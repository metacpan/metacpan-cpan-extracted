package Perl::Types::Test::Bar;
use strict;
use warnings;
our $VERSION = 0.001_000;
use types;

## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

sub empty_sub {
    { my void $RETURN_TYPE };
    print 'I am empty.' . "\n";
    return;
}

1;  # end of package
