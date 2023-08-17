#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Equ;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

ok(  123 === 123, 'identical numbers');
ok(!(123 === 456), 'different numbers');
ok(  undef === undef, 'undef is undef');
ok(!(123 === undef), 'undef is not a number');
ok(!(0   === undef), 'undef is not zero');

ok( "1.0" === 1, 'values are compared numerically' );

# overloaded '==' operator
{
   my $equal;
   package Greedy {
      use overload '==' => sub { $equal };
   }

   my $greedy = bless [], "Greedy";

   $equal = 1;
   ok(  $greedy === 123,  'Greedy is 123 when set' );

   $equal = 0;
   ok(!($greedy === 123), 'Greedy is not 123 when unset' );
}

ok(!$warnings, 'no warnings');

done_testing;
