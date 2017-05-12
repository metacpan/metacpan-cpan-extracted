#!/usr/bin/perl -w 

use strict;
use Test::More tests => 1;
push @INC, "./lib";
eval "use Pod::Coverage";

SKIP: {
	skip "Pod::Coverage required for documentation check",1 if($@);

	my $pc = Pod::Coverage->new(package => "Parse::DebControl");
	ok($pc->coverage == 1, "Pod::Coverage documentation overview is ok");
}
