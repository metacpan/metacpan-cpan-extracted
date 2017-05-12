#!/usr/bin/env perl
use strict;
use warnings;
use InlineX::C2XS qw(c2xs);

my ($hdr,$module_name,$pkg_name,$cdummies)= @ARGV;

c2xs($module_name, $pkg_name, ".", {
		SRC_LOCATION => $hdr,
		AUTOWRAP => 1,
		VERSION => 0.01
	}
);
