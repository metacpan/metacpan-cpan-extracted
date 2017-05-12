use warnings;
use strict;

BEGIN { print "1..4\n"; }

use Scope::Cleanup qw(establish_cleanup);

sub {
	print "ok 1\n";
	do {
		establish_cleanup sub {
			print "ok 3\n";
			exit 0;
			print "not ok 1\n";
		};
		print "ok 2\n";
	};
	print "not ok 2\n";
}->();
print "not ok 3\n";

END { print "ok 4\n"; }

1;
