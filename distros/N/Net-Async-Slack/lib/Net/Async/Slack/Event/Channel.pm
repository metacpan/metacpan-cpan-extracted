package Net::Async::Slack::Event::Channel;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

sub channel {
    my ($self) = @_;
    $self->{channel} //= $self->slack->channel_info($self->channel_id)
}
sub user {
    my ($self) = @_;
    $self->{user} //= $self->slack->user_info($self->user_id)
}

sub channel_id { shift->{channel_id} }

sub user_id { shift->{user_id} }

1;

