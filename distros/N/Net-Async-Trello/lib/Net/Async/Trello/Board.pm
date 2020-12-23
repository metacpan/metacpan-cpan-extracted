package Net::Async::Trello::Board;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use parent qw(Net::Async::Trello::Generated::Board);

use JSON::MaybeXS;
use Log::Any qw($log);

my $json = JSON::MaybeXS->new;

=head2 subscribe

=cut

sub subscribe {
	my ($self, %args) = @_;
    my $trello = $self->trello;
    my $board_id = $self->id;
    $log->tracef("Attempting to subscribe to board %s", $board_id);
    $self->{subscribed} ||= {};
    unless($self->{subscribed}{board}{$board_id}) {
        $self->{subscribed}{board}{$board_id} = my $src = $trello->ryu->source(
            label => "board:$board_id"
        );
        $trello->websocket->then(sub {
            my $req_id = $trello->next_request_id;
            my $txt = $json->encode({
                type             => "subscribe",
                modelType        => "Board",
                idModel          => $board_id,
                tags             => [qw(clientActions updates)],
                invitationTokens => [],
                reqid            => $req_id,
            });
        # $txt = '3:::{"sFxn":"ping","rgarg":[],"reqid":' . $req_id . ',"token":"' . $trello->token . '"}';
            $log->tracef(">> %s", $txt);
            $trello->loop->delay_future(after => 1.1)->then(sub {
                $trello->{ws}->send_frame(
                    buffer => $txt,
                    masked => 1,
                )
            })
        })->retain;
        $self->{updated_channel} ||= {};
        $self->{update_channel}{$board_id} = $src;
    }
    $self->{subscribed}{board}{$board_id}
}

=head2 lists

=cut

sub lists {
	my ($self, %args) = @_;
    $self->trello->api_get_list(
		uri => 'boards/' . $self->id . '/lists', # ?filter=closed',
        class => 'Net::Async::Trello::List',
        extra => {
            board  => $self,
        },
    )
}

=head2 cards

=cut

sub cards {
	my ($self, %args) = @_;
    my $uri = URI->new($self->trello->base_uri . 'boards/' . $self->id . '/cards?filter=visible');
    $uri->query_param($_ => $args{$_}) for keys %args;
    $self->trello->api_get_list(
		uri => $uri,
        class => 'Net::Async::Trello::Card',
        per_page => 1000,
        extra => {
            board  => $self,
        },
    )
}

=head2 members

=cut

sub members {
	my ($self, %args) = @_;
    $self->trello->api_get_list(
		uri => 'boards/' . $self->id . '/members',
        class => 'Net::Async::Trello::Member',
        per_page => 1000,
        extra => {
            board  => $self,
        },
    )
}

=head2 create_card

Creates a new card on this board.

=cut

sub create_card {
	my ($self, %args) = @_;
    my %body = (
        name      => $args{name},
        desc      => $args{description},
        pos       => $args{position} // 'bottom',
    );
    $body{idList} = ref($args{list}) ? $args{list}->id : $args{list};
    $body{idMembers} = join(',', map $_->id, @{$args{members}});
	$self->trello->http_post(
		uri => URI->new($self->trello->base_uri . 'cards'),
        body => \%body,
	)->transform(
        done => sub {
            Net::Async::Trello::Card->new(
                %{ $_[0] },
                board => $self,
                trello => $self->trello,
            )
        }
    )
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2020. Licensed under the same terms as Perl itself.
