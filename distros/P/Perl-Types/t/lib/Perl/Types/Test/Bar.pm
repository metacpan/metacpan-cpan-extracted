package Perl::Types::Test::Bar;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

sub empty_sub {
    { my void $RETURN_TYPE };
    print 'I am empty.' . "\n";
    return;
}

1;  # end of package
