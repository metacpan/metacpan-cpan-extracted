#!/usr/bin/perl

# These tests are based heavily on those included in the Sys::Syscall 0.21 distribution.

use strict;
use Test::More;
use Sys::Sendfile::FreeBSD qw(sendfile);
use IO::Socket::INET;
use File::Temp qw(tempdir);

plan tests => 2;

my $ip   = "127.0.0.1";
my $port = 60001;
my $child;

my $content = "I am a test file!\n" x (5 * 1024);
my $clen    = length($content);

END {
    kill 9, $child if $child;
}

# make child to listen and receive
if ($child = fork()) { parent(); }
else { child();  }

exit 0;

sub parent {
    my $sock;
    my $tries = 0;
    while (! $sock && $tries++ < 5) {
        $sock = IO::Socket::INET->new(PeerAddr => "$ip:$port");
        last if $sock;
        select undef, undef, undef, 0.25;
    }
    die "no socket" unless $sock;

    my $dir = tempdir(CLEANUP => 1) or die "couldn't make tempdir";
    my $tfile = "$dir/test";
    open (F, ">$tfile") or die "couldn't write to test file in $dir: $!";
    print F $content;
    close F;
    is(-s $tfile, $clen, "right size test file");
    open (F, $tfile);
    my $remain = $clen;
    while ($remain) {
	my $sent = 0;
        my $rv = sendfile(fileno(F), fileno($sock), 0, $clen, $sent);
        die "got rv = $rv from sendfile" unless $rv >= 0;
        $remain -= $sent;
        die "remain dropped below zero" if $remain < 0;
    }
    close F;

    my $line = <$sock>;
    like($line, qr/^OK/, "child got all data") or diag "Child said: $line";
}

sub child {
    my $listen = IO::Socket::INET->new(Listen    => 5,
                                       LocalAddr => $ip,
                                       LocalPort => $port,
                                       ReuseAddr => 1,
                                       Proto     => 'tcp')
        or die "couldn't start listening";
    while (my $sock = $listen->accept) {
        my $ok = sub {
            my $send = "OK\n";
            syswrite($sock, $send);
            exit 0;
        };
        my $bad = sub {
            my $send = "BAD\n";
            syswrite($sock, $send);
            exit 0;
        };

        my $got;
        my $gotlen;
        while (<$sock>) {
            $got .= $_;
            $gotlen += length($_);
            if ($gotlen == $clen) {
                $ok->() if $got eq $content;
                $bad->();
            }
        }
        $bad->();
    }
}
