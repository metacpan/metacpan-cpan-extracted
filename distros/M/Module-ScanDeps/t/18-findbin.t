#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use FindBin; 

BEGIN { use_ok( 'Module::ScanDeps' ); }

my $saved_bin = $FindBin::Bin;

my $deps = scan_deps(files => [ 't/data/use-findbin.pl' ], recurse => 1);
ok($deps->{"Net/FTP.pm"}, q[Net::FTP seen in module found via 'use lib "$FindBin::Bin/..."']);

is($FindBin::Bin, $saved_bin, '$FindBin::Bin unchanged after call to scan_deps()');
