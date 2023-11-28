#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

use Test::Tester 0.08;
use Test::More 0.88;
use Test::Neo4j::Types;
use if $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


# Verify that the test tools check that users did load
# the module and properly report if they haven't.
# (Additionally, verify that the test tools provide
# a default test name when none is given.)

my $diag = '';
{
	no warnings 'redefine';
	*Test::Neo4j::Types::diag = sub { $diag = shift };
}


check_test(
	sub { neo4j_node_ok 'Neo4j_Test::Node', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_node_ok 'Neo4j_Test::Node'",
	}
);
is $diag, "Neo4j_Test::Node is not loaded", 'no node module diag';


check_test(
	sub { neo4j_relationship_ok 'Neo4j_Test::Rel', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_relationship_ok 'Neo4j_Test::Rel'",
	}
);
is $diag, "Neo4j_Test::Rel is not loaded", 'no relationship module diag';


check_test(
	sub { neo4j_path_ok 'Neo4j_Test::Path', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_path_ok 'Neo4j_Test::Path'",
	}
);
is $diag, "Neo4j_Test::Path is not loaded", 'no path module diag';


check_test(
	sub { neo4j_point_ok 'Neo4j::Types::Generic::Point', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_point_ok 'Neo4j::Types::Generic::Point'",
	}
);
is $diag, "Neo4j::Types::Generic::Point is not loaded", 'no point module diag';


check_test(
	sub { neo4j_datetime_ok 'Neo4j::Types::Generic::DateTime', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_datetime_ok 'Neo4j::Types::Generic::DateTime'",
	}
);
is $diag, "Neo4j::Types::Generic::DateTime is not loaded", 'no datetime module diag';


check_test(
	sub { neo4j_duration_ok 'Neo4j::Types::Generic::Duration', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_duration_ok 'Neo4j::Types::Generic::Duration'",
	}
);
is $diag, "Neo4j::Types::Generic::Duration is not loaded", 'no duration module diag';


check_test(
	sub { neo4j_bytearray_ok 'Neo4j::Types::Generic::ByteArray', sub {} },
	{
		ok => 0,
		depth => undef,
		name => "neo4j_bytearray_ok 'Neo4j::Types::Generic::ByteArray'",
	}
);
is $diag, "Neo4j::Types::Generic::ByteArray is not loaded", 'no bytearray module diag';


done_testing;
