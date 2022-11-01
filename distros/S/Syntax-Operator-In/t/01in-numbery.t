#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::In;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# List literals
ok(    3 in<==> (1..5) , '3 is in 1..5');
ok(not(6 in<==> (1..5)), '6 is not in 1..5');

# Arrays
my @AtoE = (10 .. 15);
ok(    13 in<==> @AtoE , '13 is in @AtoE');
ok(not(16 in<==> @AtoE), '16 is not in @AtoE');

# Function calls
sub hundred { return 100 .. 105 }
ok(102 in<==> hundred(), '102 is in hundred()');

# This is a numeric match
ok("1.0" in<==> ("1", "2"), 'match is done numerically');

ok(!$warnings, 'no warnings');

done_testing;
