#!/usr/bin/perl

use v5.14;
use utf8;
use warnings;

use Test2::V0;

use Syntax::Operator::Identical qw( is_identical is_not_identical );

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# Avoid using builtin:: as this should still work pre-5.36
my $true  = (1==1);
my $false = !$true;

my $arr = [];
my $hash = {};

# Pairs that should be identical
{
   ok(is_identical(undef, undef), 'undef is undef');

   ok(is_identical($true, $true),   'true is true');
   ok(is_identical($false, $false), 'false is false');

   ok(is_identical($arr, $arr),   '$arr is $arr');

   ok(is_identical(123, 123),     '123 is 123');
   ok(is_identical("abc", "abc"), '"abc" is "abc"');

   ok(is_identical(10, "10"), '10 is "10"');
}

# Pairs that should differ
{
   ok(is_not_identical(undef, $false), 'undef isnot false');
   ok(is_not_identical(undef, 0),      'undef isnot 0');
   ok(is_not_identical(undef, ""),     'undef isnot ""');

   ok(is_not_identical($arr, $hash),  '$arr isnot $hash');

   ok(is_not_identical($arr, 0+$arr), '$arr isnot refaddr($arr)');

   ok(is_not_identical(123, 456), '123 isnot 456');
   ok(is_not_identical("abc", "def"), '"abc" is "def"');

   ok(is_not_identical(10, "10.0"), '10 isnot "10.0"');
}

SKIP: {
   skip "Booleans are not distinguishable on this version of Perl", 3 unless $] >= 5.036;

   ok(is_not_identical($false, ""), 'false isnot empty');
   ok(is_not_identical($false, 0), 'false isnot zero');

   ok(is_not_identical($true, 1), 'true isnot one');
}

no Syntax::Operator::Identical qw( is_identical );

like( dies { is_identical("x", "x") },
   qr/^Undefined subroutine &main::is_identical called at /,
   'unimport' );

ok(!$warnings, 'no warnings');

done_testing;
