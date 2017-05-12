#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 1;


SKIP:
{
	skip( 'Temporary database file does not exist.', 1 )
		if ! -e 't/01-Admin/test_database';

	ok(
		unlink( 't/01-Admin/test_database' ),
		'Remove temporary database file',
	);
}
