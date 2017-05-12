#!/usr/bin/perl -w

for (qw|readonly|) {

use strict;

use Test::More tests => 6;
use Scriptalicious;

(my $path = $INC{"Scriptalicious.pm"}) =~ s{/[^/]*$}{};

my $output = join "", capture($^X, "-Mlib=$path", "t/pu.pl");
like($output, qr/^pu: the rc.*\d+$/, "pu.pl runs");

$output = join "", capture($^X, "-Mlib=$path", "t/pu.pl", "-v");
like($output, qr/^doing something with \./m, "pu.pl runs");
like($output, qr/^pu: running `echo/m, "pu.pl runs");

my ($rc, @output)
    = capture_err($^X, "-Mlib=$path", "t/pu.pl", "-a");
$output = join "", @output;
like($output, qr/^pu: aborting:/m, "spots invalid arguments");
like($output, qr/^Try `(pu --help|perldoc.*)'/m,
     "suggests where to find help");

($rc, @output)
    = capture_err($^X, "-Mlib=$path", "t/pu.pl", "--version");
$output = join "", @output;
like($output, qr/^This is pu, version 1.00/m, "spots invalid arguments");

}
