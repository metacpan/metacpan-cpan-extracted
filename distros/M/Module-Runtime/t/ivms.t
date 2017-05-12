use warnings;
use strict;

use Test::More tests => 140;

BEGIN { use_ok "Module::Runtime", qw(
	$top_module_spec_rx $sub_module_spec_rx
	is_module_spec is_valid_module_spec check_module_spec
); }

ok \&is_valid_module_spec == \&is_module_spec;

foreach my $spec (
	undef,
	*STDOUT,
	\"Foo",
	[],
	{},
	sub{},
) {
	ok(!is_module_spec(0, $spec), "non-string is bad (function)");
	eval { check_module_spec(0, $spec) }; isnt $@, "";
	ok(!is_module_spec(1, $spec), "non-string is bad (function)");
	eval { check_module_spec(1, $spec) }; isnt $@, "";
}

foreach my $spec (qw(
	Foo
	foo::bar
	foo::123::x_0
	foo/bar
	foo/123::x_0
	foo::123/x_0
	foo/123/x_0
	/Foo
	/foo/bar
	::foo/bar
)) {
	ok(is_module_spec(0, $spec), "`$spec' is always good (function)");
	eval { check_module_spec(0, $spec) }; is $@, "";
	ok($spec =~ qr/\A$top_module_spec_rx\z/,
		"`$spec' is always good (regexp)");
	ok(is_module_spec(1, $spec), "`$spec' is always good (function)");
	eval { check_module_spec(1, $spec) }; is $@, "";
	ok($spec =~ qr/\A$sub_module_spec_rx\z/,
		"`$spec' is always good (regexp)");
}

foreach my $spec (qw(
	foo'bar
	IO::
	foo::::bar
	/foo/
	/1foo
	::foo::
	::1foo
)) {
	ok(!is_module_spec(0, $spec), "`$spec' is always bad (function)");
	eval { check_module_spec(0, $spec) }; isnt $@, "";
	ok($spec !~ qr/\A$top_module_spec_rx\z/,
		"`$spec' is always bad (regexp)");
	ok(!is_module_spec(1, $spec), "`$spec' is always bad (function)");
	eval { check_module_spec(1, $spec) }; isnt $@, "";
	ok($spec !~ qr/\A$sub_module_spec_rx\z/,
		"`$spec' is always bad (regexp)");
}

foreach my $spec (qw(
	1foo
	0/1
)) {
	ok(!is_module_spec(0, $spec), "`$spec' needs a prefix (function)");
	eval { check_module_spec(0, $spec) }; isnt $@, "";
	ok($spec !~ qr/\A$top_module_spec_rx\z/,
		"`$spec' needs a prefix (regexp)");
	ok(is_module_spec(1, $spec), "`$spec' needs a prefix (function)");
	eval { check_module_spec(1, $spec) }; is $@, "";
	ok($spec =~ qr/\A$sub_module_spec_rx\z/,
		"`$spec' needs a prefix (regexp)");
}

1;
