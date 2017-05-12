#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Sub::Current;

my $anon;
$anon = sub {
    is(ROUTINE(), $anon, "anon sub");
};
$anon->();
my $copy = $anon;
$copy->();
