#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;

BEGIN {
    use_ok('Proc::BackOff::Linear');
}

use constant SLOPE => 5;
use constant B => 0;

my $obj = Proc::BackOff::Linear->new( { slope => SLOPE, x => 'count', b => B } );
ok( $obj, 'BackOff Object created' );

# we'll have 10 failures in a row

my @values;
for ( my $i=1; $i < 11; $i++ ) {
    push @values, $i*5 + B;
}

for my $value ( @values ) {
    $obj->failure();
    is ($obj->delay(), $value, 'delay ok');
}

# this is here for complete code coverage.

$obj = Proc::BackOff::Linear->new( { slope => 'count', x => 'count', b => 'count' } );
ok( $obj, 'BackOff Object created' );

@values = ();
for ( my $i=1; $i < 11; $i++ ) {
    push @values, $i*$i + $i;
}

for my $value ( @values ) {
    $obj->failure();
    is ($obj->delay(), $value, 'delay ok');
}
