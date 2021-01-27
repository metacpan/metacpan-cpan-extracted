use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Tag::Reader::Perl');
}

# Test.
require_ok('Tag::Reader::Perl');
