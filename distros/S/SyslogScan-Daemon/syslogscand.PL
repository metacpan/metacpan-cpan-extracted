#!/usr/bin/perl 

use strict;
my $to = "$ARGV[0]";
my $from = "$ARGV[0].pl";

open(FROM, "<$from") || die "open $from: $!";
open(TO, ">$to") || die;
while(<FROM>) {
	print TO unless /II::Develop/;
}
chmod(0755, $to) || die;
