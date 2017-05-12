# Copyrights 2003,2007-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use strict;
use warnings;

package OODoc::Template;
use vars '$VERSION';
$VERSION = '0.16';


use Log::Report  'oodoc-template';

use IO::File     ();
use File::Spec   ();
use Data::Dumper qw(Dumper);
use Scalar::Util qw(weaken);

my @default_markers = ('<!--{', '}-->', '<!--{/', '}-->');


sub new(@)
{   my ($class, %args) = @_;
    (bless {}, $class)->init(\%args);
}

sub init($)
{   my ($self, $args) = @_;

    $self->{cached}     = {};
    $self->{macros}     = {};

    my $s = $self; weaken $s;   # avoid circular ref
    $args->{template} ||= sub { $s->includeTemplate(@_) };
    $args->{macro}    ||= sub { $s->defineMacro(@_) };

    $args->{search}   ||= '.';
    $args->{markers}  ||= \@default_markers;
    $args->{define}   ||= sub { shift; (1, @_) };

    $self->pushValues($args);
    $self;
}


sub process($)
{   my ($self, $templ) = (shift, shift);

    my $values = @_==1 ? shift : @_ ? {@_} : {};

    my $tree     # parse with real copy
      = ref $templ eq 'SCALAR' ? $self->parseTemplate($$templ)
      : ref $templ eq 'ARRAY'  ? $templ
      :                          $self->parseTemplate("$templ");

    defined $tree
        or return ();

    $self->pushValues($values)
        if keys %$values;

    my @output;
    foreach my $node (@$tree)
    {   unless(ref $node)
        {   push @output, $node;
            next;
        }
    
        my ($tag, $attr, $then, $else) = @$node;

        my %attrs;
        while(my($k, $v) = each %$attr)
        {   $attrs{$k} = ref $v ne 'ARRAY' ? $v
              : @$v==1 ? scalar $self->valueFor(@{$v->[0]})
              : join '',
                   map {ref $_ eq 'ARRAY' ? scalar $self->valueFor(@$_) : $_}
                      @$v;
        }

        (my $value, my $attrs, $then, $else)
           = $self->valueFor($tag, \%attrs, $then, $else);

        unless(defined $then || defined $else)
        {   defined $value
                or next;

            ref $value ne 'ARRAY' && ref $value ne 'HASH'
                or error __x"value for {tag} is {value}, must be single"
                     , tag => $tag, value => $value;

            push @output, $value;
            next;
        }

        my $take_else
           = !defined $value || (ref $value eq 'ARRAY' && @$value==0);

        my $container = $take_else ? $else : $then;

        defined $container
            or next;

        $self->pushValues($attrs) if keys %$attrs;

        if($take_else)
        {    my ($nest_out, $nest_tree) = $self->process($container);
             push @output, $nest_out;
             $node->[3] = $nest_tree;
        }
        elsif(ref $value eq 'HASH')
        {    my ($nest_out, $nest_tree) = $self->process($container, $value);
             push @output, $nest_out;
             $node->[2] = $nest_tree;
        }
        elsif(ref $value eq 'ARRAY')
        {    foreach my $data (@$value)
             {   my ($nest_out, $nest_tree) = $self->process($container, $data);
                 push @output, $nest_out;
                 $node->[2] = $nest_tree;
             }
        }
        else
        {    my ($nest_out, $nest_tree) = $self->process($container);
             push @output, $nest_out;
             $node->[2] = $nest_tree;
        }

        $self->popValues if keys %$attrs;
    }
    
    $self->popValues if keys %$values;

              wantarray ? (join('', @output), $tree)  # LIST context
    : defined wantarray ? join('', @output)           # SCALAR context
    :                     print @output;              # VOID context
}


sub processFile($;@)
{   my ($self, $filename) = (shift, shift);

    my $values = @_==1 ? shift : {@_};
    $values->{source} ||= $filename;

    my $cache  = $self->{cached};

    my ($output, $tree, $template);
    if(exists $cache->{$filename})
    {   $tree   = $cache->{$filename};
        $output = $self->process($tree, $values)
            if defined $tree;
    }
    elsif($template = $self->loadFile($filename))
    {   ($output, $tree) = $self->process($template, $values);
        $cache->{$filename} = $tree;
    }
    else
    {   $tree = $cache->{$filename} = undef;
    }

    defined $tree || defined wantarray
        or error __x"cannot find template file {fn}", fn => $filename;

              wantarray ? ($output, $tree)  # LIST context
    : defined wantarray ? $output           # SCALAR context
    :                     print $output;    # VOID context
}


