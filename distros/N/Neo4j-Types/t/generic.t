#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Neo4j::Types;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j::Types::Generic::ByteArray;
use Neo4j::Types::Generic::DateTime;
use Neo4j::Types::Generic::Duration;
use Neo4j::Types::Generic::Point;


# Generic type implementations are conformant

plan tests => 5 + $no_warnings;


neo4j_bytearray_ok 'Neo4j::Types::Generic::ByteArray', sub {
	my ($class, $params) = @_;
	Neo4j::Types::Generic::ByteArray->new($params->{as_string});
}, 'generic ByteArray';


neo4j_datetime_ok 'Neo4j::Types::Generic::DateTime', sub {
	my ($class, $params) = @_;
	Neo4j::Types::Generic::DateTime->new($params);
}, 'generic DateTime';

neo4j_datetime_ok 'Neo4j::Types::Generic::DateTime', sub {
	my ($class, $params) = @_;
	return Neo4j::Types::Generic::DateTime->new($params)
		unless defined $params->{days} && defined $params->{seconds};
	
	# For Neo4j DATETIME values, test the epoch constructor variant
	my $epoch = $params->{days} * 86400 + $params->{seconds};
	my $tz = $params->{tz_name} // $params->{tz_offset};
	return Neo4j::Types::Generic::DateTime->new($epoch, $tz);
}, 'generic DateTime using epoch in constructor';


neo4j_duration_ok 'Neo4j::Types::Generic::Duration', sub {
	my ($class, $params) = @_;
	Neo4j::Types::Generic::Duration->new($params);
}, 'generic Duration';


neo4j_point_ok 'Neo4j::Types::Generic::Point', sub {
	my ($class, $params) = @_;
	Neo4j::Types::Generic::Point->new(
		$params->{srid},
		@{$params->{coordinates}},
	);
}, 'generic Point';


done_testing;
