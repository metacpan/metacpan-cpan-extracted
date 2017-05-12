#!perl -T

use Test::More;
use strict;

use Scalar::MoreUtils qw(:all);

my $TESTS = 0;


# nil
BEGIN { $TESTS += 2 }
{
	ok(nil undef);
	ok(! nil 0);
}

# empty
BEGIN { $TESTS += 5 }
{
	ok(empty undef);
	ok(empty "");
	ok(!empty " ");
	ok(!empty 0);
	ok(!empty 1);
}

# define
BEGIN { $TESTS += 4 }
{
	is(define(undef), "");
	is(define(""), "");
	is(define(0), 0);
	is(define(1), 1);
}

# default
BEGIN { $TESTS += 7 }
{
	is(default(undef, undef), undef);
	is(default(undef, ""), "");
	is(default(undef, 0), 0);
	is(default(0, 1), 0);
	is(default(1, 1), 1);
	is(default(1, "Argh!"), 1);
	is(default("Argh!", 1), "Argh!");
}

# ifnil
BEGIN { $TESTS += 7 }
{
	is(ifnil(undef, undef), undef);
	is(ifnil(undef, ""), "");
	is(ifnil(undef, 0), 0);
	is(ifnil(0, 1), 0);
	is(ifnil(1, 1), 1);
	is(ifnil(1, "Argh!"), 1);
	is(ifnil("Argh!", 1), "Argh!");
}

# ifempty
BEGIN { $TESTS += 8 }
{
	is(ifempty(undef, undef), undef);
	is(ifempty(undef, ""), "");
	is(ifempty(undef, 0), 0);
	is(ifempty(0, 1), 0);
	is(ifempty(1, 1), 1);
	is(ifempty(1, "Argh!"), 1);
	is(ifempty("", "Argh!"), "Argh!");
	is(ifempty("Argh!", 1), "Argh!");
}

BEGIN { plan tests => $TESTS }
