#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use POE;
use POE::Session::Multiplex;

sub DEBUG () { 0 }

eval "require POE::Session::PlainCall";
if( $@ ) {
    plan skip_all => "POE::Session::PlainCall isn't available";
    exit 0
}

require t::One;



plan tests => 37;
my @list = t::One->spawn;
t::Two->spawn( @list );

$poe_kernel->run;
 