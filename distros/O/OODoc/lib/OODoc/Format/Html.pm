# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Format::Html;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Format';

use strict;
use warnings;

use Log::Report     'oodoc';
use OODoc::Template ();

use IO::File        ();
use File::Spec      ();
use File::Find      qw/find/;
use File::Basename  qw/basename dirname/;
use File::Copy      qw/copy/;
use POSIX           qw/strftime/;
use List::Util      qw/first/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my $html = delete $args->{html_root} || '/';
    $html    =~ s! /$ !!x;

    $self->{OFH_html} = $html;
    $self->{OFH_jump} = delete $args->{jump_script} || "$html/jump.cgi";

    my $meta  = delete $args->{html_meta_data} || '';
    if(my $ss = $self->{OFH_style} = delete $args->{html_stylesheet})
    {   my $base = basename $ss;
        $meta   .= qq[<link rel="STYLESHEET" href="/$base">];
    }
    $self->{OFH_meta} = $meta;
    $self;
}

#-------------------------------------------


sub manual(;$) {my $s = shift; @_ ? $s->{OFH_manual}=shift : $s->{OFH_manual}}

#-------------------------------------------


sub cleanupString($$)
{   my $self = shift;
    my $text = $self->cleanup(@_);
    $text =~ s!</p>\s*<p>!<br>!gs;
    $text =~ s!\</?p\>!!g;
    $text;
}


sub link($$;$)
{   my ($self, $manual, $object, $text) = @_;
    $text = $object->name unless defined $text;

    my $jump;
    if($object->isa('OODoc::Manual'))
    {   (my $manname = $object->name) =~ s!\:\:!_!g;
        $jump = "$self->{OFH_html}/$manname/index.html";
    }
    else
    {   (my $manname = $manual->name) =~ s!\:\:!_!g;
        $jump = $self->{OFH_jump}.'?'.$manname.'&'.$object->unique;
    }

    qq[<a href="$jump" target="_top">$text</a>];
}


sub mark($$)
{   my ($self, $manual, $id) = @_;
    $manual =~ s/\:\:/_/g;
    $self->{OFH_markers}->print("$id $manual $self->{OFH_filename}\n");
}


sub createManual($@)
{   my ($self, %args) = @_;
    my $verbose  = $args{verbose} || 0;
    my $manual   = $args{manual} or panic;
    my $options  = $args{format_options} || [];

    # Location for the manual page files.

    my $template = $args{template} || File::Spec->catdir('html', 'manual');
    my %template = $self->expandTemplate($template, $options);

    (my $manfile  = "$manual") =~ s!\:\:!_!g;
    my $dest = File::Spec->catdir($self->workdir, $manfile);
    $self->mkdirhier($dest);

    # File to trace markers must be open.

    unless(defined $self->{OFH_markers})
    {   my $markers = File::Spec->catdir($self->workdir, 'markers');
        my $mark = IO::File->new($markers, 'w')
            or fault __x"cannot write markers to {fn}", fn => $markers;
        $self->{OFH_markers} = $mark;
        $mark->print($self->{OFH_html}, "\n");
    }

    #
    # Process template
    #

    my $manifest = $self->manifest;
    while(my($raw, $options) = each %template)
    {   my $cooked = File::Spec->catfile($dest, basename $raw);

        print "$manual: $cooked\n" if $verbose > 2;
        $manifest->add($cooked);

        my $output  = IO::File->new($cooked, 'w')
            or fault __x"cannot write html manual to {fn}", fn => $cooked;

        $self->{OFH_filename} = basename $raw;

        $self->manual($manual);
        $self->format
          ( output      => $output
          , template_fn => $raw
          , @$options
          );
        $self->manual(undef);
        $output->close;
    }

    delete $self->{OFH_filename};
    $self;
}


