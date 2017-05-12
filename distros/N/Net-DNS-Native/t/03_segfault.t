use strict;
use Net::DNS::Native;
use Test::More;

my $dns = Net::DNS::Native->new;

my @fh;
my $buf;
eval {
	for (1..3) {
		@fh = ();
		for (1..70) {
			push @fh, $dns->getaddrinfo('localhost');
		}
		sysread($_, $buf, 1) && $dns->get_result($_) for @fh;
	}
};
if (my $err = $@) {
	if ($err =~ /socketpair|pthread/) {
		sysread($_, $buf, 1) && $dns->get_result($_) for @fh;
		plan skip_all => $err;
	}
	else {
		fail('No errors');
		diag $err;
	}
}
else {
	pass('No errors');
}

pass('No segfault');
done_testing;
