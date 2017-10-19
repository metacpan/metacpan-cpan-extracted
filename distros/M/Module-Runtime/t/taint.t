#!perl -T
# above line is required to enable taint mode

use warnings;
use strict;

BEGIN {
	if(eval { eval("1".substr($^X,0,0)) }) {
		require Test::More;
		Test::More::plan(skip_all =>
			"tainting not supported on this Perl");
	}
}

use Test::More tests => 5;

BEGIN {
	use_ok "Module::Runtime",
		qw(require_module use_module use_package_optimistically);
}

unshift @INC, "./t/lib";
my $tainted_modname = substr($^X, 0, 0) . "t::Simple";
eval { require_module($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { use_module($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { use_package_optimistically($tainted_modname) };
like $@, qr/\AInsecure dependency /;
eval { require_module("Module::Runtime") };
is $@, "";

1;
