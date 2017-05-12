#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

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
