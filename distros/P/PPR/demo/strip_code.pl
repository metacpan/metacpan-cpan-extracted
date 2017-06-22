#! /usr/bin/env perl

use 5.010;
use warnings;

# Load the grammar
use PPR;

# For each specified file...
for my $filename (@ARGV) {
    # Report...
    say
        # ...meaningful...
        grep {defined}
            # ...contents...
            slurp($filename)
                # ...that match whitespace...
                =~ m{ ((?&PerlNWS)) $PPR::GRAMMAR }gx;
}



sub slurp {
    use IO::File;
    local $/;
    readline IO::File->new(shift, 'r');
}
