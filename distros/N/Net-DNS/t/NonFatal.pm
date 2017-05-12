# $Id: NonFatal.pm 1381 2015-08-25 07:36:09Z willem $	-*-perl-*-

# Test::More calls functions from Test::Builder. Those functions all eventually
# call Test::Builder::ok (on a builder instance) for reporting the status.
# Here we define a new builder inherited from Test::Builder, with a redefined
# ok method that always reports the test to have completed successfully.
#
# The functions NonFatalBegin and NonFatalEnd re-bless the builder in use by
# Test::More (Test::More->builder) to be of type Test::NonFatal and
# Test::Builder respectively. Tests that are between those functions will thus
# always appear to succeed. The failure report itself is not suppressed.
#
# Note that the builder is only re-blessed when the file 't/online.nonfatal'
# exists.
#
# This is just a quick hack to allow for non-fatal unit tests. It has many
# problems such as for example that blocks marked by the NonFatalBegin and
# NonFatalEnd subroutines may not be nested.
#

use strict;
use Test::More;

use constant NONFATAL => eval { -e 't/online.nonfatal' };

{
	package Test::NonFatal;

	use base qw(Test::Builder);

	sub ok {
		my ( $self, $test, $name ) = ( @_, '' );

		$name = "NOT OK, but tolerating failure, $name" unless $test;

		$self->SUPER::ok( 1, $name );

		return $test ? 1 : 0;
	}
}


sub NonFatalBegin {
	bless Test::More->builder, qw(Test::NonFatal) if NONFATAL;
}

sub NonFatalEnd {
	bless Test::More->builder, qw(Test::Builder) if NONFATAL;
}


1;

