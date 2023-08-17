#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Equ qw( is_strequ is_numequ );

use B::Deparse;
my $deparser = B::Deparse->new();

sub is_deparsed
{
   my ( $sub, $exp, $name ) = @_;

   my $got = $deparser->coderef2text( $sub );

   # Deparsed output is '{ ... }'-wrapped
   $got = ( $got =~ m/^{\n(.*)\n}$/s )[0];

   # Deparsed output will have a lot of pragmata and so on; just grab the
   # final line
   $got = ( split m/\n/, $got )[-1];
   $got =~ s/^\s+//;

   is( $got, $exp, $name );
}

is_deparsed
   sub { is_strequ $_[0], $_[1] },
   'Syntax::Operator::Equ::is_strequ($_[0], $_[1]);',
   'is_streq';

if( XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN ) {
   use Syntax::Operator::Equ;

   is_deparsed
      eval('sub { $_[0] equ $_[1] }'),
      '$_[0] equ $_[1];',
      'infix equ operator';
}

done_testing;
