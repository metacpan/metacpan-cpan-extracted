#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Equ;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my $warnings = 0;
$SIG{__WARN__} = sub { $warnings++ };

{
   ok( !defined $1, '$1 not yet set' );
   "abc" =~ m/(\w+)/;
   ok( $1 equ "abc", '$1 is now abc' );
}

done_testing;
