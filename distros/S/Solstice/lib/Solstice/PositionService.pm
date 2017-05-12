package Solstice::PositionService;

# $Id: PositionService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::PositionService - Queueing and positioning info for collections of objects.

=head1 SYNOPSIS

    use Solstice::PositionService;
    my $position_service = new Solstice::PositionService;

    # get zero-indexed position in queue
    my $position = $position_service->enqueue();

    #am I the last one?
    if ( $position == ($position_service->getQueueSize() - 1)){
        ...
    }

=head1 DESCRIPTION
    
=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods 

=over 4

=cut

=item initialize($id, $value)

Sets the position value for the passed $id to $value, or 0 if $value is undefined. Returns undef.

=cut

sub initialize {
    my $self  = shift;
    my $id    = shift || caller;
    my $value = shift || 0;

    $self->set($id, $value);

    return;
}

=item enqueue([$id])

Increment the position value for the passed $id. If the value is not defined,
it is initialized as 0. Returns the current position value.

=cut

sub enqueue {
    my $self = shift;
    my $id   = shift || caller;
    
    my $position = $self->get($id) || 0;
    $self->set($id, $position + 1);

    return $position;
}

=item reset([$id])

Sets the position value for the passed $id to 0. Returns undef.

=cut

sub reset {
    my $self = shift;
    my $id   = shift || caller;

    $self->set($id, 0);

    return;
}

=item getQueueSize([$id])

Returns the current position value for the passed $id, or 0 if not defined.

=cut

sub getQueueSize {
    my $self = shift;
    my $id   = shift || caller;

    return $self->get($id) || 0;
}

=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::PositionService';
}



1;


__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
