package Myriad::RPC::Client;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

no indirect qw(fatal);
use Scalar::Util qw(weaken);
use utf8;

=encoding utf8

=head1 NAME

Myriad::RPC::Client - microservice RPC client abstraction

=head1 SYNOPSIS

 my $client = $myriad->rpc_client;

=head1 DESCRIPTION

=cut

use Myriad::Exception::Builder category => 'rpc_client';

=head2 Exceptions

=cut

=head2 RPCFailed

The RPC call has been performed correctly but the results are an error.

=cut

declare_exception RPCFailed => (message => 'Your operation failed');

=head2 UnknownTransport

RPC transport does not exist.

=cut

declare_exception UnknownTransport => (
    message => 'Unknown transport'
);

sub new {
    my ($class, %args) = @_;
    my $transport = delete $args{transport};
    weaken(my $myriad = delete $args{myriad});
    # Passing args individually looks tedious but this is to avoid
    # L<IO::Async::Notifier> exception when it doesn't recognize the key.

    if ($transport eq 'redis') {
        require Myriad::RPC::Client::Implementation::Redis;
        return Myriad::RPC::Client::Implementation::Redis->new(
            redis   => $myriad->redis,
        );
    } elsif ($transport eq 'perl') {
        require Myriad::RPC::Client::Implementation::Perl;
        return Myriad::RPC::Client::Implementation::Perl->new(
            transport => $myriad->perl_transport
        );
    } else {
        Myriad::Exception::RPC::Client::UnknownTransport->throw();
    }
}

1;

