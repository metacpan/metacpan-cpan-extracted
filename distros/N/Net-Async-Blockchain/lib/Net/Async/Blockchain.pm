package Net::Async::Blockchain;

use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Net::Async::Blockchain - base for blockchain subscription clients.

=head1 SYNOPSIS

Objects of this type would not normally be constructed directly.

For blockchain clients see:
- Net::Async::Blockchain::BTC
- Net::Async::BLockchain::ETH

Which will use this class as base.

=head1 DESCRIPTION

This module contains methods that are shared by the subscription clients.

=over 4

=back

=cut

no indirect;

use parent qw(IO::Async::Notifier);

sub subscription_url : method         { shift->{subscription_url} }
sub subscription_timeout : method     { shift->{subscription_timeout} }
sub subscription_msg_timeout : method { shift->{subscription_msg_timeout} }
sub blockchain_code                   { shift->{blockchain_code} }

=head2 configure

Any additional configuration that is not described on L<IO::Async::Notifier>
must be included and removed here.

=over 4

=item * C<subscription_url> Subscription URL it can be TCP for ZMQ and WS for the Websocket subscription
=item * C<subscription_timeout> Subscription connection timeout
=item * C<subscription_msg_timeout> Subscription interval between messages timeout
=item * C<blockchain_code> The blockchain code (eg: bitcoin, litecoin, ....)

=back

=cut

sub configure {
    my ($self, %params) = @_;

    for my $k (qw(subscription_url subscription_timeout subscription_msg_timeout blockchain_code)) {
        $self->{$k} = delete $params{$k} if exists $params{$k};
    }

    $self->SUPER::configure(%params);
}

=head2 subscription_response

Formate the subscription response message

=over 4

=item * C<$subscription_type> - A string of the subscription type (e.g: blocks)

=item * C<$messgae>           - The recevied subscription message from the blockchain node

=back

Returns a hash reference of:

=over 4

=item * C<blockchain_code>   - A string of the blockchain code (eg: bitcoin, litecoin, ....)

=item * C<subscription_type> - A string of the subscription type (e.g: blocks)

=item * C<message>           - The recevied subscription message from the blockchain node

=back

=cut

sub subscription_response {
    my ($self, $subscription_type, $messgae) = @_;
    return {
        blockchain_code   => $self->blockchain_code,
        subscription_type => $subscription_type,
        message           => $messgae,
    };
}

1;
