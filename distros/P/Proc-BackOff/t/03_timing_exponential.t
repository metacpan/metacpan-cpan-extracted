#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;

BEGIN {
    use_ok('Proc::BackOff::Exponential');
}

use constant EXPONENT => 2;
use constant BASE => 'count';

my $obj = Proc::BackOff::Exponential->new( { exponent => EXPONENT, base => BASE } );
ok( $obj, 'BackOff Object created' );

# we'll have 10 failures in a row

my @values;
for ( my $i=1; $i < 11; $i++ ) {
    push @values, $i ^ EXPONENT;
}

for my $value ( @values ) {
    $obj->failure();
    is ($obj->delay(), $value, 'delay ok');
}

# Test all the code (code coverage)

$obj = Proc::BackOff::Exponential->new( { exponent => 'count', base => 'count' } );
ok( $obj, 'BackOff Object created' );

@values = ();
for ( my $i=1; $i < 11; $i++ ) {
    push @values, $i ^ $i;
}

for my $value ( @values ) {
    $obj->failure();
    is ($obj->delay(), $value, 'delay ok');
}
