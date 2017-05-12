#!/usr/bin/perl

use strict;
use Test;

BEGIN { plan tests => 1; }

print "# Testing ithreads support\n";

use threads;

my $thr = new threads(\&func);

$thr->join;

sub func {
}

ok(defined($thr));

