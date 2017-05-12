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

$Connection->SetCallBacks("message" => \&InMessage,
                          "presence" => \&InPresence,
                          "iq" => \&InIQ);

my $status = $Connection->Connect("hostname" => $server,
                                  "port" => $port);

if (!(defined($status))) {
  print "ERROR:  Jabber server is down or connection was not allowed.\n";
  print "        ($!)\n";
  exit(0);
}

my @result = $Connection->AuthSend("username" => $username,
                                   "password" => $password,
                                   "resource" => "RPCClient");

if ($result[0] ne "ok") {
  print "ERROR: Authorization failed: $result[0] - $result[1]\n";
  exit(0);
}

print "Logged in to $server:$port...\n";

my @response = $Connection->RPCCall(to=>"$username\@$server/RPCServer",
				    methodName=>"add",
				    params=>[5,4]);

if ($response[0] eq "ok") {
  print "5 + 4 = ",$response[1]->[0],"\n";
}

sub Stop {
  print "Exiting...\n";
  $Connection->Disconnect();
  exit(0);
}
