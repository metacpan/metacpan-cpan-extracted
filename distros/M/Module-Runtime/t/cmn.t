use warnings;
use strict;

use Test::More tests => 17;

BEGIN { use_ok "Module::Runtime", qw(compose_module_name); }

is(compose_module_name(undef, "foo"), "foo");
is(compose_module_name(undef, "foo::bar"), "foo::bar");
is(compose_module_name(undef, "foo/bar"), "foo::bar");
is(compose_module_name(undef, "foo/bar/baz"), "foo::bar::baz");
is(compose_module_name(undef, "/foo"), "foo");
is(compose_module_name(undef, "/foo::bar"), "foo::bar");
is(compose_module_name(undef, "::foo/bar"), "foo::bar");
is(compose_module_name(undef, "::foo/bar/baz"), "foo::bar::baz");
is(compose_module_name("a::b", "foo"), "a::b::foo");
is(compose_module_name("a::b", "foo::bar"), "a::b::foo::bar");
is(compose_module_name("a::b", "foo/bar"), "a::b::foo::bar");
is(compose_module_name("a::b", "foo/bar/baz"), "a::b::foo::bar::baz");
is(compose_module_name("a::b", "/foo"), "foo");
is(compose_module_name("a::b", "/foo::bar"), "foo::bar");
is(compose_module_name("a::b", "::foo/bar"), "foo::bar");
is(compose_module_name("a::b", "::foo/bar/baz"), "foo::bar::baz");

1;
