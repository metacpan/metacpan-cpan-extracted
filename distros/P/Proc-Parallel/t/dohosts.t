#!/usr/bin/perl;

use strict;
use warnings;
use FindBin;
use Test::More;
use File::Temp;
use File::Slurp;

BEGIN { unshift(@INC, "$FindBin::Bin/../lib") unless $ENV{HARNESS_ACTIVE}; }
	
my $finished = 0;
my $skip = 0;

END { ok($finished, 'finished') unless $skip }

use File::Slurp::Remote;

my $rhost = `$File::Slurp::Remote::SmartOpen::ssh localhost -n hostname`;
my $lhost = `hostname`;

unless ($lhost eq $rhost) {
	$skip = 1;
	plan skip_all => 'Cannot ssh to localhost';
	exit;
}

import Test::More qw(no_plan);

my $command = $ENV{HARNESS_ACTIVE} 
	? "$FindBin::Bin/../blib/script/do.hosts" 
	: "perl -I$FindBin::Bin/../lib $FindBin::Bin/../bin/do.hosts";

# diag "$command $FindBin::Bin/data/testcluster hostname";
my $out = `$command $FindBin::Bin/data/testcluster hostname`;

is($out, "localhost:\t$lhost");

$finished = 1;

