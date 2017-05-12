#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;
use IO::Socket::SSL;

my $ppid = $$;
END { print "[$$] ", $$==$ppid ? "ppid ":"", "exit\n" };
print "[$$] ppid started\n";

$SIG{__WARN__} = sub { print "[$$] $_[0]" };
$SIG{__DIE__}  = sub { print "[$$] $_[0]"; exit 0 };

my $class = $ENV{ca_use_ssl} ? "IO::Socket::SSL" : "IO::Socket::INET";
my $port  = $ENV{ca_use_ssl} ? 19794 : 19795;

my @pids;
for( 1 .. 5 ) {
    if( my $pid = fork ) {
        push @pids, $pid;

    } else {
        print "[$$] start\n";
        my $sock = $class->new(PeerAddr=>"localhost:$port", Timeout=>2) or die "couldn't bind: $@";
        while( my $line = $sock->getline ) {
            print "[$$] $line";
        }

        my $eof = ($sock->eof() ? "EOF" : "...");
        my $ced = ($sock->connected() ? "CONNECTED" : "...");

        my $time = time;
        print "[$$] time: $time; eof: $eof; ced: $ced\n";
        exit 0;
    }
}

waitpid( $_, 0 ) for @pids;
