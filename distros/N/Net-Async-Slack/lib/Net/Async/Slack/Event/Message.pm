package Net::Async::Slack::Event::Message;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION

use Net::Async::Slack::EventType;

=head1 DESCRIPTION

{
    channel => "D5GSPCF62",
    source_team => "T4PQME0Q2",
    team => "T4PQME0Q2",
    text => "test",
    ts => "1497119268.495648",
    type => "message",
    user => "U4P3UKGBA"
}

=cut

sub slack { shift->{slack} }

sub channel {
    my ($self) = @_;
    $self->{channel} //= $self->slack->channel_info($self->channel_id)
}

sub source_team {
    my ($self) = @_;
    $self->{source_team} //= $self->slack->team_info($self->source_team_id)
}

sub team {
    my ($self) = @_;
    $self->{team} //= $self->slack->team_info($self->team_id)
}

sub channel_id { shift->{channel_id} }

sub source_team_id { shift->{source_team_id} }

sub team_id { shift->{team_id} }

sub text { shift->{text} }

sub ts { shift->{ts} }

sub type { 'message' }

1;

