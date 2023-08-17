#!/usr/bin/perl

use v5.14;
use utf8;
use warnings;

use Test2::V0;

use Syntax::Operator::Identical;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# Avoid using builtin:: as this should still work pre-5.36
my $true  = (1==1);
my $false = !$true;

my $arr = [];
my $hash = {};

# Pairs that should be identical
{
   # undef
   ok(undef ≡ undef, 'undef is undef');

   # bools
   ok($true ≡ $true,   'true is true');
   ok($false ≡ $false, 'false is false');

   # references
   ok($arr ≡ $arr,   '$arr is $arr');

   # nonreferences
   ok(123 ≡ 123,     '123 is 123');
   ok("abc" ≡ "abc", '"abc" is "abc"');

   # mixed nonreferences
   ok(10 ≡ "10", '10 is "10"');
}

# Pairs that should differ
{
   # nothing else is identical to undef
   ok(undef ≢ $false, 'undef isnot false');
   ok(undef ≢ 0,      'undef isnot 0');
   ok(undef ≢ "",     'undef isnot ""');

   # references to different things are not identical
   ok($arr ≢ $hash,  '$arr isnot $hash');

   # references are not even identical to their referrant's refaddr as a number
   ok($arr ≢ 0+$arr, '$arr isnot refaddr($arr)');

   # nonreferences compare as per both numbers and strings
   ok(123 ≢ 456, '123 isnot 456');
   ok("abc" ≢ "def", '"abc" is "def"');

   ok(10 ≢ "10.0", '10 isnot "10.0"');
}

SKIP: {
   skip "Booleans are not distinguishable on this version of Perl", 3 unless $] >= 5.036;

   ok($false ≢ "", 'false isnot empty');
   ok($false ≢ 0, 'false isnot zero');

   ok($true ≢ 1, 'true isnot one');
}

# ASCII-safe transliteration
{
   ok(undef =:= undef, 'undef is undef by ASCII');
   ok(undef !:= 0,     'undef isnot 0 by ASCII');
}

ok(!$warnings, 'no warnings');

done_testing;
