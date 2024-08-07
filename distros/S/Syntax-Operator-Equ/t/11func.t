#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Equ qw( is_strequ is_numequ );
use Syntax::Operator::Eqr qw( is_eqr );

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

# stringy
{
   ok( is_strequ( "abc",  "abc" ), 'identical strings');
   ok(!is_strequ( "abc",  "def" ), 'different strings');
   ok( is_strequ( undef,  undef ), 'undef is undef');
   ok(!is_strequ( "abc",  undef ), 'undef is not a string');
   ok(!is_strequ(    "",  undef ), 'undef is not empty string');
}

# numeric
{
   ok( is_numequ(   123,    123 ), 'identical numbers');
   ok(!is_numequ(   123,    456 ), 'different numbers');
   ok( is_numequ( undef,  undef ), 'undef is undef');
   ok(!is_numequ(   123,  undef ), 'undef is not a number');
   ok(!is_numequ(     0,  undef ), 'undef is not zero');
}

# eqr
{
   ok( is_eqr( "abc", "abc" ), 'identical strings');
   ok(!is_eqr( "abc", "def" ), 'different strings');
   ok( is_eqr( "ghi", qr/h/ ),  'string pattern match');
   ok(!is_eqr( "ghi", qr/H/ ), 'string pattern non-match');
}

no Syntax::Operator::Equ qw( is_strequ );

like( dies { is_strequ( "x", "x" ) },
   qr/^Undefined subroutine &main::is_strequ called at /,
   'unimport' );

ok(!$warnings, 'no warnings');

done_testing;