sub createOtherPages(@)
{   my ($self, %args) = @_;

    my $verbose  = $args{verbose} || 0;

    #
    # Collect files to be processed
    #
 
    my $source   = $args{source};
    if(defined $source)
    {   -d $source
             or fault __x"html source directory {dir}", dir => $source;
    }
    else
    {   $source = File::Spec->catdir("html", "other");
        -d $source or return $self;
    }

    my $process  = $args{process}  || qr/\.(s?html|cgi)$/;

    my $dest = $self->workdir;
    $self->mkdirhier($dest);

    my @sources;
    find( { no_chdir => 1
          , wanted   => sub { my $fn = $File::Find::name;
                              push @sources, $fn if -f $fn;
                            }
           }, $source
        );

    #
    # Process files, one after the other
    #

    my $manifest = $self->manifest;
    foreach my $raw (@sources)
    {   (my $cooked = $raw) =~ s/\Q$source\E/$dest/;

        print "create $cooked\n" if $verbose > 2;
        $manifest->add($cooked);

        if($raw =~ $process)
        {   $self->mkdirhier(dirname $cooked);
            my $output  = IO::File->new($cooked, 'w')
                or fault __x"cannot write html to {fn}", fn => $cooked;

            my $options = [];
            $self->format
             ( manual      => undef
             , output      => $output
             , template_fn => $raw
             , @$options
             );
            $output->close;
         }
         else
         {   copy($raw, $cooked)
                or fault __x"copy from {from} to {to} failed"
                     , from => $raw, to => $cooked;
         }

         my $rawmode = (stat $raw)[2] & 07777;
         chmod $rawmode, $cooked
             or fault __x"chmod of {fn} to {mode%o} failed"
                  , fn => $cooked, mode => $rawmode;
    }

    $self;
}

 
sub expandTemplate($$)
{   my $self     = shift;
    my $loc      = shift || panic;
    my $defaults = shift || [];

    my @result;
    if(ref $loc eq 'HASH')
    {   foreach my $n (keys %$loc)
        {   my %options = (@$defaults, @{$loc->{$n}});
            push @result, $self->expandTemplate($n, [ %options ])
        }
    }
    elsif(-d $loc)
    {   find( { no_chdir => 1,
                wanted   => sub { my $fn = $File::Find::name;
                                  push @result, $fn, $defaults
                                     if -f $fn;
                                }
              }, $loc
            );
    }
    elsif(-f $loc) { push @result, $loc => $defaults }
    else { error __x"cannot find template source '{name}'", name => $loc }

    @result;
}

sub showStructureExpand(@)
{   my ($self, %args) = @_;

    my $examples = $args{show_chapter_examples} || 'EXPAND';
    my $text     = $args{structure} or panic;

    my $name     = $text->name;
    my $level    = $text->level +1;  # header level, chapter = H2
    my $output   = $args{output}  or panic;
    my $manual   = $args{manual}  or panic;

    # Produce own chapter description

    my $descr   = $self->cleanup($manual, $text->description);
    my $unique  = $text->unique;
    (my $id     = $name) =~ s/\W+/_/g;

    $output->print(
        qq[\n<h$level id="$id"><a name="$unique">$name</a></h$level>\n$descr]
                  );

    $self->mark($manual, $unique);

    # Link to inherited documentation.

    my $super = $text;
    while($super = $super->extends)
    {   last if $super->description !~ m/^\s*$/;
    }

    if(defined $super)
    {   my $superman = $super->manual;   #  :-)
        $output->print( "<p>See ", $self->link($superman, $super), " in "
                      , $self->link(undef, $superman), "</p>\n");
    }

    # Show the subroutines and examples.

    $self->showSubroutines(%args, subroutines => [$text->subroutines]);
    $self->showExamples(%args, examples => [$text->examples])
         if $examples eq 'EXPAND';

    $self;
}

