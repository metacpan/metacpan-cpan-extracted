# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Text::Chapter;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';
use List::Util     'first';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}       ||= 'Chapter';
    $args->{container}  ||= delete $args->{manual} or panic;
    $args->{level}      ||= 1;

    $self->SUPER::init($args)
        or return;

    $self->{OTC_sections} = [];

    $self;
}

sub emptyExtension($)
{   my ($self, $container) = @_;
    my $empty = $self->SUPER::emptyExtension($container);
    my @sections = map $_->emptyExtension($empty), $self->sections;
    $empty->sections(@sections);
    $empty;
}

sub manual() {shift->container}
sub path()   {shift->name}

sub findSubroutine($)
{   my ($self, $name) = @_;
    my $sub = $self->SUPER::findSubroutine($name);
    return $sub if defined $sub;

    foreach my $section ($self->sections)
    {   my $sub = $section->findSubroutine($name);
        return $sub if defined $sub;
    }

    undef;
}

sub findEntry($)
{   my ($self, $name) = @_;
    return $self if $self->name eq $name;

    foreach my $section ($self->sections)
    {   my $entry = $section->findEntry($name);
        return $entry if defined $entry;
    }

    ();
}

sub all($@)
{   my $self = shift;
    ($self->SUPER::all(@_), map {$_->all(@_)} $self->sections);
}


sub section($)
{   my ($self, $thing) = @_;

    if(ref $thing)
    {   push @{$self->{OTC_sections}}, $thing;
        return $thing;
    }

    first {$_->name eq $thing} $self->sections;
}


sub sections()
{  my $self = shift;
   if(@_)
   {   $self->{OTC_sections} = [ @_ ];
       $_->container($self) for @_;
   }
   @{$self->{OTC_sections}};
}

1;
