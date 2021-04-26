package Myriad::RPC;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

no indirect qw(fatal);
use Scalar::Util qw(weaken);

use utf8;

=encoding utf8

=head1 NAME

Myriad::RPC - microservice RPC abstraction

=head1 SYNOPSIS

 my $rpc = $myriad->rpc;

=head1 DESCRIPTION

=cut

use Myriad::Exception::Builder category => 'rpc';

=head1 Exceptions

=cut

=head2 InvalidRequest

Returned when there is issue parsing the request, or if the request parameters are incomplete.

=cut

declare_exception InvalidRequest => (
    message => 'Invalid request'
);

=head2 MethodNotFound

Returned if the requested method is not recognized by the service.

=cut

declare_exception MethodNotFound => (
    message => 'Method not found'
);

=head2 Timeout

Returned when there is an external timeout or the request deadline is already passed.

=cut

declare_exception Timeout => (
    message => 'Timeout'
);

=head2 BadEncoding

Returned when the service is unable to decode/encode the request correctly.

=cut

declare_exception BadEncoding => (
    message => 'Bad encoding'
);

=head2 UnknownTransport

RPC transport does not exist.

=cut

declare_exception UnknownTransport => (
    message => 'Unknown transport'
);

=head1 METHODS

=cut

sub new {
    my ($class, %args) = @_;
    my $transport = delete $args{transport};
    weaken(my $myriad = delete $args{myriad});
    # Passing args individually looks tedious but this is to avoid
    # L<IO::Async::Notifier> exception when it doesn't recognize the key.

    if ($transport eq 'redis') {
        require Myriad::RPC::Implementation::Redis;
        return Myriad::RPC::Implementation::Redis->new(
            redis   => $myriad->redis,
        );
    } elsif($transport eq 'memory' or $transport eq 'perl') {
        require Myriad::RPC::Implementation::Memory;
        return Myriad::RPC::Implementation::Memory->new(
            transport => $myriad->memory_transport,
        );
    } else {
        Myriad::Exception::RPC::UnknownTransport->throw;
    }
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