sub showStructureRefer(@)
{   my ($self, %args) = @_;

    my $text     = $args{structure} or panic;
    my $name     = $text->name;
    my $level    = $text->level;

    my $output   = $args{output}  or panic;
    my $manual   = $args{manual}  or panic;

    my $link     = $self->link($manual, $text);
    $output->print(
       qq[\n<h$level id="$name"><a href="$link">$name</a><h$level>\n]);
    $self;
}

sub chapterDiagnostics(@)
{   my ($self, %args) = @_;

    my $manual  = $args{manual} or panic;
    my $diags   = $manual->chapter('DIAGNOSTICS');

    my @diags   = map {$_->diagnostics} $manual->subroutines;
    $diags      = OODoc::Text::Chapter->new(name => 'DIAGNOSTICS')
        if !$diags && @diags;

    return unless $diags;

    $self->showChapter(chapter => $diags, %args)
        if defined $diags;

    $self->showDiagnostics(%args, diagnostics => \@diags);
    $self;
}

sub showExamples(@)
{   my ($self, %args) = @_;
    my $examples = $args{examples} or panic;
    return unless @$examples;

    my $manual    = $args{manual}  or panic;
    my $output    = $args{output}  or panic;

    $output->print( qq[<dl class="example">\n] );

    foreach my $example (@$examples)
    {   my $name   = $example->name;
        my $descr  = $self->cleanup($manual, $example->description);
        my $unique = $example->unique;
        $output->print( <<EXAMPLE );
<dt>&raquo;&nbsp;<a name="$unique">Example</a>: $name</dt>
<dd>$descr</dd>
EXAMPLE

         $self->mark($manual, $unique);
    }
    $output->print( qq[</dl>\n] );

    $self;
}

sub showDiagnostics(@)
{   my ($self, %args) = @_;
    my $diagnostics = $args{diagnostics} or panic;
    return unless @$diagnostics;

    my $manual    = $args{manual}  or panic;
    my $output    = $args{output}  or panic;

    $output->print( qq[<dl class="diagnostics">\n] );

    foreach my $diag (sort @$diagnostics)
    {   my $name    = $diag->name;
        my $type    = $diag->type;
        my $text    = $self->cleanup($manual, $diag->description);
        my $unique  = $diag->unique;

        $output->print( <<DIAG );
<dt class="type">&raquo;&nbsp;$type: <a name="$unique">$name</a></dt>
<dd>$text</dd>
DIAG

         $self->mark($manual, $unique);
    }

    $output->print( qq[</dl>\n] );
    $self;
}

sub showSubroutine(@)
{   my $self = shift;
    my %args   = @_;
    my $output = $args{output}     or panic;
    my $sub    = $args{subroutine} or panic;
    my $type   = $sub->type;
    my $name   = $sub->name;

    $self->SUPER::showSubroutine(@_);

    $output->print( qq[</dd>\n</dl>\n</div>\n] );
    $self;
}

sub showSubroutineUse(@)
{   my ($self, %args) = @_;
    my $subroutine = $args{subroutine} or panic;
    my $manual     = $args{manual}     or panic;
    my $output     = $args{output}     or panic;

    my $type       = $subroutine->type;
    my $name       = $self->cleanupString($manual, $subroutine->name);
    my $paramlist  = $self->cleanupString($manual, $subroutine->parameters);
    my $unique     = $subroutine->unique;

    my $class      = $manual->package;

    my $call       = qq[<b><a name="$unique">$name</a></b>];
    $call         .= "(&nbsp;$paramlist&nbsp;)" if length $paramlist;
    $self->mark($manual, $unique);

    my $use
      = $type eq 'i_method' ? qq[\$obj-&gt;$call]
      : $type eq 'c_method' ? qq[\$class-&gt;$call]
      : $type eq 'ci_method'? qq[\$obj-&gt;$call<br>\$class-&gt;$call]
      : $type eq 'overload' ? qq[overload: $call]
      : $type eq 'function' ? qq[$call]
      : $type eq 'tie'      ? $call
      : warning("unknown subroutine type {type} for {name} in {manual}"
             , type => $type, name => $name, manual => $manual);

    $output->print( <<SUBROUTINE );
<div class="$type" id="$name">
<dl>
<dt class="sub_use">$use</dt>
<dd class="sub_body">
SUBROUTINE

    if($manual->inherited($subroutine))
    {   my $defd    = $subroutine->manual;
        my $sublink = $self->link($defd, $subroutine, $name);
        my $manlink = $self->link($manual, $defd);
        $output->print( qq[See $sublink in $manlink.<br>\n] );
    }
    $self;
}

