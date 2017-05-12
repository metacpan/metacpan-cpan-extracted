#!perl -T

# this file was copied from POE::Session::AttributeBased distribution v0.03
# all occurances of 'AttributeBased' in this file were changed to 'Attribute'

use strict;
use warnings;
use Test::More 'no_plan' ;

use POE;
use POE::Session::Attribute;
use base 'POE::Session::Attribute';

POE::Session::Attribute->create(
    heap => { this => 1, in => 'the', 'heap' => 2 },
);

sub _start : state {
    my ( $h, $k, $s, @arg ) = @_[HEAP, KERNEL, SESSION, ARG0 .. $#_ ];
    my $x;

    is ($h->{this}, 1,   "hash passed1");
    is ($h->{in}, 'the', "hash passed2");
    is ($h->{heap}, 2,   "hash passed3");
}

POE::Kernel->run();
