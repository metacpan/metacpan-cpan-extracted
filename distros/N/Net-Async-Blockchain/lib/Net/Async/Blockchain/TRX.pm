package Net::Async::Blockchain::TRX;

use strict;
use warnings;

our $VERSION = '0.005';

=head1 NAME

Net::Async::Blockchain::TRX - Tron based subscription.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new;

    $loop->add(
        my $trx_client = Net::Async::Blockchain::TRX->new(
            subscription_url => "tcp://127.0.0.1:5555",
            blockchain_code  => 'Tron',
        )
    );

    $trx_client->subscribe("blocks")->each(sub { print shift->{hash} })->get;

=head1 DESCRIPTION

Tron subscription using ZMQ from the tron based blockchain nodes

=over 4

=back

=cut

no indirect;

use Net::Async::Blockchain::Client::ZMQ;
use Future::AsyncAwait;
use curry;

use parent qw(Net::Async::Blockchain);

my %subscription_dictionary = (
    'blocks' => 'block',
);

=head2 zmq_client

Returns the current instance for L<Net::Async::Blockchain::Client::ZMQ> if not created
create a new one.

=over 4

=back

L<Net::Async::Blockchain::Client::ZMQ>

=cut

sub zmq_client {
    my ($self) = @_;
    return $self->{zmq_client} //= do {
        $self->add_child(
            my $zmq_client = Net::Async::Blockchain::Client::ZMQ->new(
                endpoint    => $self->subscription_url,
                timeout     => $self->subscription_timeout,
                msg_timeout => $self->subscription_msg_timeout,
                on_shutdown => sub {
                    my ($error) = @_;
                    warn $error;
                },
            ));
        $zmq_client;
    }
}

=head2 subscribe

Connect to the ZMQ port and subscribe to the implemented subscription: https://tronprotocol.github.io/documentation-en/architecture/event/#using-java-trons-built-in-message-queue-for-event-subscription

=over 4

=item * C<subscription> string subscription name

=back

L<Ryu::Source>

=cut

async sub subscribe {
    my ($self, $subscription) = @_;
    my $subscription_event = $subscription_dictionary{$subscription} or die "Invalid or not implemented subscription";
    return $self->zmq_client->subscribe($subscription_event)->map(
        $self->$curry::weak(
            sub {
                my ($self, $message) = @_;
                return $self->subscription_response($subscription, $message);
            }));
}

1;
