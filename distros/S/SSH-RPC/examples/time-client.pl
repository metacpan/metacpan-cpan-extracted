#!/usr/bin/perl

use strict;
use SSH::RPC::Client;
use Getopt::Long;

my ($user, $host, $pass, $hires);

GetOptions  (
    "user=s"    => \$user,
    "pass=s"    => \$pass,
    "host=s"    => \$host,
    "hires"     => \$hires,
    );


if ($user eq "" || $host eq "") {
    print <<STOP;

    $0 --user=joe --host=server.example.com --pass=abc123

    --user      The username to connect with.

    --host      The hostname to connect to.

    --pass      The password of the user you're connecting with. Optional
                if you have an ssh key installed.

    --hires     Return miliseconds rather than just seconds.

STOP
    exit;
}


my $ssh = SSH::RPC::Client->new($host, $user, $pass);
my $command = ($hires) ? "hiResTime" : "time";
my $result = $ssh->run($command);
if ($result->isSuccess) {
    if ($hires) {
        printf "%02d:%02d:%02d.%d\n", @{$result->getResponse};
    }
    else {
        print $result->getResponse."\n";
    }
}
else {
    die $result->getError;
} 


