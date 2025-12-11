use v5.12;
use warnings;
use Test::More;
use Neo4j::Bolt::NeoValue;

eval {
	require Neo4j::Types::Generic::DateTime;
	require Neo4j::Types::Generic::Duration;
	require Neo4j::Types::Generic::Point;
	1;
} or plan skip_all => "Neo4j::Types v2 unavailable";

my ($i, $v, $vv);
#diag "create neo4j_values from objects";

$i = Neo4j::Types::Generic::DateTime->new({ days => 29*365 });
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Date", "Date";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "Date roundtrip $_"
	for qw( days epoch nanoseconds seconds type tz_name tz_offset );

$i = Neo4j::Types::Generic::DateTime->new({ seconds => 43299 });
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "LocalTime", "LocalTime";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "LocalTime roundtrip $_"
	for qw( days epoch nanoseconds seconds type tz_name tz_offset );

$i = Neo4j::Types::Generic::DateTime->new({
	days        => 11,
	seconds     => 43329,
	nanoseconds => 600_000_000,
	#tz_name     => "America/New_York",
	tz_offset   => -5*3600,
});
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "DateTime", "DateTime";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "DateTime roundtrip $_"
	for qw( days epoch nanoseconds seconds type tz_name tz_offset );

$i = Neo4j::Types::Generic::DateTime->new({
	seconds     => 43329,
	nanoseconds => 600_000_000,
	tz_offset   => -5*3600,
});
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Time", "Time";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "Time roundtrip $_"
	for qw( days epoch nanoseconds seconds type tz_name tz_offset );

$i = Neo4j::Types::Generic::DateTime->new( 29*365*86000 );
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "LocalDateTime", "LocalDateTime";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "LocalDateTime roundtrip $_"
	for qw( days epoch nanoseconds seconds type tz_name tz_offset );

$i = Neo4j::Types::Generic::Duration->new({
	months      => 13,
	days        => 200,
	seconds     => 0,
	nanoseconds => 0,
});
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Duration", "Duration";
$vv = $v->_as_perl;
is $vv->$_(), $i->$_(), "Duration roundtrip $_"
	for qw( months days seconds nanoseconds );

$i = Neo4j::Types::Generic::Point->new( 4326, 1.0, 3.0 );
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Point2D", "Point2D";
$vv = $v->_as_perl;
is $vv->srid(), $i->srid(), "Point2D roundtrip srid";
is_deeply [$vv->coordinates()], [$i->coordinates()], "Point2D roundtrip coordinates";

$i = Neo4j::Types::Generic::Point->new( 9157, 1.0, 3.0, -1.5 );
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Point3D", "Point3D";
$vv = $v->_as_perl;
is $vv->srid(), $i->srid(), "Point3D roundtrip srid";
is_deeply [$vv->coordinates()], [$i->coordinates()], "Point3D roundtrip coordinates";

done_testing;
