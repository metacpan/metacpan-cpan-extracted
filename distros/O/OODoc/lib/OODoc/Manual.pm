# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Manual;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use OODoc::Text::Chapter;

use List::Util 'first';


use overload '""' => sub { shift->name };
use overload bool => sub {1};


use overload cmp  => sub {$_[0]->name cmp "$_[1]"};

#-------------------------------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my $name = $self->{OP_package} = delete $args->{package}
       or error __x"package name is not specified";

    $self->{OP_source}   = delete $args->{source}
        or error __x"no source is specified for manual {name}", name => $name;

    $self->{OP_version}  = delete $args->{version}
        or error __x"no version is specified for manual {name}", name => $name;

    $self->{OP_distr}    = delete $args->{distribution}
        or error __x"no distribution specified for manual {name}", name=> $name;

    $self->{OP_parser}   = delete $args->{parser}    or panic;
    $self->{OP_stripped} = delete $args->{stripped};

    $self->{OP_pure_pod} = delete $args->{pure_pod} || 0;
    $self->{OP_chapter_hash} = {};
    $self->{OP_chapters}     = [];
    $self->{OP_subclasses}   = [];
    $self->{OP_realizers}    = [];
    $self->{OP_extra_code}   = [];
    $self->{OP_isa}          = [];

    $self;
}

#-------------------------------------------


sub package() {shift->{OP_package}}


sub parser() {shift->{OP_parser}}


sub source() {shift->{OP_source}}


sub version() {shift->{OP_version}}


sub distribution() {shift->{OP_distr}}


sub stripped() {shift->{OP_stripped}}


sub isPurePod() {shift->{OP_pure_pod}}

#-------------------------------------------


sub chapter($)
{   my ($self, $it) = @_;
    $it or return;

    ref $it
        or return $self->{OP_chapter_hash}{$it};

    $it->isa("OODoc::Text::Chapter")
        or panic "$it is not a chapter";

    my $name = $it->name;
    if(my $old = $self->{OP_chapter_hash}{$name})
    {   my ($fn,  $ln2) = $it->where;
        my ($fn2, $ln1) = $old->where;
        error __x"two chapters named {name} in {file} line {line1} and {line2}"
          , name => $name, file => $fn, line1 => $ln2, line2 => $ln1;
    }

    $self->{OP_chapter_hash}{$name} = $it;
    push @{$self->{OP_chapters}}, $it;
    $it;
}


sub chapters(@)
{   my $self = shift;
    if(@_)
    {   $self->{OP_chapters}     = [ @_ ];
        $self->{OP_chapter_hash} = { map { ($_->name => $_) } @_ };
    }
    @{$self->{OP_chapters}};
}


sub name()
{   my $self    = shift;
    return $self->{OP_name} if defined $self->{OP_name};

    my $chapter = $self->chapter('NAME')
        or error __x"no chapter NAME in scope of package {pkg} in file {file}"
             , pkg => $self->package, file => $self->source;

    my $text   = $chapter->description || '';
    $text =~ m/^\s*(\S+)\s*\-\s/
        or error __x"the NAME chapter does not have the right format in {file}"
             , file => $self->source;

    $self->{OP_name} = $1;
}



sub subroutines() { shift->all('subroutines') }


sub subroutine($)
{   my ($self, $name) = @_;
    my $sub;

    my $package = $self->package;
    my @parts   = defined $package ? $self->manualsForPackage($package) : $self;

    foreach my $part (@parts)
    {   foreach my $chapter ($part->chapters)
        {   $sub = first {defined $_} $chapter->all(subroutine => $name);
            return $sub if defined $sub;
        }
    }

    ();
}


sub examples()
{   my $self = shift;
    ( $self->all('examples')
    , map {$_->examples} $self->subroutines
    );
}


sub diagnostics(@)
{   my ($self, %args) = @_;
    my @select = $args{select} ? @{$args{select}} : ();

    my @diag = map {$_->diagnostics} $self->subroutines;
    return @diag unless @select;

    my $select;
    {   local $" = '|';
        $select = qr/^(@select)$/i;
    }

    grep {$_->type =~ $select} @diag;
}


#-------------------------------------------


sub superClasses(;@)
{   my $self = shift;
    push @{$self->{OP_isa}}, @_;
    @{$self->{OP_isa}};
}


sub realizes(;$)
{   my $self = shift;
    @_ ? ($self->{OP_realizes} = shift) : $self->{OP_realizes};
}


sub subClasses(;@)
{   my $self = shift;
    push @{$self->{OP_subclasses}}, @_;
    @{$self->{OP_subclasses}};
}


