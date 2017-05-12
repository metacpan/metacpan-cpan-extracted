use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

foreach("", "1,2") {
	eval qq{
		use Scope::Cleanup qw(establish_cleanup);
		my \$x = sub { establish_cleanup($_); };
	};
	isnt $@, "";
}

eval { do { &establish_cleanup(sub{}); }; };
like $@, qr/\Aestablish_cleanup called as a function/;
eval { do { &establish_cleanup(); }; };
like $@, qr/\Aestablish_cleanup called as a function/;

eval { do { establish_cleanup([]); }; };
like $@, qr/\ANot a CODE reference/;

1;
