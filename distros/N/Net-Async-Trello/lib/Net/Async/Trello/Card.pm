package Net::Async::Trello::Card;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use parent qw(Net::Async::Trello::Generated::Card);

use Unicode::UTF8 ();
use Log::Any qw($log);

=head1 NAME

Net::Async::Trello::Card

=head1 DESCRIPTION

Card interaction.

=cut

sub history {
    my ($self, %args) = @_;
    my $trello = $self->trello;
    my $filter = delete $args{filter};
    my $uri = URI->new(
        $trello->base_uri . 'cards/' . $self->id . '/actions/?member=false'
    );
    if(ref $filter) {
        $uri->query_param(filter => @$filter)
    } elsif($filter) {
        $uri->query_param(filter => $filter)
    } else {
        $uri->query_param(filter => 'all')
    }
    $uri->query_param($_ => $args{$_}) for keys %args;
    $trello->api_get_list(
        uri   => $uri,
        class => 'Net::Async::Trello::CardAction',
        extra => {
            card => $self
        }
    )
}

sub update {
    my ($self, %args) = @_;
    my $trello = $self->trello;
    $trello->http_put(
        uri => URI->new(
            $trello->base_uri . 'cards/' . $self->id
        ),
        body => \%args
    )
}

=head2 add_comment

Helper method to add a comment to a card as the current user.

Takes a single C<$comment> parameter, this should be the text to add (in
standard Trello Markdown format).

=cut

sub add_comment {
    my ($self, $comment) = @_;
    my $trello = $self->trello;
    $trello->http_post(
        uri => URI->new(
            $trello->base_uri . 'cards/' . $self->id . '/actions/comments?text=' . Unicode::UTF8::encode_utf8($comment)
        ),
        body => { }
    )
}

=head2 in_list_since

Returns the date when this card was moved to the current list, as an ISO8601 string.

=cut

sub in_list_since {
    my ($self, $comment) = @_;
    my $trello = $self->trello;
	# We call the endpoint with limit=1 here to find the most recent idList update
    $trello->http_get(
        uri => URI->new(
            $trello->base_uri . 'cards/' . $self->id . '/actions?filter=updateCard:idList&limit=1'
        ),
    )->then(sub {
        my $date = shift->[0]->{date}
			or return Future->done($self->created_at);
        Future->done($date);
    })
}

=head2 created_at

Uses the card action history to find when it was created.

Note that the date is currently embedded in the ID, so if you
want to avoid the extra API call you can use that information
via an algorithm such as L<https://steveridout.github.io/mongo-object-time/>

=cut

sub created_at {
    my ($self, $comment) = @_;
    my $trello = $self->trello;
    $trello->http_get(
        uri => URI->new(
            $trello->base_uri . 'cards/' . $self->id . '/actions&limit=1&since=0'
        ),
    )->then(sub {
        Future->done(shift->[0]->{date});
    })
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org> with contributions from C<@felipe-binary>

=head1 LICENSE

Copyright Tom Molesworth 2014-2020. Licensed under the same terms as Perl itself.
