#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::ExistsOr;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my %hash = ( k1 => "value", k2 => undef );

# Basic operation
{
   is( $hash{k1} \\ "not", "value", 'logical existsor on defined key' );
   is( $hash{k2} \\ "not", undef,   'logical existsor on present-but-undef key' );
   is( $hash{k3} \\ "not", "not",   'logical existsor on missing key' );

   is( ($hash{k1} existsor "not"), "value", 'low existsor on defined key' );
   is( ($hash{k2} existsor "not"), undef,   'low existsor on present-but-undef key' );
   is( ($hash{k3} existsor "not"), "not",   'low existsor on missing key' );
}

# Short-circuiting
{
   my %rhs_eval;
   $hash{k1} \\ $rhs_eval{k1}++;
   $hash{k2} \\ $rhs_eval{k2}++;
   $hash{k3} \\ $rhs_eval{k3}++;

   is( \%rhs_eval, { k3 => 1 }, 'existsor short-circuits its RHS' );
}

# Stack discipline
{
   is( [ "before", $hash{k1} \\ "not", "after" ], [ "before", "value", "after" ],
      'logical existsor exists in stack' );
   is( [ "before", $hash{k3} \\ "not", "after" ], [ "before", "not", "after" ],
      'logical existsor missing in stack' );
}

# unimport
{
   no Syntax::Operator::ExistsOr;

   # \\ isn't usable as a symbol name but we can hack something up
   my $rref = \\"key";

   ok( ref($rref) && ref($$rref), '\\\\ parses as double-refgen' );
}

done_testing;
