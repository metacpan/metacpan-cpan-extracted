#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


# Loading Neo4j::Types loads all type packages

plan tests => 9 + $no_warnings;


require_ok 'Neo4j::Types';
ok $INC{'Neo4j/Types.pm'},              'use Neo4j::Types';
ok $INC{'Neo4j/Types/ByteArray.pm'},    'use byte array';
ok $INC{'Neo4j/Types/DateTime.pm'},     'use datetime';
ok $INC{'Neo4j/Types/Duration.pm'},     'use duration';
ok $INC{'Neo4j/Types/Node.pm'},         'use node';
ok $INC{'Neo4j/Types/Path.pm'},         'use path';
ok $INC{'Neo4j/Types/Point.pm'},        'use point';
ok $INC{'Neo4j/Types/Relationship.pm'}, 'use relationship';


done_testing;
