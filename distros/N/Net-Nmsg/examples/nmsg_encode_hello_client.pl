#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Output;
use Net::Nmsg::Msg;

use Time::HiRes;

my $o;
my $b = 0;
if (! @ARGV) {
  @ARGV = ('127.0.0.1', 9430);
}
if ($ARGV[0] eq '-b') {
  $b = 1;
  shift @ARGV;
}
if (@ARGV == 2) {
  # Note: IPv6 will work if IO::Socket::INET6 is installed
  $o = Net::Nmsg::Output->open_sock(@ARGV, broadcast => $b);
  print STDERR "sending on @ARGV (broadcast = $b)\n";
}
else {
  print STDERR "Usage: $0 [[-b] <ADDR> <PORT>]\n";
  exit 1;
}

my $m = Net::Nmsg::Msg::base::encode->new();

my $itermax = 2;

sub send_msg {
  my($e_type, $e_payload) = @_;
  my $t = Time::HiRes::time();
  $m->time(int($t), int(($t - int($t)) * 1E9));
  $m->set_type($e_type);
  $m->set_payload($e_payload);
  $o->write($m);
}

# TEXT
for my $i (0 .. $itermax) {
  my $hello = "hello world $i";
  send_msg(TEXT => $hello);
}
print "sent TEXT-encoded payloads\n";

# JSON
eval "use JSON qw()";
if ($@) {
  print "no JSON support\n";
}
else {
  my %hello = (hello => 'world', foo => 'bar');
  for my $i (0 .. $itermax) {
    $hello{id} = $i;
    send_msg(JSON => JSON::encode_json(\%hello));
  }
  print "sent JSON-encoded payloads\n";
}

# YAML
eval "use YAML qw()";
if ($@) {
  print "no YAML support\n";
}
else {
  my %hello = (hello => 'world', foo => 'bar');
  for my $i (0 .. $itermax) {
    $hello{id} = $i;
    send_msg(YAML => YAML::Dump(\%hello));
  }
  print "sent YAML-encoded payloads\n";
}

# MSGPACK
eval "use Data::MessagePack";
if ($@) {
  print "no MSGPACK support\n";
}
else {
  my $mp = Data::MessagePack->new;
  my %hello = (hello => 'world', foo => "q\x00\x00x");
  for my $i (0 .. $itermax) {
    $hello{id} = $i;
    send_msg(MSGPACK => $mp->pack(\%hello));
  }
  print "sent MSGPACK-encoded payloads\n";
}
# XML 
eval "use XML::Dumper";
if ($@) {
  for my $i (0 .. $itermax) {
    send_msg(XML => '<xml/>');
  }
  print "sent dummy XML-encoded payloads\n";
}
else {
  my %hello = (hello => 'world', foo => "q\x00\x00x");
  my $xdump = XML::Dumper->new;
  for my $i (0 .. $itermax) {
    $hello{id} = $i;
    send_msg(XML => $xdump->pl2xml(\%hello));
  }
  print "sent XML-encoded payloads\n";
}
