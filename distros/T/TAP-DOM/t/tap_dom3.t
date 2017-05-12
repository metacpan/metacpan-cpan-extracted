#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap3.txt") or die "Cannot read t/some_tap3.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::DOM->new( tap => $tap );
#diag Dumper($tapdata);

ok(1, "no more error 'Modification of non-creatable array value attempted, subscript -1'");
