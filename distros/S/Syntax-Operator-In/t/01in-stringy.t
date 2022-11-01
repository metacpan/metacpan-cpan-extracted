#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::In;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# List literals
ok(    "c" in<eq> ("a".."e") , 'c is in a..e');
ok(not("f" in<eq> ("a".."e")), 'f is not in a..e');

# Arrays
my @AtoE = ("A" .. "E");
ok(    "C" in<eq> @AtoE , 'C is in @AtoE');
ok(not("F" in<eq> @AtoE), 'F is not in @AtoE');

# Function calls
sub XtoZ { return "X" .. "Z" }
ok("Y" in<eq> XtoZ(), 'Y is in XtoZ()');

# This is a stringy match

ok(!$warnings, 'no warnings');

done_testing;
