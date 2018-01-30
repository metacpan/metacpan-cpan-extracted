package Net::Async::Ping;
$Net::Async::Ping::VERSION = '0.004001';
use strict;
use warnings;

# ABSTRACT: asyncronously check remote host for reachability

use Module::Runtime 'use_module';
use namespace::clean;

my %method_map = (
   tcp    => 'TCP',
   icmp   => 'ICMP',
   icmpv6 => 'ICMPv6',
);

sub new {
   my $class = shift;

   my $method = shift || 'tcp';

   die "The '$method' proto of Net::Ping not ported yet"
      unless $method_map{$method};

   my @args;
   if (ref $_[0]) {
      @args = (%{$_[0]})
   } else {
      my ($default_timeout, $bytes, $device, $tos, $ttl) = @_;

      @args = (
         (@_ >= 1 ? (default_timeout => $default_timeout) : ()),
         (@_ >= 2 ? (bytes => $bytes) : ()),
         (@_ >= 3 ? (device => $device) : ()),
         (@_ >= 4 ? (tos => $tos) : ()),
         (@_ >= 5 ? (ttl => $ttl) : ()),
      )
   }
   use_module('Net::Async::Ping::' . $method_map{$method})->new(@args)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping - asyncronously check remote host for reachability

=head1 VERSION

version 0.004001

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Ping;

 my $p = Net::Async::Ping->new;
 my $loop = IO::Async::Loop->new;

 my $future = $p->ping($loop, 'myrealbox.com');

 $future->on_done(sub {
    say "good job the host is running!"
 });
 $future->on_fail(sub {
    say "the host is down!!!";
 });

 # With a timer
 my $timer;
 $timer = IO::Async::Timer::Periodic->new(
    interval => 1,
    on_tick  => sub {
        $timer->adopt_future(
            $p->ping($loop, 'myrealbox.com')
                ->on_done(sub { say "good job the host is running!" })
                ->on_fail(sub { say "the host is down!!!" })
                ->else_done
        );
    },
 );
 $timer->start;

 $l->add( $timer );
 $l->run;

=head1 DESCRIPTION

This module's goal is to eventually be able to test remote hosts
on a network with a number of different socket types and protocols.
Currently it only supports TCP and ICMP, but UDP, and Syn are planned.
If you need one of those feel free to work up a patch.

This module was originally forked off of L<Net::Ping>, so it shares B<some> of it's interface, but only where it makes sense.

=head1 METHODS

=head2 new

 my $p = Net::Async::Ping->new(
   $proto, $def_timeout, $bytes, $device, $tos, $ttl,
 );

All arguments to new are optional, but if you want to provide one in the
middle you must provide all the ones to the left of it.  The default
protocol is C<tcp>.  The default timeout is 5 seconds.
C<device> is what host to bind the socket to, ie what to ping B<from>.
C<bytes>, C<tos> and C<ttl> do not currently apply.

Alternately, you can use a new constructor:

 my $p = Net::Async::Ping->new(
   tcp => {
      default_timeout => 10,
      bind            => '192.168.1.1',
      port_number     => 80,
   },
 );

All of the above arguments are optional. Bind is the same as device from
before.

See L<Net::Async::Ping::TCP> and L<Net::Async::Ping::ICMP> for module specific
options.

=head2 ping

 my $future = $p->ping($loop, $host, $timeout);

Returns a L<Future> representing the ping.  C<loop> should be an
L<IO::Async::Loop>, host is the host, and timeout is optional and defaults to
the default set above.

It's also possible to omit the $loop, and add the pinger to a loop afterwards:

 my $loop = IO::Async::Loop->new;
 $p->ping($host);
 $loop->add( $p );

The return value of the future depends on the protocol. See
L<Net::Async::Ping::TCP> and L<Net::Async::Ping::ICMP>.

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
