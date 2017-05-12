#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);

BEGIN {
	my @warnings;
	local ( $SIG{__WARN__} ) = sub {
		push @warnings, @_;
	};
	use_ok("Perl::Command");
	is_deeply( \@warnings, [], "no warnings" );
}

ok(
	grep( /-Mlib=.*\/blib/, @PERL ),
	"generated a valid-looking command line"
);

