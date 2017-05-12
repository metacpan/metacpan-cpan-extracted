package Solstice::OnloadService;

# $Id: OnloadService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::OnloadService - Allows applications to attach Javascript events to the page's onload event.

=head1 SYNOPSIS

  use Solstice::OnloadService;
  
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::StringLibrary qw(strtojavascript);

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::OnloadService object.

=cut

sub new {
    my $obj  = shift;
    return $obj->SUPER::new(@_);
}

=item addEvent($str)

=cut

sub addEvent {
    my $self  = shift;
    my $event = shift;
    return unless defined $event;

    # strip off trailing semicolons on incoming events
    $event =~ s/;+$//g;
    
    my $events = $self->get('onload_events') || [];
    push @$events, $event;
    $self->set('onload_events', $events)
}

=item getEvents()

=cut

sub getEvents {
    my $self = shift;
    
    my $events = $self->get('onload_events') || [];
    
    if (my $focus_id = $self->getFocusTarget()) {
        push @$events, qq|Solstice.Element.focus('$focus_id')|;    
    }
    if (my $scroll_id = $self->getScrollTarget()) {
        push @$events, qq|Solstice.Element.scrollTo('$scroll_id')|;
    }
    return $events;
}

=item setFocusTarget($id)

=cut

sub setFocusTarget {
    my $self = shift;
    $self->set('focus_target_id', shift);
}

=item getFocusTarget()

=cut

sub getFocusTarget {
    my $self = shift;
    return $self->get('focus_target_id');
}

=item setScrollTarget($id)

=cut

sub setScrollTarget {
    my $self = shift;
    $self->set('scroll_target_id', shift);
}

=item getScrollTarget()

=cut

sub getScrollTarget {
    my $self = shift;
    return $self->get('scroll_target_id');
}

=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::OnloadService';
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<StringLibrary|StringLibrary>.

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
