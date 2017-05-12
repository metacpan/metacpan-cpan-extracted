#!/usr/bin/perl

use strict;
use warnings;

use POSIX ();

my @format = qw( a A b B c C d D e Ec EC Ex EX EY Ey F G g h H I j k l m M n Od Oe OH OI Om OM OS Ou OU OV Ow Oy p P r R s S t T u U V w W x X y Y z Z );

my @t = localtime;

my $date = shift @ARGV || POSIX::strftime '%H:%M:%S', gmtime;
my $modifier = shift @ARGV || '';

foreach my $f (@format) {
    my $result = `TZ=GMT LC_TIME=C date "+%$modifier$f" -d "$date"`;
    chomp $result;
    my $len = 4 + length $modifier;
    printf "%-${len}s => '%s',\n", $modifier ? "'$modifier$f'" : $f, $result;
};
