# This example shows how to add memoization to functions using a
# decorator.

use strict;
use warnings;
use lib "../lib";
use Python::Decorator;

# memoize() implements a decorator: it takes a code reference and
# returns a code reference.
sub memoize_scalar {
    my $f = shift;
    my %results;
    my $memoized_f = sub {
	my $key = join(":",@_);
	if (exists $results{$key}) {
	    print "returning cached value for [$key]\n";
	    return $results{$key};
	}
	
	print "caching result for [$key]\n";
	$results{$key} = &$f(@_);
	return $results{$key};
    };
    return $memoized_f;
}

@memoize_scalar
sub incr {
    return $_[0]+1;
}

print "incr(1)= ".incr(1)." (calculated)\n";
print "incr(1)= ".incr(1)." (memoized)\n";
print "incr(2)= ".incr(2)." (calculated)\n";
