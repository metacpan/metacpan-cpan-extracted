#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::Neo4j::Types 0.03;
use Test::More 0.94;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Time::Piece;
use Neo4j_Test::MockQuery;
use Neo4j::Driver;

BEGIN {
	require Neo4j::Types;
	plan skip_all => 'Test requires Neo4j::Types v2' unless eval { Neo4j::Types->VERSION('2.00') };
}



# Confirm that the deep_bless Jolt parser correctly converts
# Neo4j temporal values to Neo4j::Types v2 values.

my ($d, $s, $v);

plan tests => 16 + $no_warnings;


my $mock_plugin = Neo4j_Test::MockQuery->new;
$d = Neo4j::Driver->new('http:')->plugin($mock_plugin);
$s = $d->session;

my $mock_jolt_query;
sub mock_jolt {
	my $query = 'mock_jolt_query_' . ++$mock_jolt_query;
	$mock_plugin->query_result($query => shift);
	return $query;
}


# Trigger Jolt.pm to load DateTime.pm (with require instead of use to allow for 1.00)
$s->run(mock_jolt { 'T' => '00:00:00' });

SKIP: { skip '(Time-Piece#47: strftime broken on Win32)', 1 if $^O =~ /Win32/;
neo4j_datetime_ok 'Neo4j::Driver::Type::DateTime', sub {
	my ($class, $params) = @_;
	my $iso = '';
	if (defined $params->{days}) {
		$iso = gmtime( $params->{days} * 86400 )->strftime('%Y-%m-%d');
	}
	if (defined $params->{seconds} || defined $params->{nanoseconds}) {
		# 'T' is always required by ISO, but Neo4j omits it for TIME values
		$iso .= 'T' if length $iso;
		$iso .= gmtime( $params->{seconds} // 0 )->strftime('%H:%M:%S');
	}
	if (defined $params->{nanoseconds}) {
		$iso .= sprintf '.%09i', $params->{nanoseconds};
	}
	if (defined $params->{tz_offset}) {
		$iso .= sprintf '%s%02i:%02i',
			$params->{tz_offset} < 0 ? '-' : '+',
			int(abs $params->{tz_offset} / 3600),
			int(abs $params->{tz_offset} % 3600 / 60);
	}
	if (defined $params->{tz_name}) {
		$iso .= sprintf '[%s]', $params->{tz_name};
	}
	return bless { 'T' => $iso }, $class;
};
}


subtest 'LocalDateTime' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => '2015-07-04T19:32:24' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'LocalDateTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'LocalDateTime';
	is $v->type, 'LOCAL DATETIME', 'LocalDateTime type';
	is $v->epoch, 1436038344, 'LocalDateTime epoch';
	is $v->tz_offset, undef, 'LocalDateTime no offset';
	is $v->tz_name, undef, 'LocalDateTime no zone';
};


subtest 'ZonedDateTime full' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => '1987-12-18T12:00:00-08:00[America/Los_Angeles]' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'ZonedDateTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'ZonedDateTime';
	$v->seconds;  # init _parse
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->epoch, 566827200, 'ZonedDateTime full epoch';
	is $v->tz_offset, -28800, 'ZonedDateTime full offset';
	is $v->tz_name, 'America/Los_Angeles', 'ZonedDateTime full name';
};


subtest 'ZonedDateTime offset' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => '1987-12-18T12:00:00-08:00' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'ZonedDateTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'ZonedDateTime';
	$v->days;  # init _parse
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->epoch, 566827200, 'ZonedDateTime offset epoch';
	is $v->tz_offset, -28800, 'ZonedDateTime offset';
	is $v->tz_name, 'Etc/GMT+8', 'ZonedDateTime offset name';
};


subtest 'ZonedDateTime name' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => '1987-12-18T12:00:00[America/Los_Angeles]' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'ZonedDateTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'ZonedDateTime';
	$v->nanoseconds;  # init _parse
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->epoch, 566827200, 'ZonedDateTime name epoch';
	is $v->tz_offset, undef, 'ZonedDateTime name no offset';
	is $v->tz_name, 'America/Los_Angeles', 'ZonedDateTime name';
};


