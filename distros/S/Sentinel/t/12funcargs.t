#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Sentinel;

my $var;
sub inner :lvalue
{
   sentinel set => sub { $var = shift };
}

sub test1
{
   $_[0] = "one";
}
test1 inner;
is( $var, "one", 'sentinel() as lvalue parameter to sub' );

done_testing;
