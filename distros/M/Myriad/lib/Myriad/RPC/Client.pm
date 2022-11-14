package Myriad::RPC::Client;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::RPC::Client - microservice RPC client abstraction

=head1 SYNOPSIS

 my $client = $myriad->rpc_client;

=head1 DESCRIPTION

=cut

no indirect qw(fatal);
use Scalar::Util qw(weaken);

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
            redis   => $myriad->redis_transport,
        );
    } elsif ($transport eq 'memory' or $transport eq 'perl') {
        require Myriad::RPC::Client::Implementation::Memory;
        return Myriad::RPC::Client::Implementation::Memory->new(
            transport => $myriad->memory_transport
        );
    } else {
        Myriad::Exception::RPC::Client::UnknownTransport->throw();
    }
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

