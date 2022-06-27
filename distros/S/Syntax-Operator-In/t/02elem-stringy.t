#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Elem;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# List literals
ok(    "c" elem ("a".."e") , 'c is in a..e');
ok(not("f" elem ("a".."e")), 'f is not in a..e');

# Arrays
my @AtoE = ("A" .. "E");
ok(    "C" elem @AtoE , 'C is in @AtoE');
ok(not("F" elem @AtoE), 'F is not in @AtoE');

# Function calls
sub XtoZ { return "X" .. "Z" }
ok("Y" elem XtoZ(), 'Y is in XtoZ()');

# This is a stringy match
ok(!("1.0" elem (1, 2, 3)), 'match is done stringly, not numerically');

# stack discipline
is_deeply( [ 1, 2, ("+" elem ("+", "-")), 3, 4 ],
   [ 1, 2, 1, 3, 4 ],
   'elem preserves stack' );

ok(!$warnings, 'no warnings');

done_testing;
