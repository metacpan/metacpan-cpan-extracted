
# Test::More calls functions from Test::Builder which all eventually call
# Test::Builder::ok (on the (singular) builder instance) to report the
# status. Here we define a builder subclass derived from Test::Builder,
# with a redefined ok method that overrides the completion status seen by
# the test harness.
#
# Note: The reported completion status is only modified if the file
# 't/online.nonfatal' exists.
#
# The functions NonFatalBegin and NonFatalEnd re-bless the builder
# instance to be of type NonFatal and Test::Builder respectively.
# Tests that are between those functions will thus appear to succeed.
# The failure report itself is not suppressed.
#
# This is just a quick hack to allow for non-fatal unit tests. It has many
# problems such as for example that blocks marked by the NonFatalBegin and
# NonFatalEnd subroutines may not be nested.


package NonFatal;

use strict;
use warnings;
use base qw(Test::Builder);

use constant NONFATAL => 1;

my @failed;

sub ok {
	my ( $self, $test, @name ) = @_;

	return $self->SUPER::ok( $test, @name ) unless NONFATAL;
	return $self->SUPER::ok( $test, @name ) if $test;

	push @failed, join( "\t", $self->current_test, @name );

	$self->SUPER::ok( 1, "NOT OK (tolerating failure)  @name" );
	return $test;
}


END {
	my $n = scalar(@failed) || return;
	my $s = ( $n == 1 ) ? '' : 's';
	Test::Builder->new->diag( join "\n\t", "\tDisregarding $n failed sub-test$s", @failed );
	0;
}


package main;				## no critic ProhibitMultiplePackages

sub NonFatalBegin {
	bless Test::Builder->new, qw(NonFatal);
	return;
}

sub NonFatalEnd {
	bless Test::Builder->new, qw(Test::Builder);
	return;
}


1;

__END__