sub showSubsIndex(@)
{   my ($self, %args) = @_;
    my $output     = $args{output}     or panic;
}

sub showSubroutineName(@)
{   my ($self, %args) = @_;
    my $subroutine = $args{subroutine} or panic;
    my $manual     = $args{manual}     or panic;
    my $output     = $args{output}     or panic;
    my $name       = $subroutine->name;

    my $url
     = $manual->inherited($subroutine)
     ? "M<".$subroutine->manual."::$name>"
     : "M<$name>";

    $output->print
     ( $self->cleanupString($manual, $url)
     , ($args{last} ? ".\n" : ",\n")
     );
}

sub showOptions(@)
{   my $self   = shift;
    my %args   = @_;
    my $output = $args{output} or panic;
    $output->print( qq[<dl class="options">\n] );

    $self->SUPER::showOptions(@_);

    $output->print( qq[</dl>\n] );
    $self;
}

sub showOptionUse(@)
{   my ($self, %args) = @_;
    my $output = $args{output} or panic;
    my $option = $args{option} or panic;
    my $manual = $args{manual} or panic;

    my $params = $self->cleanupString($manual, $option->parameters);
    $params    =~ s/\s+$//;
    $params    =~ s/^\s+//;
    $params    = qq[ =&gt; <span class="params">$params</span>]
        if length $params;
 
    my $use    = qq[<span class="option">$option</span>];
    $output->print( qq[<dt class="option_use">$use$params</dt>\n] );
    $self;
}

sub showOptionExpand(@)
{   my ($self, %args) = @_;
    my $output = $args{output} or panic;
    my $option = $args{option} or panic;
    my $manual = $args{manual}  or panic;

    $self->showOptionUse(%args);

    my $where = $option->findDescriptionObject or return $self;
    my $descr = $self->cleanupString($manual, $where->description);

    $output->print( qq[<dd>$descr</dd>\n] )
        if length $descr;

    $self;
}


sub writeTable($@)
{   my ($self, %args) = @_;

    my $rows   = $args{rows}   or panic;
    return unless @$rows;

    my $head   = $args{header} or panic;
    my $output = $args{output} or panic;

    $output->print( qq[<table cellspacing="0" cellpadding="2" border="1">\n] );

    local $"   = qq[</th>    <th align="left">];
    $output->print( qq[<tr><th align="left">@$head</th></tr>\n] );

    local $"   = qq[</td>    <td valign="top">];
    $output->print( qq[<tr><td align="left">@$_</td></tr>\n] )
        foreach @$rows;

    $output->print( qq[</table>\n] );
    $self;
}

sub showSubroutineDescription(@)
{   my ($self, %args) = @_;
    my $manual     = $args{manual}     or panic;
    my $subroutine = $args{subroutine} or panic;

    my $text       = $self->cleanup($manual, $subroutine->description);
    return $self unless length $text;

    my $output     = $args{output}     or panic;
    $output->print($text);

    my $extends    = $self->extends    or return $self;
    my $refer      = $extends->findDescriptionObject or return $self;

    $output->print("<br>\n");
    $self->showSubroutineDescriptionRefer(%args, subroutine => $refer);
}

sub showSubroutineDescriptionRefer(@)
{   my ($self, %args) = @_;
    my $manual     = $args{manual}     or panic;
    my $subroutine = $args{subroutine} or panic;
    my $output     = $args{output}     or panic;
    $output->print("\nSee ", $self->link($manual, $subroutine), "\n");
}

