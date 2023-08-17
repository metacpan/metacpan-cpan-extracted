#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Eqr;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

ok(  "abc" eqr "abc", 'identical strings');
ok(!("abc" eqr "def"), 'different strings');
ok(  undef eqr undef, 'undef is undef');
ok(!("abc" eqr undef), 'undef is not a string');
ok(!(""    eqr undef), 'undef is not empty string');

ok(  "ghi" eqr qr/h/,  'string pattern match');
ok(!("ghi" eqr qr/H/), 'string pattern non-match');

my $pat = qr/i/;
ok(  "ghi" eqr $pat, 'string pattern match from variable');

# overloaded 'eq' operator
{
   my $equal;
   package Greedy {
      use overload 'eq' => sub { $equal };
   }

   my $greedy = bless [], "Greedy";

   $equal = 1;
   ok(  $greedy eqr "abc",  'Greedy is abc when set' );

   $equal = 0;
   ok(!($greedy eqr "abc"), 'Greedy is not abc when unset' );
}

ok(!$warnings, 'no warnings');

done_testing;
