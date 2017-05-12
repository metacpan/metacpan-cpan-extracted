#!/usr/bin/perl 
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";
use Coro;

use Net::SSH::Mechanize;
use MyTest::Mock::ConnectParams;

my $threads = 10;
my $timeout = 10;

my @exchanges = (
    [q(id),
     qr/uid=\d+\(\S+\) gid=\d+\(\S+\)/],
    [q(printf "stdout output\n" ; printf >&2 "stderr output\n" ),
     qr/\Astdout output\n\z/m], # FIXME what's up here?
    [q(printf "eoled\nnot eoled"),
     qr/\Aeoled\nnot eoled\z/sm],
);

plan tests => @exchanges * $threads + 2;

my (@ssh) = map { 
    Net::SSH::Mechanize->new(
        connection_params => MyTest::Mock::ConnectParams->detect,
        login_timeout => $timeout,
    );
} 1..$threads;

is @ssh, $threads, "number of subprocesses is $threads";

my @threads;
my $ix = 0;
foreach my $ix (1..@ssh) {
    push @threads, async {
        my $id = $ix;
        my $ssh = $ssh[$id-1];
        note "(thread=$ix) starting";

        eval {
            my $session = $ssh->login;
            note "(thread=$ix) logged in";  

            foreach my $exchange (@exchanges) {
                my ($cmd, $expect) = @$exchange;
                
                my $data = $session->capture($cmd);
                
                like $data, $expect, "(thread=$ix) $cmd: got expected data";
            }
            
            $session->logout;
            note "(thread=$ix) logged out";           
            1;
        } or do {
            note "(thread=$ix) error: $@";
        };
        note "(thread=$ix) ending";
     };
}

is @threads, $threads, "number of threads is $threads";
my $id = 0;
foreach my $thread (@threads) {
    note "joining thread ",++$id;
    $thread->join;
}
        