sub defineMacro($$$$)
{   my ($self, $tag, $attrs, $then, $else) = @_;
    my $name = delete $attrs->{name}
        or error __x"macro requires a name";

    defined $else
        and error __x"macros cannot have an else part ({macro})",macro => $name;

    my %attrs = %$attrs;   # for closure
    $attrs{markers} = $self->valueFor('markers');

    $self->{macros}{$name} =
        sub { my ($tag, $at) = @_;
              $self->process($then, +{%attrs, %$at});
            };

    ();
    
}


sub valueFor($;$$$)
{   my ($self, $tag, $attrs, $then, $else) = @_;

#warn "Looking for $tag";
#warn Dumper $self->{values};
    for(my $set = $self->{values}; defined $set; $set = $set->{NEXT})
    {   my $v = $set->{$tag};

        if(defined $v)
        {   # HASH  defines container
            # ARRAY defines container loop
            # object or other things can be stored as well, but may get
            # stringified.
            return wantarray ? ($v, $attrs, $then, $else) : $v
                if ref $v ne 'CODE';

            return wantarray
                 ? $v->($tag, $attrs, $then, $else)
                 : ($v->($tag, $attrs, $then, $else))[0]
        }

        return wantarray ? (undef, $attrs, $then, $else) : undef
            if exists $set->{$tag};

        my $code = $set->{DYNAMIC};
        if(defined $code)
        {   my ($value, @other) = $code->($tag, $attrs, $then, $else);
            return wantarray ? ($value, @other) : $value
                if defined $value;
            # and continue the search otherwise
        }
    }

    wantarray ? (undef, $attrs, $then, $else) : undef;
}


sub allValuesFor($;$$$)
{   my ($self, $tag, $attrs, $then, $else) = @_;
    my @values;

    for(my $set = $self->{values}; defined $set; $set = $set->{NEXT})
    {   
        if(defined(my $v = $set->{$tag}))
        {   my $t = ref $v eq 'CODE' ? $v->($tag, $attrs, $then, $else) : $v;
            push @values, $t if defined $t;
        }

        if(defined(my $code = $set->{DYNAMIC}))
        {   my $t = $code->($tag, $attrs, $then, $else);
            push @values, $t if defined $t;
        }
    }

    @values;
}


