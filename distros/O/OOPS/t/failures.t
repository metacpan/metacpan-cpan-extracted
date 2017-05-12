#!/usr/bin/perl -I../lib

use strict;
use warnings;
use diagnostics;
use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter Data::Dumper Clone::PP);
import Clone::PP qw(clone);
use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use OOPS::TestCommon;

print "1..27\n";

resetall; # --------------------------------------------------
{
	my $tests = <<'END';

		#
		# I don't know why this fails.
		# The really weird thing is that the following test
		# does not fail.  They do almost exactly the
		# same thing.  Since this involves references that 
		# contemplate their own navel, I'm releasing OOPS
		# anyway.
		#
		%$root = (
			hkey => { skey2 => 'sval2' },
		);
		$root->{hkey}{'skey2'} = \$root->{hkey}{skey2};
		$root->{eref91} = $root->{hkey}{'skey2'};
		COMMIT
		${$root->{eref91}} = 7039;
		TODO_COMPARE

		%$root = (
			hkey => { skey2 => 'sval2' },
		);
		my $x;
		$x = \$x;
		$root->{hkey}{'skey2'} = $x;
		$root->{eref91} = $root->{hkey}{'skey2'};
		COMMIT
		${$root->{eref91}} = 7039;
		COMPARE

		#
		# This fails because we don't keep the bless 
		# information with the scalar but rather with the
		# ref.
		#
		$root->{x} = 'foobar';
		COMPARE
		$root->{y} = \$root->{x};
		COMPARE
		wa($root->{y});
		COMPARE
		bless $root->{y}, 'baz';
		COMPARE
		COMMIT
		$root->{y} = 7;
		COMMIT
		$root->{y} = \$root->{x};
		wa($root->{y});
		TODO_COMPARE

END
	my $root = {
		h	=> {
			k	=> 'v',
		},
		a	=> [ 'av' ],
		r	=> \'sr',
	};
	supercross7($tests, { baseroot => $root });
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;
