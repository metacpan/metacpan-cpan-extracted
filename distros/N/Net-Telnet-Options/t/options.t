#!/usr/bin/perl -w

require 5.008;

use Test::Simple tests => 21;
use Data::Dumper;
use Net::Telnet::Options;

my $nto = Net::Telnet::Options->new();

# Terminal type option: 24
# How it Works
#  Server wants to know which terminal types the client supports/prefers.
#  Server sends 'DO TTYPE'
#  Client answers 'WILL TTYPE'
#  Server sends 'SB TTYPE SEND'
#  Client answers 'SB TTYPE IS .. '
# The SEND/IS loop continues until the client resends the same information 
# twice, at which point the server should stop answering.

# Cheat, with a scalar socket (works only in 5.8.0 ?)

# Pretend to be a client

$nto->acceptDoOption('TTYPE', {'SB' => \&ttype_sb_callback } );
my $ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

sub ttype_sb_callback
{
    my ($cmd, $subcmd, $data, $pos) = @_;

    ok($cmd eq 'SEND' && $pos == 0, "Callback got SEND at position 0");
# sendOpt (socket, command, option name/number, suboption)

    $nto->sendOpt($socket, 'SB', 24, 'IS', 'VT100');
#    print "Callback got: $cmd, $subcmd, $data, $pos\n";
    return ;
}

my $data = chr(255) . chr(253) . chr(24);

my $returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq '', "Removed DO telnet option from string");
ok($nto->{telnetopts}{TTYPE}{STATUS_ME} eq 'WILL', "Parse DO option");
ok($ssocket eq chr(255) . chr(251) . chr(24), "Sent WILL option");

$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";
# IAC SB TERMINAL-TYPE SEND IAC SE
$data = chr(255) . chr(250) . chr(24) . chr(1) . chr(255) . chr(240);

$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq '', "Removed SB telnet option from string");
ok($ssocket eq chr(255) . chr(250) . chr(24) . chr(0) . 'VT100' . 
               chr(255) . chr(240),
   "Sent 'VT100' via sendOpt");


# Pretend to be a server
$nto = Net::Telnet::Options->new();

$nto->activeDoOption('NAWS', {'SB' => \&naws_sb_callback } );
ok($nto->{telnetopts}{NAWS}{ACTIVE} == 1, "Active status on");

sub naws_sb_callback
{
  my ($cmd, $subcmd, $data, $pos) = @_;
  ok($cmd eq 'IS', "SB callback with IS");
# print ("NAWS SB: $cmd\n");

  return unless($cmd eq 'IS');
  my ($width, $height) = unpack('nn', $subcmd);
  ok($width = 80 && $height = 24, "Got NAWS width 80, hieght 24");
#  print ("NAWS width, height: $width, $height\n");
  return undef;
}

$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

$nto->doActiveOptions($socket);
close($socket);
ok($ssocket eq chr(255) . chr(253) . chr(31), "Socket got DO NAWS");
ok($nto->{telnetopts}{NAWS}{STATUS_YOU} eq 'ASKING', "Status ASKING");

$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

$data = chr(255) . chr(251) . chr(31);

$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq '', "Removed WILL telnet option from string");
ok($nto->{telnetopts}{NAWS}{STATUS_YOU} eq 'WILL', "Status WILL");

# IAC SB NAWS <16-bit value> <16-bit value> IAC SE
$data = chr(255) . chr(250) . chr(31) .  
    chr(0) . chr(80) . chr(0) . chr(24) .
    chr(255) . chr(240);
$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq '', "Removed SB telnet option from string");

# Check chr 255 gets deduplicated
$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

$data = chr(255) . chr(255);

$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq chr(255), "Found 255 in string");

# Try no options ;)

$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

$data = "Hello World";

$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);

ok($returned eq "Hello World", "Left normal text alone");

# Parse option line in two halves

$ssocket = '';
open $socket, "+<", \$ssocket or die "Can't open socket scalar ($!)\n";

$data = chr(255);
$returned = $nto->answerTelnetOpts($socket, $data);

ok($returned eq '', "Swallowed half an option");
$data = chr(255);
$returned = $nto->answerTelnetOpts($socket, $data);
close($socket);
ok($returned eq chr(255), "Got single char 255 back");

# New with options.. 
# BINARY is option 0 

$nto = undef;
my %options = (BINARY => { 'DO' => sub {} },
               90     => { 'DO' => sub {} } );

$nto = Net::Telnet::Options->new(%options);

ok(exists $nto->{telnetopts}{MSP}{DO} && 
   exists $nto->{telnetopts}{BINARY}{DO}, "Added two options via new()");
ok(exists $nto->getTelnetOptState("MSP")->{DO}, "getTelnetOptState MSP exists");
$nto->removeOption(0);

ok(!exists $nto->{telnetopts}{BINARY}, "Removed option by number");

# print "Returned: $returned\n";
# print Dumper($nto);
# print "SSocket : ", join(' ', map { ord $_ } split(//, $ssocket)), "\n";

