use strict;
use warnings;

my @flags;
if ($] >= 5.038) {
	require XS::Parse::Infix::Builder;
	@flags = XS::Parse::Infix::Builder->extra_compiler_flags;
}

load_module('Dist::Build::XS');
add_xs(extra_compiler_flags => \@flags);
