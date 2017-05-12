#!/bin/sh
#-*-Perl-*-

exec perl -x $0 "$@"

#!perl

use Net::Jabber qw(Client);
use strict;

if ($#ARGV < 3) {
  print "\nperl client.pl <server> <port> <username> <password> \n\n"
;
  exit(0);
}

my $server = $ARGV[0];
my $port = $ARGV[1];
my $username = $ARGV[2];
my $password = $ARGV[3];


$SIG{HUP} = \&Stop;
$SIG{KILL} = \&Stop;
$SIG{TERM} = \&Stop;
$SIG{INT} = \&Stop;

my $Connection = new Net::Jabber::Client();

$Connection->RPCSetCallBacks(add=>\&add);

my $status = $Connection->Connect("hostname" => $server,
                                  "port" => $port);

if (!(defined($status))) {
  print "ERROR:  Jabber server is down or connection was not allowed.\n";
  print "        ($!)\n";
  exit(0);
}

my @result = $Connection->AuthSend("username" => $username,
                                   "password" => $password,
                                   "resource" => "RPCServer");

if ($result[0] ne "ok") {
  print "ERROR: Authorization failed: $result[0] - $result[1]\n";
  exit(0);
}

print "Logged in to $server:$port...\n";

while(1) {
  $Connection->Process();
}

sub Stop {
  print "Exiting...\n";
  $Connection->Disconnect();
  exit(0);
}

sub add {
  my $iq = shift;
  my $params = shift;

  print $params->[0]," + ",$params->[1]," = ",$params->[0] + $params->[1],"\n";

  return ("ok", [ $params->[0] + $params->[1] ]);
}
