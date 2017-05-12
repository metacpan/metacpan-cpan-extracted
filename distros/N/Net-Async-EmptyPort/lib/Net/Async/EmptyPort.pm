package Net::Async::EmptyPort;
$Net::Async::EmptyPort::VERSION = '0.001000';
# ABSTRACT: Asynchronously wait for a port to open

use Moo;
use Future::Utils 'try_repeat_until_success', 'try_repeat';

has _loop => (
   is       => 'ro',
   init_arg => 'loop',
   required => 1,
   handles => {
      _connect => 'connect',
      _listen => 'listen',
      _delay => 'delay_future',
      _timeout => 'timeout_future',
   },
);

my %family_map = (
   tcp => 'stream',
   udp => 'dgram',
);
sub empty_port {
   my ($self, $args) = @_;

   $args          //= {};
   $args->{host}  //= '127.0.0.1';
   $args->{port}  //= 0;
   $args->{proto} //= 'tcp';

   if ($args->{port} == 0) {
      $self->_listen(
         on_socket => sub {},
         host => $args->{host},
         socktype => $family_map{$args->{proto}},
         service => $args->{port},
      )
   } else {
      my $port = $args->{port};

      try_repeat {
         $self->_listen(
            on_socket => sub {},
            host => $args->{host},
            socktype => $family_map{$args->{proto}},
            service => $port++,
         )
      } while => sub {
         !shift->is_done && $port < 65000
      },
   }
}

sub wait_port {
   my ($self, $args) = @_;

   die 'port is a required argument'
      unless $args->{port};

   $args->{host}     //= '127.0.0.1';
   $args->{proto}    //= 'tcp';
   $args->{max_wait} //= 10;

   my $amount  = 2;
   my $attempt = 0;

   my $f = try_repeat_until_success {
      $self->_delay(
         after => $amount * (2 ** $attempt++) - $amount,
      )->then(sub {
         $self->_connect(
            host => $args->{host},
            socktype => $family_map{$args->{proto}},
            service  => $args->{port},
         )
      })
   };

   $f = Future->wait_any(
      $f,
      $self->_timeout( after => $args->{max_wait} )
   ) if $args->{max_wait} > 0;

   $f
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::EmptyPort - Asynchronously wait for a port to open

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::EmptyPort;

 my $loop = IO::Async::Loop->new;
 my $ep = Net::Async::EmptyPort->new(
    loop => $loop,
 );

 # could take a while to start...
 my $chosen_port = start_server_in_background();

 $ep->wait_port({ port => $chosen_port })->get;

=head1 DESCRIPTION

This module is an asynchronous port of L<Net::EmptyPort>.  The interface is
different and thus simplified from the original.  A couple of the original
methods are not implemented; specifically C<can_bind> and C<check_port>.  They
are not hard to implement but I don't have a good idea of why someone would use
them.

=head1 METHODS

=head2 empty_port

 my $listen_future = $ep->empty_port({
    host => '192.168.1.1',
    port => 8000,
    proto => 'tcp',
 });

This method has no required arguments but accepts the following named
parameters:

=over

=item * C<host>

Defaults to C<127.0.0.1>

=item * C<port>

Defaults to C<0>; which means the kernel will immediately provide an open port.
Alternately, if you provide a port C<Net::Async::EmptyPort> will try that port
up through to port C<65000>.

=item * C<proto>

Defaults to C<tcp>; the other option is C<udp>.

=back

The return value is an L<IO::Async::Listener>.  The easiest way (though this
will introduce a race condition) to make it work like the original is as
follows:

 $ep->empty_port->then(sub { Future->done(shift->read_handle->sockport) })

Then the Future will simply contain the port, though a better option is to pass
the actual listener or socket to whatever will use it if possible.

=head2 wait_port

 my $socket_future = $ep->wait_port({
    port => 8080,
    proto => 'tcp',
    host => '192.168.1.1',
    max_wait => 60,
 });

This method takes the following named parameters:

=over

=item * C<host>

Defaults to C<127.0.0.1>

=item * C<port>

Required.

=item * C<proto>

Defaults to C<tcp>; the other option is C<udp>.

=item * C<max_wait>

Defaults to C<10> seconds.  Set to C<-1> to wait indefinitely.

=back

The return value is a L<Future> containing an L<IP::Socket::IP>.  You can use
that for connecting, but unlike L</empty_port> there is no race condition here
so it makes perfect sense to just use C<wait_port> as a "blocker."

C<wait_port> uses a basic exponential backoff to avoid quickly polling.
Eventually the backoff method will be configurable.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
