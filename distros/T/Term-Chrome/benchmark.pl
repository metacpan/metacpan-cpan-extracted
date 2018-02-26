#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark ':all';

use lib 'lib';
use Term::Chrome;
use Term::ANSIColor qw(colored BOLD RED ON_BLUE RESET YELLOW ON_MAGENTA);

my $s = 'a' x 50;

my %bench = (
    'Chrome normal' => sub {
	join('', Yellow / Magenta, "Yellow on magenta $s", Reset)
    },
    'Chrome CODEREF' => sub {
	&{ Yellow / Magenta }("Yellow on magenta $s")
    },
    'Chrome cached' => do {
	my $yellow_on_magenta = \&{ Yellow / Magenta };
	sub {
	    $yellow_on_magenta->("Yellow on magenta $s")
	}
    },
    'ANSIColor colored' => sub {
	colored(['yellow on_magenta'], "Yellow on magenta $s")
    },
    'ANSIColor constants' => sub {
	join('', YELLOW ON_MAGENTA "Yellow on magenta $s", RESET)
    },
    'ANSIColor autoreset' => sub {
	local $Term::ANSIColor::AUTORESET = 1;
	YELLOW ON_MAGENTA "Yellow on magenta $s"
    },
);

my $Redifier = \&{+Red};
sub dump_bench
{
    for my $name (sort keys %bench) {
	my $result = $bench{$name}->();
	$result =~ s/\e(\[.*?[a-zA-Z])/$Redifier->("\\e$1")/ge;
	printf "%s:\n%s\n", $name, $result
    }
}

dump_bench;

cmpthese(2000000, \%bench);

%bench = (
    'Chrome constants' => sub {
	join('', Red / Blue + Bold, "Bold red on blue.", Reset)
    },
    'Chrome constants in string' => sub {
	"${ Red / Blue + Bold }Bold red on blue.${ +Reset }"
    },
    'Pre-combined chrome constants' => do {
	my $RedBlue = Red / Blue + Bold;

	sub {
	    "${RedBlue}Bold red on blue.${ +Reset }"
	}
    },
    'Pre-stringified chrome constants' => do {
	my $RedBlue = "${ Red / Blue + Bold }";

	sub {
	    "${RedBlue}Bold red on blue.${ +Reset }"
	}
    },
    'ANSIColor constants' => sub {
	join('', RED BOLD ON_BLUE "Bold red on blue.", RESET)
    },
    'ANSIColor color()' => sub {
	join('', Term::ANSIColor::color('bold red on_blue'), "Bold red on blue.", Term::ANSIColor::color('reset'))
    },
);
dump_bench;

cmpthese(2000000, \%bench);

