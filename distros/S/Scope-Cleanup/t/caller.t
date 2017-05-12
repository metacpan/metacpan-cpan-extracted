use warnings;
use strict;

BEGIN {
	unless("$]" >= 5.008004) {
		require Test::More;
		Test::More->import(skip_all =>
			"cleanup code can't see caller on this perl");
	}
}

use Test::More tests => 2;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my(@c0, @c1);

sub {
	@c0 = caller(0);
	establish_cleanup sub { @c1 = caller(1); };
}->();
is_deeply \@c0, \@c1;

1;
