package Myriad::Subscription;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

no indirect qw(fatal);
use Scalar::Util qw(weaken);
use utf8;

=encoding utf8

=head1 NAME

Myriad::Subscription - microservice Subscription abstraction

=head1 SYNOPSIS

 my $sub = Myriad::Subscription->new();

=head1 DESCRIPTION

=cut

use Myriad::Exception::Builder category => 'subscription';

=head1 Exceptions

=head2 UnknownTransport

Subscription transport does not exist.

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
        require Myriad::Subscription::Implementation::Redis;
        return Myriad::Subscription::Implementation::Redis->new(
            redis   => $myriad->redis,
        );
    } elsif ($transport eq 'memory' or $transport eq 'perl') {
        require Myriad::Subscription::Implementation::Memory;
        return Myriad::Subscription::Implementation::Memory->new(
            transport => $myriad->memory_transport
        );
    } else {
        Myriad::Exception::Subscription::UnknownTransport->throw();
    }
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

