#
# use_consts.t
#
use Test::More tests => 6;
use strict;
BEGIN {
	our @consts = qw(SEM_NSEMS_MAX SEM_VALUE_MAX _SC_SEM_NSEMS_MAX _SC_SEM_VALUE_MAX SIZEOF_SEM_T);
	use_ok('POSIX::RT::Semaphore', @consts);
}

our @consts;

for my $sym (@consts) {
	my $r;

	eval {
		no strict 'refs';
		$r = &{$sym}();
	};

	if (! $@) {
		pass("$sym (is $r)");
	} else {
		fail("$sym failure: $@");
	}
}
