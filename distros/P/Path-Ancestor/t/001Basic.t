######################################################################
# Test suite for Path::Ancestor
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Path::Ancestor qw(longest_common_ancestor);

is( longest_common_ancestor("/foo/bar", "/foo"),
    "/foo",
    "simple"
);

is( longest_common_ancestor("/foo", "/foo/bar"),
    "/foo",
    "simple"
);

is( longest_common_ancestor("/foo/bar", "/foo/bar"),
    "/foo/bar",
    "equal"
);

is( longest_common_ancestor("/foo", "/bar"),
    "/",
    "/foo vs. /bar"
);

is( longest_common_ancestor("/foo2", "/foo1"),
    "/",
    "/foo1 vs. /foo2"
);
is( longest_common_ancestor("/", "/"),
    "/",
    "two root paths"
);

is( longest_common_ancestor("/foo/bar/baz", "/foo/bar/barf"),
    "/foo/bar",
    "differ in subpath"
);

is( longest_common_ancestor("xyz", "abc"),
    "",
    "empty diff"
);

is( longest_common_ancestor("xyz", "abc", "def"),
    "",
    "empty diff"
);

is( longest_common_ancestor("/foo/bar/baz", "/foo/bar/quack", "/foo/bar/moo"),
    "/foo/bar",
    "3x2 match"
);

is( longest_common_ancestor( "foo/bar/baz",
                             "foo/bar/baz/moo",
                             "foo/bar/quack"),
    "foo/bar",
    "POD"
);

is( longest_common_ancestor( "foo/bar/baz",
                             "foo/bar/baz/moo",
                             "foo/bar/baz",
                             "foo/bar/baz",
                           ),
    "foo/bar/baz",
    "four"
);

is( longest_common_ancestor( "foo/bar/",
                             "foo/bar",
                           ),
    "foo/bar",
    "trailing slash"
);

is( longest_common_ancestor( "foo/bar/",
                             "foo/bar/",
                           ),
    "foo/bar",
    "trailing slash"
);

is( longest_common_ancestor( "foo/ba",
                             "foo/bar/",
                           ),
    "foo",
    "trailing slash"
);

is( longest_common_ancestor( "foo/bar/",
                             "foo/ba",
                           ),
    "foo",
    "trailing slash"
);

is( longest_common_ancestor( "foo/bar/",
                             "",
                           ),
    "",
    "one empty"
);

is( longest_common_ancestor( "",
                             "foo/bar/",
                           ),
    "",
    "one empty"
);

is( longest_common_ancestor( "/",
                           ),
    "/",
    "single"
);

is( longest_common_ancestor( "/foo",
                           ),
    "/foo",
    "single"
);

is( longest_common_ancestor("/foo/", "/foo/bar"),
    "/foo",
    "trailing slash"
);

is( longest_common_ancestor("/foo/b", "/foo/bar"),
    "/foo",
    "submatch"
);

is( longest_common_ancestor("/foo/bar", "/foo/"),
    "/foo",
    "trailing slash"
);

is( longest_common_ancestor("/foo/bar", "/foo/b"),
    "/foo",
    "submatch"
);

is( longest_common_ancestor("/foo/bar", "/foo/b", "/foo/bar"),
    "/foo",
    "triple"
);

is( longest_common_ancestor("/foo/bar", "/foo/b", "/"),
    "/",
    "triple"
);

is( longest_common_ancestor("/foo/bar", "/foo/b", "//"),
    "/",
    "double slash"
);

is( longest_common_ancestor("//", "//", "/"),
    "/",
    "double slash"
);

is( longest_common_ancestor("foo", "fob"),
    "",
    "two relatives"
);

is( longest_common_ancestor("foo/m", "foo/ma"),
    "foo",
    "two relatives"
);

is( longest_common_ancestor("foo/ma", "foo/ma/"),
    "foo/ma",
    "two relatives with trailing slash"
);

is( longest_common_ancestor("foo/ma/", "foo/ma/"),
    "foo/ma",
    "two relatives with trailing slash"
);

is( longest_common_ancestor("foo/ma/", "foo/ma"),
    "foo/ma",
    "two relatives with trailing slash"
);