sub realizers(;@)
{   my $self = shift;
    push @{$self->{OP_realizers}}, @_;
    @{$self->{OP_realizers}};
}


sub extraCode()
{   my $self = shift;
    my $name = $self->name;

    $self->package eq $name
    ? grep {$_->name ne $name} $self->manualsForPackage($name)
    : ();
}


sub all($@)
{   my $self = shift;
    map { $_->all(@_) } $self->chapters;
}


sub inherited($) {$_[0]->name ne $_[1]->manual->name}


sub ownSubroutines
{   my $self = shift;
    my $me   = $self->name || return 0;
    grep {not $self->inherited($_)} $self->subroutines;
}

#-------------------------------------------


sub collectPackageRelations()
{   my $self = shift;
    return () if $self->isPurePod;

    my $name = $self->package;
    my %return;

    # The @ISA / use base
    {  no strict 'refs';
       $return{isa} = [ @{"${name}::ISA"} ];
    }

    # Support for Object::Realize::Later
    $return{realizes} = $name->willRealize if $name->can('willRealize');

    %return;
}


sub expand()
{   my $self = shift;
    return $self if $self->{OP_is_expanded};

    #
    # All super classes must be expanded first.  Manuals for
    # extra code are considered super classes as well.  Super
    # classes which are external are ignored.
    #

    my @supers  = reverse     # multiple inheritance, first isa wins
                      grep ref,
                          $self->superClasses;

    $_->expand for @supers;

    #
    # Expand chapters, sections and subsections.
    #

    my @chapters = $self->chapters;

    my $merge_subsections = sub
      { my ($section, $inherit) = @_;
        $section->extends($inherit);
        $section->subsections($self->mergeStructure
          ( this      => [ $section->subsections ]
          , super     => [ $inherit->subsections ]
          , merge     => sub { $_[0]->extends($_[1]); $_[0] }
          , container => $section
          ));
        $section;
      };

    my $merge_sections = sub
      { my ($chapter, $inherit) = @_;
        $chapter->extends($inherit);
        $chapter->sections($self->mergeStructure
          ( this      => [ $chapter->sections ]
          , super     => [ $inherit->sections ]
          , merge     => $merge_subsections
          , container => $chapter
          ));
        $chapter;
      };

    foreach my $super (@supers)
    {
        $self->chapters($self->mergeStructure
          ( this      => \@chapters
          , super     => [ $super->chapters ]
          , merge     => $merge_sections
          , container => $self
          ));
    }

    #
    # Give all the inherited subroutines a new location in this manual.
    #

    my %extended  = map +($_->name => $_),
                       map $_->subroutines,
                          ($self, $self->extraCode);

    my %used;  # items can be used more than once, collecting multiple inherit

    my @inherited = map $_->subroutines, @supers;
    my %location;

    foreach my $inherited (@inherited)
    {   my $name        = $inherited->name;
        if(my $extended = $extended{$name})
        {   # on this page and upper pages
            $extended->extends($inherited);

            unless($used{$name}++)    # add only at first appearance
            {   my $path = $self->mostDetailedLocation($extended);
                push @{$location{$path}}, $extended;
            }
        }
        else
        {   # only defined on higher level manual pages
            my $path = $self->mostDetailedLocation($inherited);
            push @{$location{$path}}, $inherited;
        }
    }

    while(my($name, $item) = each %extended)
    {   next if $used{$name};
        push @{$location{$item->path}}, $item;
    }

    foreach my $chapter ($self->chapters)
    {   $chapter->setSubroutines(delete $location{$chapter->path});
        foreach my $section ($chapter->sections)
        {   $section->setSubroutines(delete $location{$section->path});
            foreach my $subsect ($section->subsections)
            {   $subsect->setSubroutines(delete $location{$subsect->path});
            }
        }
    }

    warning __x"section without location in {manual}: {section}"
      , manual => $self, section => $_
          for keys %location;

    $self->{OP_is_expanded} = 1;
    $self;
}


