#!/usr/bin/perl

# Tests for the unicode option

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

plan tests => 5;

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 25_blob.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package My;

use strict;
use ORLite {
	file => '$file',
};

1;
END_PERL





######################################################################
# Test round tripping of unicode objects

SCOPE: {
	my $smiley1 = My::Foo->create(
		name    => 'foo',
		content => "\001\012\015",
		notype  => "\000\001\012\015",
	);
	isa_ok( $smiley1, 'My::Foo' );

	# Known broken
	TODO: {
		local $TODO = "Known problems with BLOB types";

		my $len = My->selectrow_arrayref(
			'select length(name), length(content), length(notype) from foo',
		);
		is_deeply( $len, [ 3, 3, 4 ], 'Lengths ok' );
	}

	my $smiley2 = My::Foo->load($smiley1->id);
	isa_ok( $smiley2, 'My::Foo' );

	is_deeply( $smiley1, $smiley2, 'Round trip ok' );
}
