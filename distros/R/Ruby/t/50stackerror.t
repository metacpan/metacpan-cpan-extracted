#!perl

use strict;
use Ruby 'Integer';

print "1..100\n";
for my $i(1 .. 100){
	my $x = eval{ Integer($i)->to_s->to_perl };
	print $x == $i ? "ok $i\n" : "not ok $i\n";
	if($@){
		$@ =~ s/^/#/g;
		print $@;
	}
}
