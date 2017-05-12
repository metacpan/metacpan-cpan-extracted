#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark ':all';

use lib 'lib';
use Term::Chrome;
use Term::ANSIColor qw(colored BOLD RED ON_BLUE RESET);

my $s = 'a' x 50;

my %bench = (
    'Chrome normal' => sub {
	&{ Yellow / Magenta }("Yellow on magenta $s")
    },
    'Chrome cached' => do {
	my $yellow_on_magenta = \&{ Yellow / Magenta };
	sub {
	    $yellow_on_magenta->("Yellow on magenta $s")
	}
    },
    'ANSIColor' => sub {
	colored(['yellow on_magenta'], "Yellow on magenta $s")
    },
);

print $_->(), "\n" for values %bench;
cmpthese(5000000, \%bench);

%bench = (
    'Chrome constants' => sub {
	join('', Red / Blue + Bold, "Bold red on blue.", Reset)
    },
    'ANSIColor constants' => sub {
	join('', RED BOLD ON_BLUE "Bold red on blue.", RESET)
    },
);
print $_->(), "\n" for values %bench;
cmpthese(5000000, \%bench);

