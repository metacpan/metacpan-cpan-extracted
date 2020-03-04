#!perl
use strict;
use warnings;

use Test2::V0;
use File::Which;

my $sh = which 'sh';

# no shell - no service.
if ($sh) {
	pass('found sh');
} else {
	bail_out('OS unsupported') unless $sh;
}

done_testing;
