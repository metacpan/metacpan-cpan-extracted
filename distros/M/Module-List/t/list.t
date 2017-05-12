use warnings;
use strict;

use Test::More tests => 43;

BEGIN { use_ok "Module::List", qw(list_modules); }

my @test_names = qw(
	warnings Module Module::List Module::that::does::not::exist
	Module:: prefix_that_does_not_exist::
);

sub test_presence($@) {
	my $results = shift;
	foreach my $test_name (@test_names) {
		is(!!exists($results->{$test_name}), !!shift);
	}
}

my $r;

$r = list_modules("", { });
test_presence($r, 0, 0, 0, 0, 0, 0);

$r = list_modules("", { recurse => 1 });
test_presence($r, 0, 0, 0, 0, 0, 0);

$r = list_modules("", { list_modules => 1 });
test_presence($r, 1, 0, 0, 0, 0, 0);

$r = list_modules("", { list_prefixes => 1 });
test_presence($r, 0, 0, 0, 0, 1, 0);

$r = list_modules("", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 1, 0, 0, 0, 1, 0);

$r = list_modules("Module::", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 0, 0, 1, 0, 0, 0);

$r = list_modules("foo::", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 0, 0, 0, 0, 0, 0);

1;
