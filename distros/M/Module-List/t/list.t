use warnings;
use strict;

use Test::More tests => 45;

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

sub test_undefs($) {
	my($results) = @_;
	foreach(values %$results) {
		if(defined $_) {
			ok 0;
			return;
		}
	}
	ok 1;
}

sub test_paths($) {
	my($results) = @_;
	foreach(keys %$results) {
		my $is_prefix = /::\z/;
		my $val = $results->{$_};
		unless(ref($val) eq "HASH" &&
				join(",", keys %$val) eq
					($is_prefix ? "prefix_paths" :
						"module_path")) {
			ok 0;
			return;
		}
	}
	ok 1;
}

my $r;

$r = list_modules("", { });
is_deeply $r, {};

$r = list_modules("", { recurse => 1 });
is_deeply $r, {};

$r = list_modules("", { list_modules => 1 });
test_presence($r, 1, 0, 0, 0, 0, 0);
test_undefs($r);

$r = list_modules("", { list_prefixes => 1 });
test_presence($r, 0, 0, 0, 0, 1, 0);
test_undefs($r);

$r = list_modules("", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 1, 0, 0, 0, 1, 0);
test_undefs($r);

$r = list_modules("Module::", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 0, 0, 1, 0, 0, 0);
test_undefs($r);

$r = list_modules("foo::", { list_modules => 1, list_prefixes => 1 });
test_presence($r, 0, 0, 0, 0, 0, 0);
test_undefs($r);

$r = list_modules("Module::",
	{ list_modules => 1, list_prefixes => 1, return_path => 1 });
test_presence($r, 0, 0, 1, 0, 0, 0);
test_paths($r);

1;
