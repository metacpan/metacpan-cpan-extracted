#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
