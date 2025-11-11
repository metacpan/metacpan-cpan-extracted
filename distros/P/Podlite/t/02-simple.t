#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

# Test 1: Module loads
require_ok('Podlite');

# Test 2: Simple filtering works
my $test_file = 't/simple_test.pl';
open my $fh, '>', $test_file or die "Cannot create $test_file: $!";
print $fh <<'END_SCRIPT';
use strict;
use warnings;
use lib "lib";
use Podlite;

my $x = 1;

=head1 TEST

my $y = 2;
print "x=$x y=$y\n";
END_SCRIPT
close $fh;

my $output = `$^X $test_file 2>&1`;
ok($output =~ /x=1 y=2/, 'Simple filter works')
    or diag("Output: $output");

unlink $test_file;
done_testing();
