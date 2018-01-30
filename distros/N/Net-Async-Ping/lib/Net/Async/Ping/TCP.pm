package Net::Async::Ping::TCP;
$Net::Async::Ping::TCP::VERSION = '0.004001';
use Moo;
use warnings NONFATAL => 'all';

use Carp qw/croak/;
use Future;
use POSIX 'ECONNREFUSED';
use Time::HiRes;
use Scalar::Util qw/blessed/;

extends 'IO::Async::Notifier';

use namespace::clean;

has default_timeout => (
   is => 'ro',
   default => 5,
);

has service_check => ( is => 'rw' );

has bind => ( is => 'rw' );

has port_number => (
   is => 'rw',
   default => 7,
);

# Overrides method in IO::Async::Notifier to allow specific options in this class
sub configure_unknown
{   my $self = shift;
    my %params = @_;
    delete $params{$_} foreach qw/default_timeout service_check bind/;
    return unless keys %params;
    my $class = ref $self;
    croak "Unrecognised configuration keys for $class - " . join( " ", keys %params );

}

sub ping {
    my $self = shift;
    # Maintain compat with old API
    my $legacy = blessed $_[0] and $_[0]->isa('IO::Async::Loop');
    my $loop   = $legacy ? shift : $self->loop;

   my ($host, $timeout) = @_;
   $timeout ||= $self->default_timeout;

   my $service_check = $self->service_check;

   my $t0 = [Time::HiRes::gettimeofday];

   return Future->wait_any(
      $loop->connect(
         host     => $host,
         service  => $self->port_number,
         socktype => 'stream',
         ($self->bind ? (
            local_host => $self->bind,
         ) : ()),
      ),
      $loop->timeout_future(after => $timeout)
   )
   ->then(
      sub { Future->done(Time::HiRes::tv_interval($t0)) },
      sub {
         my ($human, $layer) = @_;
         my $ex    = pop;
         if ($layer && $layer eq 'connect') {
            return Future->done(Time::HiRes::tv_interval($t0))
               if !$service_check && $ex == ECONNREFUSED;
         }
         Future->fail(Time::HiRes::tv_interval($t0))
      },
   )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping::TCP

=head1 VERSION

version 0.004001

=head1 DESCRIPTION

This is the TCP part of L<Net::Async::Ping>. See that documentation for full details.

=head2 Return value

L<Net::Async::Ping::TCP> will always terminate with the hi resolution time it
took to check for liveness, with the success or failure checked by
introspecting the future itself.

=head2 Additional options

C<service_check>, which is off by default, will cause ping to fail if the host refuses
connection to the selected port (7 by default.)

 my $p = Net::Async::Ping->new(
   tcp => {
      service_check => 1,
   },
 );

=head1 NAME

Net::Async::Ping::TCP

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arthur Axel "fREW" Schmidt, Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
