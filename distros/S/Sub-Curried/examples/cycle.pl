#!/usr/bin/perl
use strict; use warnings;
use Sub::Curried;

=head1 Cycle Example

This is documented in detail at L<http://greenokapi.net/blog/2008/07/27/102550-sequence-fun/>

Debolaz asked a question in #moose, how to get:

 a list of numbers like 10,25,50,100,250,500,1000,etc without tracking any
 other state than the number itself

=cut

use feature 'say'; # Perl >= 5.10
# use Perl6::Say;  # Perl <  5.10

# We want to be able to declare an infinite list of repeated values, for example
# (1,2,3,1,2,3,1,2,3) or in this case a list of functions (x2.5, x2, x2, ...)
curry cycle (@list) {
    my @curr = @list;
    return sub {
        @curr = @list unless @curr;
        return shift @curr;
        };
}

# Or use Sub::Section's  op(*)
curry times ($x,$y) { $x * $y }

# like a fold, but returning intermediate values
curry scanl ($fn, $start, $it) {
    my $curr = $start;
    return sub {
        my $ret = $curr;
        $curr = $fn->($curr, $it->());
        return $ret;
    };
}

# convert an infinite list into a perl array
curry take ($count, $it) {
    return map { $it->() } 1..$count;
}

# and finally.. the example in its glory!
say for take 12 => 
    (scanl times)->(
            10,
            cycle [2.5, 2, 2] 
       );
