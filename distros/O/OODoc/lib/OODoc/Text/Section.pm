# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Text::Section;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';
use List::Util     'first';



sub init($)
{   my ($self, $args) = @_;
    $args->{type}      ||= 'Section';
    $args->{level}     ||= 2;
    $args->{container} ||= delete $args->{chapter} or panic;

    $self->SUPER::init($args) or return;

    $self->{OTS_subsections} = [];
    $self;
}

sub emptyExtension($)
{   my ($self, $container) = @_;
    my $empty = $self->SUPER::emptyExtension($container);
    my @subsections = map $_->emptyExtension($empty), $self->subsections;
    $empty->subsections(@subsections);
    $empty;
}

#-------------------------------------------


sub chapter() { shift->container }

sub path()
{   my $self = shift;
    $self->chapter->path . '/' . $self->name;
}

sub findSubroutine($)
{   my ($self, $name) = @_;
    my $sub = $self->SUPER::findSubroutine($name);
    return $sub if defined $sub;

    foreach my $subsection ($self->subsections)
    {   my $sub = $subsection->findSubroutine($name);
        return $sub if defined $sub;
    }

    undef;
}

sub findEntry($)
{   my ($self, $name) = @_;
    return $self if $self->name eq $name;
    my $subsect = $self->subsection($name);
    defined $subsect ? $subsect : ();
}

sub all($@)
{   my $self = shift;
    ($self->SUPER::all(@_), map {$_->all(@_)} $self->subsections);
}

#-------------------------------------------


sub subsection($)
{   my ($self, $thing) = @_;
    if(ref $thing)
    {   push @{$self->{OTS_subsections}}, $thing;
        return $thing;
    }

    first {$_->name eq $thing} $self->subsections;
}


sub subsections(;@)
{   my $self = shift;
    if(@_)
    {   $self->{OTS_subsections} = [ @_ ];
        $_->container($self) for @_;
    }

    @{$self->{OTS_subsections}};
}


1;
