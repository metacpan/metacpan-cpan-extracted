#!/usr/bin/perl

use strict;
use warnings;

use POSIX ();

my @format = qw( a A b B c C d D e Ec EC Ex EX EY Ey F G g h H I j k l m M n Od Oe OH OI Om OM OS Ou OU OV Ow Oy p P r R s S t T u U V w W x X y Y z Z );

my @t = localtime;

my $modifier = defined $ARGV[0] ? $ARGV[0] : '';

foreach my $f (@format) {
    printf "%-2s => '%s',\n", $f, POSIX::strftime("%$modifier$f", @t);
};
