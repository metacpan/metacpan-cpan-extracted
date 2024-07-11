#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Is;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use Data::Checks qw( Num );

use B qw( svref_2object walkoptree );

sub count_ops
{
   my ( $code ) = @_;
   my %opcounts;

   # B::walkoptree() is stupid
   #   https://github.com/Perl/perl5/issues/19101
   no warnings 'once';
   local *B::OP::collect_opnames = sub {
      my ( $op ) = @_;
      $opcounts{ $op->name }++ unless $op->name eq "null";
   };
   walkoptree( svref_2object( $code )->ROOT, "collect_opnames" );

   return %opcounts;
}

my %opcounts;

# Const-folded op should use OP_STATIC_IS and no OP_ENTERSUB
%opcounts = count_ops sub { $_[0] is Num };
ok( $opcounts{static_is}, 'LHS is Num uses OP_STATIC_IS' );

# Non-constfolded op should appear like a regular OP_PADSV + OP_INFIX_IS_...
my $constraint_Num = Num;
%opcounts = count_ops sub { $_[0] is $constraint_Num };
# We can't predict what the addr will be
$opcounts{$_ =~ s/_0x[[:xdigit:]]+$/_ADDR/r} = delete $opcounts{$_}
   for grep { m/_0x[[:xdigit:]]+$/ } keys %opcounts;

ok( $opcounts{infix_Syntax__Operator__Is__is_ADDR}, 'LHS is $padsv uses OP_IS (dynamic)' );
ok( $opcounts{padsv}, 'LHS is $padsv uses OP_PADSV' );

done_testing;
