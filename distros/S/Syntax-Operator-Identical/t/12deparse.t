#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Identical qw( is_identical is_not_identical );

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
   sub { is_identical $_[0], $_[1] },
   'Syntax::Operator::Identical::is_identical($_[0], $_[1]);',
   'is_identical';

is_deparsed
   sub { is_not_identical $_[0], $_[1] },
   'Syntax::Operator::Identical::is_not_identical($_[0], $_[1]);',
   'is_not_identical';

if( XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN ) {
   use Syntax::Operator::Identical;

   is_deparsed
      eval('sub { $_[0] =:= $_[1] }'),
      '$_[0] =:= $_[1];',
      'infix =:= operator';

   is_deparsed
      eval('sub { $_[0] !:= $_[1] }'),
      '$_[0] !:= $_[1];',
      'infix !:= operator';
}

done_testing;
