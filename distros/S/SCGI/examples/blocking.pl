#!/usr/bin/perl

use strict;
use warnings;

use SCGI;
use IO::Socket::INET;
use Data::Dumper;

my $socket = IO::Socket::INET->new(
  Listen => 5,
  ReuseAddr => SO_REUSEADDR,
  LocalPort => 9090
) or die "cannot bind to port 9090: $!";

my $scgi = SCGI->new($socket, blocking => 1);

while (my $request = $scgi->accept) {
  $request->read_env;
  $request->socket->print("Content-Type: text/plain\n\n");
  $request->socket->print(Dumper $request->env);
  $request->close;
}
