#!perl -T
# vim: filetype=perl

# this file was copied from POE::Session::AttributeBased distribution v0.03
# all occurances of 'AttributeBased' in this file were changed to 'Attribute'

use strict;
use warnings;
use Test::More 'no_plan' ;

use POE;
use base 'POE::Session::Attribute';

POE::Session::Attribute->create(
    args => [qw(this came from attributes)]
);

sub _start : state {
    my ( $h, $k, $s, @arg ) = @_[HEAP, KERNEL, SESSION, ARG0 .. $#_ ];

    not_a_state(@arg);

    ok(1, '_start');

    $k->yield('do_count', 0..9);
}

sub do_count : state {
    my ( $h, $k, $s, @arg ) = @_[ HEAP, KERNEL, SESSION, ARG0 .. $#_ ];
    
    ok(1, 'do_count');
    for ( @arg ){
	$k->post($s, 'job', $_);
    }
}

sub job : state {
    my ( $h, $k, $s, $id ) = @_[ HEAP, KERNEL, SESSION, ARG0 ];

    ok(1, 'job');
}

sub not_a_state {
    for (@_) {
	ok(1, "not_a_state \$_ = $_");
    }
}

sub _default : state {
    ok( 1, "_default");
}

POE::Kernel->run();
