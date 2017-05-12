#!/usr/bin/perl -w

use strict;
use Test::More tests => 12;

BEGIN {
    use_ok('Proc::BackOff::Random');
}

use constant MIN => 1;
use constant MAX => 5;

my $obj = Proc::BackOff::Random->new( { min => MIN, max => MAX } );
ok( $obj, 'BackOff Object created' );

# we'll have 10 failures in a row

# we set srand to a known value, so its repeatable... I hope.
# well, its better than  sub random ( return 19; }.
srand(5);

my @values;
for ( my $i=1; $i < 11; $i++ ) {
    push @values, int (rand(MAX - MIN) + MIN);
}

srand(5);

for my $value ( @values ) {
    $obj->failure();
    is ($obj->delay(), $value, 'delay ok');
}
