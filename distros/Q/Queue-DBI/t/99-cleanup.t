#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 1;


SKIP:
{
	skip( 'Temporary database file does not exist.', 1 )
		if ! -e 't/test_database';

	ok(
		unlink( 't/test_database' ),
		'Remove temporary database file',
	);
}