subtest 'ZonedTime' => sub {
	plan tests => 7;
	$v = $s->run(mock_jolt { 'T' => '12:50:35.000556Z' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'ZonedTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'ZonedTime';
	$v->tz_name;  # init _parse
	is $v->type, 'ZONED TIME', 'ZonedTime type';
	is $v->epoch, 46235, 'ZonedTime epoch';
	is $v->nanoseconds, 556_000, 'ZonedTime nanos';
	is $v->tz_offset, 0, 'ZonedTime zulu offset';
	is $v->tz_name, 'Etc/GMT', 'ZonedTime zulu name';
};


subtest 'LocalTime' => sub {
	plan tests => 5;
	$v = $s->run(mock_jolt { 'T' => '12:34:56' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'LocalTime legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'LocalTime';
	$v->tz_offset;  # init _parse
	is $v->type, 'LOCAL TIME', 'LocalTime type';
	is $v->epoch, 45296, 'LocalTime epoch';
	is $v->nanoseconds, 0, 'LocalTime nanos';
};


subtest 'Date' => sub {
	plan tests => 5;
	$v = $s->run(mock_jolt { 'T' => '2002-04-16' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Date legacy';
	isa_ok $v, 'Neo4j::Types::DateTime', 'Date';
	is $v->type, 'DATE', 'Date type';
	is $v->days, 11793, 'Date epoch';
	is $v->seconds, undef, 'Date secs';
};


subtest 'ZonedDateTime non-standard offsets' => sub {
	plan tests => 9;
	# large negative offset
	$v = $s->run(mock_jolt { 'T' => '2001-01-01T00:00:00-13:00' })->single->get;
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->tz_offset, -46800, 'ZonedDateTime offset';
	is $v->tz_name, undef, 'ZonedDateTime offset name';
	# large positive offset
	$v = $s->run(mock_jolt { 'T' => '2001-01-01T00:00:00+15:00' })->single->get;
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->tz_offset, 54000, 'ZonedDateTime offset';
	is $v->tz_name, undef, 'ZonedDateTime offset name';
	# partial hour offset
	$v = $s->run(mock_jolt { 'T' => '2001-01-01T00:00:00+00:30' })->single->get;
	is $v->type, 'ZONED DATETIME', 'ZonedDateTime type';
	is $v->tz_offset, 1800, 'ZonedDateTime offset';
	is $v->tz_name, undef, 'ZonedDateTime offset name';
};


# Trigger Jolt.pm to load DateTime.pm (with require instead of use to allow for 1.00)
$s->run(mock_jolt { 'T' => 'PT0S' });

neo4j_duration_ok 'Neo4j::Driver::Type::Duration', sub {
	my ($class, $params) = @_;
	my $iso = sprintf 'P%sM%sDT%.9fS',
		($params->{months} // 0), ($params->{days} // 0),
		($params->{seconds} // 0) + ($params->{nanoseconds} // 0) / 1e9;
	return bless { 'T' => $iso }, $class;
};


subtest 'Duration simple' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => 'P29WT31M' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Duration legacy';
	isa_ok $v, 'Neo4j::Types::Duration', 'Duration';
	$v->nanoseconds;  # init _parse
	is $v->months, 0, 'months';
	is $v->days, 203, 'days';
	is $v->seconds, 1860, 'secs';
	is $v->nanoseconds, 0, 'nanos';
};


subtest 'Duration time' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => 'PT13H17M19.023S' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Duration legacy';
	isa_ok $v, 'Neo4j::Types::Duration', 'Duration';
	$v->days;  # init _parse
	is $v->months, 0, 'no months';
	is $v->days, 0, 'no days';
	is $v->seconds, 47839, 'secs';
	is $v->nanoseconds, 23_000_000, 'nanos';
};


subtest 'Duration no time' => sub {
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => 'P3Y5M7W11D' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Duration legacy';
	isa_ok $v, 'Neo4j::Types::Duration', 'Duration';
	$v->seconds;  # init _parse
	is $v->months, 41, 'months';
	is $v->days, 60, 'days';
	is $v->seconds, 0, 'no secs';
	is $v->nanoseconds, 0, 'no nanos';
};


subtest 'Duration negative' => sub {
	# Negative/reverse durations were specified by ISO in a 2019 update:
	# https://www.postgresql.org/message-id/9q0ftb37dv7.fsf%40gmx.us
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => 'P-3Y-5M-7W-11DT-13H-17M-19.023S' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Duration legacy';
	isa_ok $v, 'Neo4j::Types::Duration', 'Duration';
	is $v->months, -41, 'months';
	is $v->days, -60, 'days';
	is $v->seconds, -47839, 'secs';
	is $v->nanoseconds, -23_000_000, 'nanos';
};


subtest 'Duration reverse' => sub {
	# The Neo4j server currently can't actually produce this format,
	# but there seem to be a number of bugs around ISO duration handling
	# in the Neo4j server, so maybe reverse-direction durations will be
	# added if/when those issues are addressed.
	plan tests => 6;
	$v = $s->run(mock_jolt { 'T' => '-P3Y5M7W11DT13H17M19.023S' })->single->get;
	isa_ok $v, 'Neo4j::Driver::Type::Temporal', 'Duration legacy';
	isa_ok $v, 'Neo4j::Types::Duration', 'Duration';
	is $v->months, -41, 'months';
	is $v->days, -60, 'days';
	is $v->seconds, -47839, 'secs';
	is $v->nanoseconds, -23_000_000, 'nanos';
};


subtest 'temporal JSON' => sub {
	plan tests => 8;
	my $json = <<END;
{"errors":[],"results":[{"columns":["DateTime","Duration"],"data":[{"meta":[{"type":"datetime"},{"type":"duration"}],"rest":["2015-07-04T19:32:24+01:00","P30Y8M13D"],"row":["2015-07-04T19:32:24+01:00","P30Y8M13D"]}]}]}
END
	$mock_plugin->response_for('/db/json/tx/commit', 'temporal json' => { json => $json });
	my $r = $d->session(database => 'json')->run('temporal json')->single;
	isa_ok $v = $r->get('DateTime'), 'Neo4j::Types::DateTime', 'DateTime';
	is $v->type, 'ZONED DATETIME', 'DateTime type';
	is $v->epoch, 1436038344, 'DateTime epoch';
	isa_ok $v = $r->get('Duration'), 'Neo4j::Types::Duration', 'Duration';
	is $v->months, 368, 'months';
	is $v->days, 13, 'days';
	is $v->seconds, 0, 'secs';
	is $v->nanoseconds, 0, 'nanos';
};


done_testing;
