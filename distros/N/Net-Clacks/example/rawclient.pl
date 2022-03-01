#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 22;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Term::ReadKey;
use Time::HiRes qw(sleep);
use Data::Dumper;
use IO::Socket::IP;
use IO::Socket::SSL;
use MIME::Base64;

my $peer = shift @ARGV;
if(!defined($peer) || $peer !~ /\:/) {
    die("Usage: rawclient.pl host:port");
}

my ($host, $port) = split/\:/, $peer;
my $username = 'exampleuser';
my $password = 'unsafepassword';
my $authtoken = encode_base64($username, '') . ':' . encode_base64($password, '');
my @initcommands = (
    "CLACKS devclient",
    "OVERHEAD A $authtoken",
    "NOPING",
);

my $socket = IO::Socket::IP->new(
    PeerHost => $host,
    PeerPort => $port,
    Type => SOCK_STREAM,
) or croak("Failed to connect to Clacks message service: $ERRNO");

binmode($socket, ':bytes');
$socket->blocking(0);

IO::Socket::SSL->start_SSL($socket,
                           SSL_verify_mode => SSL_VERIFY_NONE,
                           ) or croak("Can't use SSL: " . $SSL_ERROR);

# Auth
foreach my $initcmd (@initcommands) {
    print '>', $initcmd, "\n";
    syswrite($socket, $initcmd . "\r\n");
}

my $keepRunning = 1;
$SIG{TERM} = sub { 
    $keepRunning = 0; 
    print "Quitting...\n";
};
$SIG{INT} = sub { 
    $keepRunning = 0; 
    print "Quitting...\n";
};

my $haswork = 0;
while($keepRunning) {
    # Client -> Server
    my $line = ReadLine -1;

    $haswork = 0;

    if(defined($line)) {
        chomp $line;
        if($line eq 'QUIT') {
            last;
        }
        if(length($line)) {
            $line .= "\r\n";
            syswrite($socket, $line);
            $haswork = 1;
        }
    }

    # Server -> Client
    my $buf;
    sysread($socket, $buf, 1000);
    if(defined($buf)) {
        print $buf;
        $haswork = 1;
    }
    if(!$haswork) {
        sleep(0.05);
    }
}

syswrite($socket, "QUIT\r\n");
