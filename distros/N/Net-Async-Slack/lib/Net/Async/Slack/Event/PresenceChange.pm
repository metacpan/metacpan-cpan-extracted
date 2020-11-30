package Net::Async::Slack::Event::PresenceChange;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

{
"type":"presence_change",
"presence":"active",
"user":"U5GSPCF1C"
}

=cut

sub user {
    my ($self) = @_;
    $self->{user} //= $self->slack->user_info($self->user_id)
}
sub user_id { shift->{user_id} }

sub presence { shift->{presence} }

sub type { 'presence_change' }

1;

