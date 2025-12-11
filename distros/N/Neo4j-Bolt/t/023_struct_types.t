use v5.12;
use warnings;
use Test::More;
use Neo4j::Bolt::NeoValue;
use Neo4j::Bolt::DateTime;

my ($i, $v, $vv);
#diag "create neo4j_values from hashes";

$i = bless { epoch_days => 29*365 }, "Neo4j::Bolt::DateTime";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Date", "Date";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"Date roundtrip";

$i = bless { nsecs => 43299*1_000_000_000 }, "Neo4j::Bolt::DateTime";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "LocalTime", "LocalTime";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"LocalTime roundtrip";

$i = bless { epoch_secs => 29*365*86000, nsecs=>003000000, offset_secs => -5*3600 }, "Neo4j::Bolt::DateTime";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "DateTime", "DateTime";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"DateTime roundtrip";

$i = bless { nsecs => 43200*1_003_000_000, offset_secs => -5*3600 }, "Neo4j::Bolt::DateTime";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Time", "Time";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"Time roundtrip";

$i = bless { epoch_secs => 29*365*86000, nsecs=>003000000 }, "Neo4j::Bolt::DateTime";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "LocalDateTime", "LocalDateTime";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"LocalDateTime roundtrip";

$i = bless { months => 13, days => 200, secs => 0, nsecs => 0  }, "Neo4j::Bolt::Duration";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Duration", "Duration";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"Duration roundtrip";

$i = bless { srid => 4326, x => 1.0, y => 3.0 }, "Neo4j::Bolt::Point";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Point2D", "Point2D";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"Point roundtrip";

$i = bless { srid => 4326, x => 1.0, y => 3.0, z => -1.5 }, "Neo4j::Bolt::Point";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is $v->_neotype, "Point3D", "Point3D";
$vv = $v->_as_perl;
delete $vv->{neo4j_type};
is_deeply $vv,$i,"Point roundtrip";

SKIP: {
  skip "DateTime module", 4 unless eval { require DateTime; 1 };
  
  $i = bless { epoch_secs => $v = 29*365*86000, neo4j_type => 'LocalDateTime' }, "Neo4j::Bolt::DateTime";
  isa_ok $vv = $i->as_DateTime(), 'DateTime';
  is $vv->epoch(), $v, 'DateTime epoch';
  
  $i = bless { months => 1, days => 2, secs => 3, nsecs => 4 }, "Neo4j::Bolt::Duration";
  isa_ok $vv = $i->as_DTDuration(), 'DateTime::Duration';
  is $vv->in_units('days'), 2, 'DateTime::Duration days';
}

done_testing;