#----------------------


our %producers =
 ( a           => 'templateHref'
 , chapter     => 'templateChapter'
 , date        => 'templateDate'
 , index       => 'templateIndex'
 , inheritance => 'templateInheritance'
 , list        => 'templateList'
 , manual      => 'templateManual'
 , meta        => 'templateMeta'
 , distribution=> 'templateDistribution'
 , name        => 'templateName'
 , project     => 'templateProject'
 , title       => 'templateTitle'
 , version     => 'templateVersion'
 );
   
sub format(@)
{   my ($self, %args) = @_;
    my $output    = delete $args{output};

    my %permitted = %args;
    my $template  = OODoc::Template->new;
    while(my ($tag, $method) = each %producers)
    {   $permitted{$tag} = sub
          { # my ($istag, $attrs, $ifblock, $elseblock) = @_;
            shift;
            $self->$method($template, @_)
          };
    }

    $output->print(
      scalar $template->processFile($args{template_fn}, \%permitted));
}


sub templateProject($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    $self->project;
}


sub templateTitle($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;

    my $manual = $self->manual
        or error __x"not a manual, so no automatic title in {fn}"
            , fn => scalar $templ->valueFor('template_fn');

    my $name   = $self->cleanupString($manual, $manual->name);
    $name      =~ s/\<[^>]*\>//g;
    $name;
}


sub templateManual($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;

    my $manual = $self->manual
        or error __x"not a manual, so no manual name for {fn}"
            , fn => scalar $templ->valueFor('template_fn');

    $self->cleanupString($manual, $manual->name);
}


sub templateDistribution($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    my $manual  = $self->manual;
    defined $manual ? $manual->distribution : '';
}


sub templateVersion($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    my $manual  = $self->manual;
    defined $manual ? $manual->version : $self->version;
}


sub templateDate($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    strftime "%Y/%m/%d", localtime;
}


sub templateName($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;

    my $manual = $self->manual
        or error __x"not a manual, so no name for {fn}"
            , fn => scalar $templ->valueFor('template_fn');

    my $chapter = $manual->chapter('NAME')
        or error __x"cannot find chapter NAME in manual {fn}", $manual->source;

    my $descr   = $chapter->description;

    return $1 if $descr =~ m/^ \s*\S+\s*\-\s*(.*?)\s* $ /x;

    error __x"chapter NAME in manual {manual} has illegal shape"
      , manual => $manual;
}


our %path_lookup =
  ( front       => "/index.html"
  , manuals     => "/manuals/index.html"
  , methods     => "/methods/index.html"
  , diagnostics => "/diagnostics/index.html"
  , details     => "/details/index.html"
  );

sub templateHref($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    my $window = delete $attrs->{window} || '_top';
    keys %$attrs==1
        or error __x"expect one name with 'a'";
    (my $to)   = keys %$attrs;

    my $path   = $path_lookup{$to}
        or error __x"missing path for {dest}", dest => $to;

    qq[<a href="$self->{OFH_html}$path" target="$window">];
}


sub templateMeta($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    $self->{OFH_meta};
}


sub templateInheritance(@)
{   my ($self, $templ, $attrs, $if, $else) = @_;

    my $manual  = $self->manual;
    my $chapter = $manual->chapter('INHERITANCE')
        or return '';

    my $buffer  = '';
    open my $out, '>', \$buffer;
    $self->showChapter
      ( %$attrs
      , manual  => $self->manual
      , chapter => $chapter
      , output  => $out
      );
    close $out;

    for($buffer)
    {   s#\<pre\>\s*(.*?)\</pre\>\n*#\n$1#gs;   # over-eager cleanup
        s#^( +)#'&nbsp;' x length($1)#gme;
        s# $ #<br>#gmx;
        s#(\</h\d\>)(\<br\>\n?)+#$1\n#;
    }

    $buffer;
}


