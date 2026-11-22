#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

# Test 1: Module loads
require_ok('Podlite');

# Test 2: Simple filtering works
my $run = run_perl(<<'END_SCRIPT');
use strict;
use warnings;
use Podlite;

my $x = 1;

=head1 TEST

my $y = 2;
print "x=$x y=$y\n";
END_SCRIPT

my $output = $run->{stdout} . $run->{stderr};
ok($output =~ /x=1 y=2/, 'Simple filter works')
    or diag("Output: $output");

done_testing();
