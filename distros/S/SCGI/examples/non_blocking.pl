#!/usr/bin/perl

use strict;
use warnings;

use Event::Lib qw(show_method);

use SCGI;
use IO::Socket::INET;

##
# This example currently leaks memory (at least on my debian system)
# There were some SV's being lost by Event::Lib, but this has been fixed now,
# and Devel::Leak indicates that the number of SV's is not increasing. However
# the process size steadily increases :'(
##

my $socket = IO::Socket::INET->new(
  Listen => 5,
  ReuseAddr => SO_REUSEADDR,
  LocalPort => 9090,
  Proto => 'tcp',
  Blocking => 0,
) or die "cannot bind to port 9090: $!";

my $scgi = SCGI->new($socket);

sub accept {
  my $event = shift;
  my $request = $scgi->accept;
  event_new(
    $request->socket,
    EV_READ|EVLOOP_ONCE,
    \&handle,
    $request,
  )->add;
}

sub handle {
  my ($event, undef, $request) = @_;
  if ($request->read_env) {
    $request->set_blocking(1);
    $request->socket->print("Content-Type: text/plain\n\n");
    $request->socket->print('hello');
    $event->free;
    $request->close;
  }
  else {
    $event->add;
  }
}

my $event = event_new($scgi->socket, EV_READ|EV_PERSIST, \&accept);
$event->add;
$event->dispatch;
