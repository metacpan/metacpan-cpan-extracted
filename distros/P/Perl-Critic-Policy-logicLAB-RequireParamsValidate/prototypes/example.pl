#!/usr/bin/env perl

# $Id$

use strict;
use warnings;
use Params::Validate qw(:all);

foo();
bar();
_baz();

exit 0;

# takes named params (hash or hashref)
sub foo {
    validate(
		@_, {
			foo => 1,    # mandatory
				bar => 0,    # optional
		}
	);
}

sub bar {
    return 1;
}

sub _baz {
    return 0;
}

#Illegal declaration of anonymous subroutine at prototypes/example.pl line 12.
sub sub {
	print "WTF!?";
}
