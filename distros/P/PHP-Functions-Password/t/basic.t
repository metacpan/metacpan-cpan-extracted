# $Id: basic.t,v 1.3 2017/06/24 13:25:32 cmanley Exp $
use strict;
use warnings;
use Test::More;
use lib qw(../lib);
use PHP::Functions::Password;

my @methods = map { $_, "password_$_"; } qw(
	get_info
	hash
	needs_rehash
	verify
);

plan tests => scalar(@methods);

my $class = 'PHP::Functions::Password';
foreach my $method (@methods) {
	can_ok($class, $method);
}
#done_testing();