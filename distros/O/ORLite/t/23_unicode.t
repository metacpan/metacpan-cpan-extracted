#!/usr/bin/perl

# Tests for the unicode option

BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;

BEGIN {
	# Tests won't succeed before 5.8.5
	if ( $] < 5.008005 ) {
		plan skip_all => 'Perl 5.8.5 or above required.';
	}
}

use utf8;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

plan tests => 19;

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 23_unicode.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package My;

use strict;
use ORLite {
	file    => '$file',
	unicode => 1,
};

1;
END_PERL





#####################################################################
# Basic test to fetch something from the database

SCOPE: {
	# Loaded correctly
	my $smiley = My::Foo->load(1);
	isa_ok($smiley, 'My::Foo');

	# Check that the is_utf8 flags are set as expected
	ok( ! utf8::is_utf8($smiley->id),  '->id not utf8'  );
	ok( ! utf8::is_utf8($smiley->one), '->one not utf8' );
	ok( ! utf8::is_utf8($smiley->two), '->two not utf8' );
	ok( utf8::is_utf8($smiley->name),  '->name is utf8' );
	ok( utf8::is_utf8($smiley->text),  '->text is utf8' );
	is($smiley->text, '☺', 'right smiley');
}





######################################################################
# Test round tripping of unicode objects

SCOPE: {
	my $smiley1 = My::Foo->create(
		one  => 1,
		two  => 1.125,
		name => 'foo',
		text => "\x{263A}",
	);
	isa_ok( $smiley1, 'My::Foo' );
	ok( ! utf8::is_utf8($smiley1->id), '->id not utf8' );
	ok( ! utf8::is_utf8($smiley1->one), '->one not utf8' );
	ok( ! utf8::is_utf8($smiley1->two), '->two not utf8' );

	my $smiley2 = My::Foo->load(2);
	isa_ok( $smiley2, 'My::Foo' );
	ok( ! utf8::is_utf8($smiley2->id),  '->id not utf8'  );
	ok( ! utf8::is_utf8($smiley2->one), '->one not utf8' );
	ok( ! utf8::is_utf8($smiley2->two), '->two not utf8' );
	ok( utf8::is_utf8($smiley2->name),  '->name is utf8' );
	ok( utf8::is_utf8($smiley2->text),  '->text is utf8' );

	is_deeply( $smiley1, $smiley2, 'Round trip ok' );
}
