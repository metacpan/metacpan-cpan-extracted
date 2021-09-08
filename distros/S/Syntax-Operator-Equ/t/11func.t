#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Equ qw( is_strequ is_numequ );

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

ok(!$warnings, 'no warnings');

done_testing;