sub mergeStructure(@)
{   my ($self, %args) = @_;
    my @this      = defined $args{this}  ? @{$args{this}}  : ();
    my @super     = defined $args{super} ? @{$args{super}} : ();
    my $container = $args{container} or panic;

    my $equal     = $args{equal} || sub {"$_[0]" eq "$_[1]"};
    my $merge     = $args{merge} || sub {$_[0]};

    my @joined;

    while(@super)
    {   my $take = shift @super;
        unless(first {$equal->($take, $_)} @this)
        {   push @joined, $take->emptyExtension($container)
                unless @joined && $joined[-1]->path eq $take->path;
            next;
        }

        # A low-level merge is needed.

        my $insert;
        while(@this)      # insert everything until equivalents
        {   $insert = shift @this;
            last if $equal->($take, $insert);

            if(first {$equal->($insert, $_)} @super)
            {   my ($fn, $ln) = $insert->where;
                warning __x"order conflict: '{h1}' before '{h2}' in {file} line {line}"
                  , h1 => $take, h2 => $insert, file => $fn, line => $ln;
            }

            push @joined, $insert
                unless @joined && $joined[-1]->path eq $insert->path;
        }
        push @joined, $merge->($insert, $take);
    }

    (@joined, @this);
}


sub mostDetailedLocation($)
{   my ($self, $thing) = @_;

    my $inherit = $thing->extends
       or return $thing->path;

    my $path1   = $thing->path;
    my $path2   = $self->mostDetailedLocation($inherit);
    my ($lpath1, $lpath2) = (length($path1), length($path2));

    return $path1 if $path1 eq $path2;

    return $path2
       if $lpath1 < $lpath2 && substr($path2, 0, $lpath1+1) eq "$path1/";

    return $path1
       if $lpath2 < $lpath1 && substr($path1, 0, $lpath2+1) eq "$path2/";

    warning __x"subroutine '{name}' location conflict:\n  {p1} in {man1}\n  {p2} in {man2}"
      , name => "$thing", p1 => $path1, man1 => $thing->manual
      , p2 => $path2, man2 => $inherit->manual
          if $self eq $thing->manual;

    $path1;
}


sub createInheritance()
{   my $self = shift;

    if($self->name ne $self->package)
    {   # This is extra code....
        my $from = $self->package;
        return "\n $self\n    contains extra code for\n    M<$from>\n";
    }

    my $output;
    my @supers  = $self->superClasses;

    if(my $realized = $self->realizes)
    {   $output .= "\n $self realizes a M<$realized>\n";
        @supers = $realized->superClasses if ref $realized;
    }

    if(my @extras = $self->extraCode)
    {   $output .= "\n $self has extra code in\n";
        $output .= "   M<$_>\n" foreach sort @extras;
    }

    foreach my $super (@supers)
    {   $output .= "\n $self\n";
        $output .= $self->createSuperSupers($super);
    }

    if(my @subclasses = $self->subClasses)
    {   $output .= "\n $self is extended by\n";
        $output .= "   M<$_>\n" foreach sort @subclasses;
    }

    if(my @realized = $self->realizers)
    {   $output .= "\n $self is realized by\n";
        $output .= "   M<$_>\n" foreach sort @realized;
    }

    my $chapter = OODoc::Text::Chapter->new
      ( name        => 'INHERITANCE'
      , manual      => $self
      , linenr      => -1
      , description => $output
      ) if $output && $output =~ /\S/;

    $self->chapter($chapter);
}

sub createSuperSupers($)
{   my ($self, $package) = @_;
    my $output = $package =~ /^[aeio]/i
      ? "   is an M<$package>\n"
      : "   is a M<$package>\n";

    return $output
        unless ref $package;  # only the name of the package is known

    if(my $realizes = $package->realizes)
    {   $output .= $self->createSuperSupers($realizes);
        return $output;
    }

    my @supers = $package->superClasses or return $output;
    $output   .= $self->createSuperSupers(shift @supers);

    foreach(@supers)
    {   $output .= "\n\n   $package also extends M<$_>\n";
        $output .= $self->createSuperSupers($_);
    }

    $output;
}

#-------------------------------------------


sub stats()
{   my $self     = shift;
    my $chapters = $self->chapters || return;
    my $subs     = $self->ownSubroutines;
    my $options  = map { $_->options } $self->ownSubroutines;
    my $diags    = $self->diagnostics;
    my $examples = $self->examples;

    my $manual   = $self->name;
    my $package  = $self->package;
    my $head
      = $manual eq $package
      ? "manual $manual"
      : "manual $manual for $package";

    <<STATS;
$head
   chapters:               $chapters
   documented subroutines: $subs
   documented options:     $options
   documented diagnostics: $diags
   shown examples:         $examples
STATS
}


sub index()
{   my $self  = shift;
    my @lines;
    foreach my $chapter ($self->chapters)
    {  push @lines, $chapter->name;
       foreach my $section ($chapter->sections)
       {   push @lines, "  ".$section->name;
           foreach ($section->subsections)
           {   push @lines, "    ".$_->name;
           }
       }
    }
    join "\n", @lines, '';
}

#-------------------------------------------


1;
