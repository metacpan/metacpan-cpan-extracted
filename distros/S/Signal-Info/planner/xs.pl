#! perl

use strict;
use warnings;

load_module('Dist::Build::XS');
load_module('Dist::Build::XS::Conf');

my $has_field_template = <<EOF;
#include <signal.h>

int main(int, char**) {
	siginfo_t info;
	info.si_%s = 0;
	return 0;
}
EOF

for my $field (qw/band fd timerid overrun/) {
	my $source = sprintf $has_field_template, $field;
	try_compile_run(source => $source, define => "HAVE_SI_\U$field");
}

add_xs();