sub templateChapter($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    warning __x"no meaning for container {c} in chapter block", c => $if
        if defined $if && length $if;

    my $name  = first { !/[a-z]/ } keys %$attrs;
    defined $name
        or error __x"chapter without name in template {fn}"
            , fn => scalar $templ->valueFor('template_fn');

    my $manual  = $self->manual;
    defined $manual or panic;
    my $chapter = $manual->chapter($name) or return '';

    my $buffer  = '';
    open my $out, '>', \$buffer;
    $self->showChapter
      ( %$attrs
      , manual  => $self->manual
      , chapter => $chapter
      , output  => $out
      );
    close $out;

    $buffer;
}


sub templateIndex($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;

    warning __x"no meaning for container {c} in list block", c => $if
        if defined $if && length $if;

    my $group  = first { !/[a-z]/ } keys %$attrs;
    defined $group
        or error __x"no group named as attribute for list";

    my $start  = $attrs->{starting_with} || 'ALL';
    my $types  = $attrs->{type}          || 'ALL';

    my $select = sub { @_ };
    unless($start eq 'ALL')
    {   $start =~ s/_/[\\W_]/g;
        my $regexp = qr/^$start/i;
        $select    = sub { grep $_->name =~ $regexp, @_ };
    }
    unless($types eq 'ALL')
    {   my @take   = map { $_ eq 'method' ? '.*method' : $_ }
                         split /[_|]/, $types;
        local $"   = ')|(';
        my $regexp = qr/^(@take)$/i;
        my $before = $select;
        $select    = sub { grep $_->type =~ $regexp, $before->(@_) };
    }

    my $columns = $attrs->{table_columns} || 2;
    my @rows;

    if($group eq 'SUBROUTINES')
    {   my @subs;

        foreach my $manual ($self->manuals)
        {   foreach my $sub ($select->($manual->ownSubroutines))
            {   my $linksub = $self->link($manual, $sub, $sub->name);
                my $linkman = $self->link(undef, $manual, $manual->name);
                my $link    = "$linksub -- $linkman";
                push @subs, [ lc("$sub-$manual"), $link ];
            }
        }

        @rows = map { $_->[1] }
            sort { $a->[0] cmp $b->[0] } @subs;
    }
    elsif($group eq 'DIAGNOSTICS')
    {   foreach my $manual ($self->manuals)
        {   foreach my $sub ($manual->ownSubroutines)
            {   my @diags    = $select->($sub->diagnostics) or next;

                my $linksub  = $self->link($manual, $sub, $sub->name);
                my $linkman  = $self->link(undef, $manual, $manual->name);

                foreach my $diag (@diags)
                {   my $type = uc($diag->type);
                    push @rows, <<"DIAG";
$type: $diag<br>
&middot;&nbsp;$linksub in $linkman<br>
DIAG
                }
            }
        }

        @rows = sort @rows;
    }
    elsif($group eq 'DETAILS')
    {   foreach my $manual (sort $select->($self->manuals))
        {   my $details  = $manual->chapter("DETAILS") or next;
            my @sections;
            foreach my $section ($details->sections)
            {   my @subsect = grep !$manual->inherited($_) && $_->description
                  , $section->subsections;
                push @sections, $section
                    if @subsect || $section->description;
            }

            @sections || length $details->description
                or next;

            my $sections = join "\n"
              , map { "<li>".$self->link($manual, $_)."</li>" }
                    @sections;

            push @rows, $self->link($manual, $details, "Details in $manual")
              . qq[\n<ul>\n$sections</ul>\n]
        }
    }
    elsif($group eq 'MANUALS')
    {   @rows = map $self->link(undef, $_, $_->name)
          , sort $select->($self->manuals);
    }
    else
    {   error __x"unknown group {name} as list attribute", name => $group;
    }

    push @rows, ('') x ($columns-1);
    my $rows   = int(@rows/$columns);

    my $output = qq[<tr>];
    while(@rows >= $columns)
    {   $output .= qq[<td valign="top">]
                . join( "<br>\n", splice(@rows, 0, $rows))
                .  qq[</td>\n];
    }
    $output   .= qq[</tr>\n];
    $output;
}


