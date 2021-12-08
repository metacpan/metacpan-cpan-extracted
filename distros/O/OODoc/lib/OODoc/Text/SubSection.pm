# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Text::SubSection;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}      ||= 'Subsection';
    $args->{container} ||= delete $args->{section} or panic;
    $args->{level}     ||= 3;

    $self->SUPER::init($args) or return;
    $self->{OTS_subsubsections} = [];
    $self;
}

sub emptyExtension($)
{   my ($self, $container) = @_;
    my $empty = $self->SUPER::emptyExtension($container);
    my @subsub = map $_->emptyExtension($empty), $self->subsubsections;
    $empty->subsubsections(@subsub);
    $empty;
}

sub findEntry($)
{  my ($self, $name) = @_;
   $self->name eq $name ? $self : ();
}

#-------------------------------------------


sub section() { shift->container }


sub chapter() { shift->section->chapter }

sub path()
{   my $self = shift;
    $self->section->path . '/' . $self->name;
}

#-------------------------------------------


sub subsubsection($)
{   my ($self, $thing) = @_;

    if(ref $thing)
    {   push @{$self->{OTS_subsubsections}}, $thing;
        return $thing;
    }

    first {$_->name eq $thing} $self->subsubsections;
}


sub subsubsections(;@)
{   my $self = shift;
    if(@_)
    {   $self->{OTS_subsubsections} = [ @_ ];
        $_->container($self) for @_;
    }

    @{$self->{OTS_subsubsections}};
}


1;

1;
