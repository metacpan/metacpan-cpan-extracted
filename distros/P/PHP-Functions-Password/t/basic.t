# $Id: basic.t,v 1.2 2017/06/21 19:29:22 cmanley Exp $
use strict;
use warnings;
use Test::More; #qw(no_plan);
use lib qw(../lib);

my @methods = map { $_, "password_$_"; } qw(
	get_info
	hash
	needs_rehash
	verify
);

plan tests => 1 + scalar(@methods);

my $class = 'PHP::Functions::Password';
require_ok($class) || BAIL_OUT("$class has errors");
foreach my $method (@methods) {
	can_ok($class, $method);
}
