#!perl

use strict;
use warnings;
use Test::More tests => 8;

use Sub::Current;

our $i = 0;
sub recurse {
    if ($i++ < 4) {
	ok(1, "test i$i");
	ROUTINE->();
    }
}
recurse();

sub recurse2 {
    my $j = shift;
    if ($j > 0) {
	ok(1, "test j$j");
	ROUTINE->($j - 1);
    }
}
recurse2(4);
