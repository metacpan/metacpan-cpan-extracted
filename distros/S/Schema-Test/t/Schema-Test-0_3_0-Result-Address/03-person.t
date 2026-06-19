use strict;
use warnings;

use Schema::Test::0_3_0;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
ok(Schema::Test::0_3_0->source('Address')->has_relationship('person'), 'Has person relationship.');
