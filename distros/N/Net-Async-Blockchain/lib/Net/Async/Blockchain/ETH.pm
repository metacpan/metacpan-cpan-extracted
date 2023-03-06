package Net::Async::Blockchain::ETH;

use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Net::Async::Blockchain::ETH - Ethereum based subscription.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new;

    $loop->add(
        my $eth_client = Net::Async::Blockchain::ETH->new(
            subscription_url => "ws://127.0.0.1:8546",
            blockchain_code  => 'Ethereum',
        )
    );

    $eth_client->subscribe("blocks")->each(sub { print shift->{hash} })->get;

=head1 DESCRIPTION

Ethereum subscription using websocket node client

=over 4

=back

=cut

no indirect;

use Net::Async::Blockchain::Client::Websocket;
use curry;
use Future::AsyncAwait;

use parent qw(Net::Async::Blockchain);

my %subscription_dictionary = ('blocks' => 'newHeads');

=head2 subscription_id

Actual subscription ID, this ID is received every time when a subscription
is created.

=over 4

=back

An hexadecimal string

=cut

sub subscription_id { shift->{subscription_id} }

=head2 websocket_client

Returns the current instance for L<Net::Async::Blockchain::Client::Websocket> if not created
create a new one.

=over 4

=back

L<Net::Async::Blockchain::Client::Websocket>

=cut

sub websocket_client {
    my ($self) = @_;
    return $self->{websocket_client} //= do {
        $self->add_child(
            my $websocket_client = Net::Async::Blockchain::Client::Websocket->new(
                endpoint    => $self->subscription_url,
                on_shutdown => sub {
                    my ($error) = @_;
                    warn $error;
                },
            ));
        $websocket_client;
    }
}

=head2 subscribe

Connect to the websocket port and subscribe to the implemented subscription:
- https://github.com/ethereum/go-ethereum/wiki/RPC-PUB-SUB#create-subscription

=over 4

=item * C<subscription> string subscription name

=back

L<Ryu::Source>

=cut

async sub subscribe {
    my ($self, $subscription) = @_;

    my $subscription_event = $subscription_dictionary{$subscription} or die "Invalid or not implemented subscription";
    my $source             = await $self->websocket_client()->eth_subscribe($subscription_event);

    # the first response from the node is the subscription id
    # once we received it we can start to listening the subscription.
    return $source->skip_until(
        $self->$curry::weak(
            sub {
                my ($self, $response) = @_;
                return 1                                       unless $response->{result};
                $self->{subscription_id} = $response->{result} unless $self->{subscription_id};
                return 0;
            }))
        # we use the subscription id received as the first response to filter
        # all incoming subscription responses.
        ->filter(
        $self->$curry::weak(
            sub {
                my ($self, $response) = @_;
                return undef unless $response->{params} && $response->{params}->{subscription};
                return $response->{params}->{subscription} eq $self->subscription_id;
            })
    )->map(
        $self->$curry::weak(
            sub {
                my ($self, $response) = @_;
                return $self->subscription_response($subscription, $response);
            }));
}

1;
