#!/usr/bin/perl

use warnings;
use strict;

open(my $html, '<', 'Programming_Guide_A5013_RevEs.html') || die "run pdftohtml: $!";

sub strip_html {
	my $t = shift;
	$t =~ s{&nbsp;}{ }gs;
	$t =~ s{(<br>|\n)+}{}gs;
	$t =~ s{\s+$}{}gs;
	$t =~ s{\s*;\s*}{;}gs;
	return $t;
}

while(<$html>) {
	next if m{^(&nbsp)?Page \d+};
	if ( m{<b>(\w+)&nbsp;</b><br>} ) {
		my $command = $1;
		my $param = <$html>;
		next if $param =~ m{Page #};
		my $description = <$html>;
		printf "%-4s %-15s %s\n", $command, strip_html($param), strip_html($description);
	}
}