sub pushValues($)
{   my ($self, $attrs) = @_;

    if(my $markers = $attrs->{markers})
    {   my @markers = ref $markers eq 'ARRAY' ? @$markers
          : map {s/\\\,//g; $_} split /(?!<\\)\,\s*/, $markers;

        push @markers, $markers[0] . '/'
            if @markers==2;

        push @markers, $markers[1]
            if @markers==3;

        $attrs->{markers}
          = [ map { ref $_ eq 'Regexp' ? $_ : qr/\Q$_/ } @markers ];
    }

    if(my $search = $attrs->{search})
    {   $attrs->{search} = [ split /\:/, $search ]
            if ref $search ne 'ARRAY';
    }

    $self->{values} = { %$attrs, NEXT => $self->{values} };
}


sub popValues()
{   my $self = shift;
    $self->{values} = $self->{values}{NEXT};
}


sub includeTemplate($$$)
{   my ($self, $tag, $attrs, $then, $else) = @_;

    defined $then || defined $else
        and error __x"template is not a container";

    if(my $fn = $attrs->{file})
    {   my $output = $self->processFile($fn, $attrs);
        $output    = $self->processFile($attrs->{alt}, $attrs)
            if !defined $output && $attrs->{alt};

        defined $output
            or error __x"cannot find template file {fn}", fn => $fn;

        return ($output);
    }

    if(my $name = $attrs->{macro})
    {    my $macro = $self->{macros}{$name}
            or error __x"cannot find macro {name}", name => $name;

        return $macro->($tag, $attrs, $then, $else);
    }

    error __x"file or macro attribute required for template in {source}"
      , source => $self->valueFor('source') || '??';
}


sub loadFile($)
{   my ($self, $relfn) = @_;
    my $absfn;

    if(File::Spec->file_name_is_absolute($relfn))
    {   my $fn = File::Spec->canonpath($relfn);
        $absfn = $fn if -f $fn;
    }

    unless($absfn)
    {   my @srcs = map { @$_ } $self->allValuesFor('search');
        foreach my $dir (@srcs)
        {   $absfn = File::Spec->rel2abs($relfn, $dir);
            last if -f $absfn;
            $absfn = undef;
        }
    }

    defined $absfn
        or return undef;

    my $in = IO::File->new($absfn, 'r');
    unless(defined $in)
    {   my $source = $self->valueFor('source') || '??';
        fault __x"Cannot read from {fn} in {file}", fn => $absfn, file=>$source;
    }

    \(join '', $in->getlines);  # auto-close in
}


sub parse($@)
{   my ($self, $template) = (shift, shift);
    $self->process(\$template, @_);
}


sub parseTemplate($)
{   my ($self, $template) = @_;

    defined $template
        or return undef;

    my $markers = $self->valueFor('markers');

    # Remove white-space escapes
    $template =~ s! \\ (?: \s* (?: \\ \s*)? \n)+
                    (?: \s* (?= $markers->[0] | $markers->[3] ))?
                  !!mgx;

    my @frags;

    # NOT_$tag supported for backwards compat
    while( $template =~ s!^(.*?)        # text before container
                           $markers->[0] \s*
                           (?: IF \s* )?
                           (NOT (?:_|\s+) )?
                           ([\w.-]+) \s*    # tag
                           (.*?) \s*    # attributes
                           $markers->[1]
                         !!xs
         )
    {   push @frags, $1;
        my ($not, $tag, $attr) = ($2, $3, $4);
        my ($then, $else);

        if($template =~ s! (.*?)           # contained
                           ( $markers->[2]
                             \s* \Q$tag\E \s*  # "our" tag
                             $markers->[3]
                           )
                         !!xs)
        {   $then       = $1;
            my $endline = $2;
        }

        if($not) { ($then, $else) = (undef, $then) }
        elsif(!defined $then) { }
        elsif($then =~ s! $markers->[0]
                          \s* ELSE (?:_|\s+)
                          \Q$tag\E \s*
                          $markers->[1]
                          (.*)
                        !!xs)
        {   # ELSE_$tag for backwards compat
            $else = $1;
        }

        push @frags, [$tag, $self->parseAttrs($attr), $then, $else];
    }

    push @frags, $template;
    \@frags;
}


sub parseAttrs($)
{   my ($self, $string) = @_;

    my %attrs;
    while( $string =~
        s!^\s* (?: '([^']+)'        # attribute name (might be quoted)
               |   "([^"]+)"
               |   (\w+)
               )
           \s* (?: \= \>? \s*       # an optional value
                   ( \"[^"]*\"          # dquoted value
                   | \'[^']*\'          # squoted value
                   | \$\{ [^}]+ \}      # complex variable
                   | [^\s,]+            # unquoted value
                   )
                )?
                \s* \,?             # optionally separated by commas
         !!xs)
    {   my ($k, $v) = ($1||$2||$3, $4);
        unless(defined $v)
        {  $attrs{$k} = 1;
           next;
        }

        if($v =~ m/^\'(.*)\'$/)
        {   # Single quoted parameter, no interpolation
            $attrs{$k} = $1;
            next;
        }

        $v =~ s/^\"(.*)\"$/$1/;
        my @v = split /( \$\{[^\}]+\} | \$\w+ )/x, $v;

        if(@v==1 && $v[0] !~ m/^\$/)
        {   $attrs{$k} = $v[0];
            next;
        }

        my @steps;
        foreach (@v)
        {   if( m/^ (?: \$(\w+) | \$\{ (\w+) \s* \} ) $/x )
            {   push @steps, [ $+ ];
            }
            elsif( m/^ \$\{ (\w+) \s* ([^\}]+? \s* ) \} $/x )
            {   push @steps, [ $1, $self->parseAttrs($2) ];
            }
            else
            {   push @steps, $_ if length $_;
            }
        }

        $attrs{$k} = \@steps;
    }

    error __x"attribute error in {tag}'", tag => $_[1]
        if length $string;

    \%attrs;
}


1;