sub templateList($$)
{   my ($self, $templ, $attrs, $if, $else) = @_;
    warning __x"no meaning for container {c} in index block", c => $if
        if defined $if && length $if;

    my $group  = first { !/[a-z]/ } keys %$attrs;
    defined $group
        or error __x"no group named as attribute for list";

    my $show_sub = $attrs->{show_subroutines} || 'LIST';
    my $types    = $attrs->{subroutine_types} || 'ALL';
    my $manual   = $self->manual or panic;
    my $output   = '';

    my $selected = sub { @_ };
    unless($types eq 'ALL')
    {   my @take   = map { $_ eq 'method' ? '.*method' : $_ }
                         split /[_|]/, $types;
        local $"   = ')|(?:';
        my $regexp = qr/^(?:@take)$/;
        $selected  = sub { grep $_->type =~ $regexp, @_ };
    }

    my $sorted     = sub { sort {$a->name cmp $b->name} @_ };

    if($group eq 'ALL')
    {   my @subs   = $sorted->($selected->($manual->subroutines));
        if(!@subs || $show_sub eq 'NO') { ; }
        elsif($show_sub eq 'COUNT')     { $output .= @subs }
        else
        {   $output .= $self->indexListSubroutines($manual,@subs);
        }
    }
    else  # any chapter
    {   my $chapter  = $manual->chapter($group) or return '';
        my $show_sec = $attrs->{show_sections} || 'LINK';
        my @sections = $show_sec eq 'NO' ? () : $chapter->sections;

        my @subs = $sorted->($selected->( @sections
                                        ? $chapter->subroutines
                                        : $chapter->all('subroutines')
                                        )
                             );

        $output  .= $self->link($manual, $chapter, $chapter->niceName); 
        my $count = @subs && $show_sub eq 'COUNT' ? ' ('.@subs.')' : '';

        if($show_sec eq 'NO') { $output .= qq[$count<br>\n] }
        elsif($show_sec eq 'LINK' || $show_sec eq 'NAME')
        {   $output .= qq[<br>\n<ul>\n];
            if(!@subs) {;}
            elsif($show_sec eq 'LINK')
            {   my $link = $self->link($manual, $chapter, 'unsorted');
                $output .= qq[<li>$link$count\n];
            }
            elsif($show_sec eq 'NAME')
            {   $output .= qq[<li>];
            }

            $output .= $self->indexListSubroutines($manual,@subs)
                if @subs && $show_sub eq 'LIST';
        }
        else
        {   error __x"illegal value to show_sections: {v}", v => $show_sec;
        }
     
        # All sections within the chapter (if show_sec is enabled)

        foreach my $section (@sections)
        {   my @subs  = $sorted->($selected->($section->all('subroutines')));

            my $count = ! @subs              ? ''
                      : $show_sub eq 'COUNT' ? ' ('.@subs.')'
                      :                        ': ';

            if($show_sec eq 'LINK')
            {   my $link = $self->link($manual, $section, $section->niceName);
                $output .= qq[<li>$link$count\n];
            }
            else
            {   $output .= qq[<li>$section$count\n];
            }

            $output .= $self->indexListSubroutines($manual,@subs)
                if $show_sub eq 'LIST' && @subs;

            $output .= qq[</li>\n];
        }

        $output .= qq[</ul>\n]
             if $show_sec eq 'LINK' || $show_sec eq 'NAME';
    }

    $output;
}

sub indexListSubroutines(@)
{   my $self   = shift;
    my $manual = shift;
    
    join ",\n"
       , map { $self->link($manual, $_, $_) }
            @_;
}

#-------------------------------------------


1;
