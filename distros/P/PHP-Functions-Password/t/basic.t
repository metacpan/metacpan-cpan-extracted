use strict;
use warnings;
use Test::More;
use lib qw(../lib);

my @methods = map { $_, "password_$_"; } qw(
	algos
	get_info
	hash
	needs_rehash
	verify
);

plan tests => 1 + scalar(@methods);

my $class = 'PHP::Functions::Password';
require_ok($class) || BAIL_OUT("Failed to require $class");

foreach my $method (@methods) {
	can_ok($class, $method);
}
#done_testing();
