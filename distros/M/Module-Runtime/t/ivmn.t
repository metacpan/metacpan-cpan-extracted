use warnings;
use strict;

use Test::More tests => 47;

BEGIN { use_ok "Module::Runtime", qw(
	$module_name_rx is_module_name is_valid_module_name check_module_name
); }

ok \&is_valid_module_name == \&is_module_name;

foreach my $name (
	undef,
	*STDOUT,
	\"Foo",
	[],
	{},
	sub{},
) {
	ok(!is_module_name($name), "non-string is bad (function)");
	eval { check_module_name($name) }; isnt $@, "";
}

foreach my $name (qw(
	Foo
	foo::bar
	IO::File
	foo::123::x_0
	_
)) {
	ok(is_module_name($name), "`$name' is good (function)");
	eval { check_module_name($name) }; is $@, "";
	ok($name =~ /\A$module_name_rx\z/, "`$name' is good (regexp)");
}

foreach my $name (qw(
	foo'bar
	foo/bar
	IO::
	1foo::bar
	::foo
	foo::::bar
)) {
	ok(!is_module_name($name), "`$name' is bad (function)");
	eval { check_module_name($name) }; isnt $@, "";
	ok($name !~ /\A$module_name_rx\z/, "`$name' is bad (regexp)");
}

1;
