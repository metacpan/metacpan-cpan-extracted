# $Id: NonFatal.pm 1823 2020-11-16 16:29:45Z willem $	-*-perl-*-

# Test::More calls functions from Test::Builder. Those functions all eventually
# call Test::Builder::ok (on a builder instance) for reporting the status.
# Here we define a new builder inherited from Test::Builder, with a redefined
# ok method that always reports the test to have completed successfully.
#
# The functions NonFatalBegin and NonFatalEnd re-bless the builder in use by
# Test::More (Test::More->builder) to be of type NonFatal and Test::Builder
# respectively. Tests that are between those functions will thus always appear
# to succeed. The failure report itself is not suppressed.
#
# Note that the builder is only re-blessed when the file 't/online.nonfatal'
# exists.
#
# This is just a quick hack to allow for non-fatal unit tests. It has many
# problems such as for example that blocks marked by the NonFatalBegin and
# NonFatalEnd subroutines may not be nested.
#

package NonFatal;

use strict;
use warnings;
use base qw(Test::Builder);

my @failed;

sub ok {
	my ( $self, $test, @name ) = @_;

	return $self->SUPER::ok( 1, @name ) if $test;

	$self->SUPER::ok( 1, "NOT OK (tolerating failure)  @name" );

	push @failed, join( "\t", $self->current_test, @name );
	return $test;
}


sub diag {
	my @annotation = @_;
	return Test::More->builder->diag(@annotation);
}


END {
	my $n = scalar(@failed);
	my $s = $n > 1 ? 's' : '';
	bless Test::More->builder, qw(Test::Builder);
	diag( join "\n\t", "\tDisregarding $n failed sub-test$s", @failed ) if $n;
	return;
}


package main;				## no critic ProhibitMultiplePackages

require Test::More;

use constant NONFATAL => eval { -e 't/online.nonfatal' };

sub NonFatalBegin {
	bless Test::More->builder, qw(NonFatal) if NONFATAL;
	return;
}

sub NonFatalEnd {
	bless Test::More->builder, qw(Test::Builder) if NONFATAL;
	return;
}


1;

__END__

