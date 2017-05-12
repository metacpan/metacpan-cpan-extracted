#!/usr/bin/perl 
use strict;
use warnings;
use Test::More tests => 4;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";

use Net::SSH::Mechanize;
use MyTest::Mock::ConnectParams;

my $connection = MyTest::Mock::ConnectParams->detect;    

note "using command:";
note "    ", join " ", $connection->ssh_cmd;

my $timeout = 10;
my $ssh = Net::SSH::Mechanize->new(
    connection_params => $connection,
    login_timeout => $timeout,
);

my $session = $ssh->login;

is $session->login_timeout, $timeout, "timeout set ok";

my @exchanges = (
    [q(id),
     qr/uid=\d+\(\S+\) gid=\d+\(\S+\)/],
    [q(printf "stdout output\n" ; printf >&2 "stderr output\n" ),
     qr/\Astdout output\n\z/m], # FIXME what's up here?

    # Using echo -ne instead of printf gets peculiar result: prints "-ne eoled\neoled"
    # Also, mock-sh only supports printf currently.
    [q(printf "eoled\nnot eoled"),
     qr/\Aeoled\nnot eoled\z/m],
);

foreach my $exchange (@exchanges) {
    my ($cmd, $expect) = @$exchange;

    my $data = $session->capture($cmd);

    like $data, $expect, "$cmd: got expected data"
}

$session->logout;


