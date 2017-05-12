use warnings;
use strict;

BEGIN { print "1..3\n"; }

use Scope::Cleanup qw(establish_cleanup);

establish_cleanup sub { print "ok 3\n" };
sub aa() {
	establish_cleanup sub { print "ok 2\n" };
	do {
		establish_cleanup sub { print "ok 1\n" };
		exit 0;
		print "not ok 1\n";
	};
	print "not ok 2\n";
}
aa();
print "not ok 3\n";

1;
