#! /usr/bin/perl

# convenience functions for our tests

use Errno qw(ENOSYS);

sub is_implemented(&) {
	my $block = shift;
	local $! = 0;
	&$block;
	return $! != &ENOSYS;
}

sub zero_but_true($) { return ($_[0] and $_[0] == 0); }

sub make_semname {
	my $name = "/abc.$$"; # FreeBSD has 14 char limit?
	return ($^O eq 'dec_osf') ? "/tmp/$name" : $name;
}

sub ok_getvalue {
	my ($sem, $expected, $msg) = @_;
	$msg = "getvalue() == $expected" unless $msg;

	my $val = $sem->getvalue;
	SKIP: {
		if (!(defined $val) and $!{ENOSYS}) {
			skip "getvalue unimplemented", 1;
		}
		ok($val == $expected, $msg);
	}
}

1;
