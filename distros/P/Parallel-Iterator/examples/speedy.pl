#!/usr/bin/perl

use strict;
use warnings;
use Inline 'C';
use Parallel::Iterator qw( iterate_as_array );

# Demonstrates a simple way to run multiple instances of a C function in
# parallel. You'll need it to be a fairly time consuming function
# otherwise the overhead of forking and marshalling arguments will
# overwhelm the execution time.

my @ar = qw( This Pork Bubble );
@ar = ( @ar, @ar ) for 1 .. 5;
my @got = iterate_as_array( sub { calc( $_[1] ) }, \@ar );
print join( ', ', @got ), "\n";

__END__    
__C__
int calc(char *str) {
    int sum = 0;
    int c;
    while (c = *str++) {
        sum = sum << 3 | c;
    }
    return sum;
}
