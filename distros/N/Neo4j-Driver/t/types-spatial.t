#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::Neo4j::Types;
use Test::More 0.94;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j_Test::MockQuery;
use Neo4j::Driver;


# Confirm that the deep_bless Jolt parser correctly converts
# Neo4j spatial values to Neo4j::Types v2 values.

my ($d, $v);

plan tests => 4 + $no_warnings;


my $mock_plugin = Neo4j_Test::MockQuery->new;
$d = Neo4j::Driver->new('http:')->plugin($mock_plugin);


SKIP: {
skip 'neo4j_point_ok: GH neo4j-types#18', 1 unless eval { Test::Neo4j::Types->VERSION('2.0051') };
neo4j_point_ok 'Neo4j::Driver::Type::Point', sub {
	my ($class, $params) = @_;
	my $has_z = @{$params->{coordinates}} == 3 ? ' Z ' : '';
	my $wkt = sprintf 'SRID=%s;POINT%s(%s)',
		$params->{srid}, $has_z, join ' ', @{$params->{coordinates}};
	return bless { '@' => $wkt }, $class;
};
}


subtest 'Point' => sub {
	$mock_plugin->query_result('point 2d' => { '@' => 'SRID=4326;POINT(2.5 -72.0)' });
	$v = $d->session->run('point 2d')->single->get;
	isa_ok $v, 'Neo4j::Types::Point', 'Point';
	is $v->srid, 4326, 'srid';
	is_deeply [$v->coordinates], [2.5, -72], 'coordinates';
};


subtest 'Point 3D' => sub {
	$mock_plugin->query_result('point 2d' => { '@' => 'SRID=9157;POINT Z (3.0 0.0 1.0)' });
	$v = $d->session->run('point 2d')->single->get;
	isa_ok $v, 'Neo4j::Types::Point', 'Point';
	$v->coordinates;  # init _parse
	is $v->srid, 9157, 'srid';
	is_deeply [$v->coordinates], [3, 0, 1], 'coordinates';
};


subtest 'Point JSON' => sub {
	plan tests => 3;
	my $json = <<END;
{"errors":[],"results":[{"columns":["0"],"data":[{"meta":[{"type":"point"}],"rest":[{"coordinates":[5.0,7.0],"crs":{"name":"cartesian","properties":{"href":"http://spatialreference.org/ref/sr-org/7203/ogcwkt/","type":"ogcwkt"},"srid":7203,"type":"link"},"type":"Point"}],"row":[{"coordinates":[5.0,7.0],"crs":{"name":"cartesian","properties":{"href":"http://spatialreference.org/ref/sr-org/7203/ogcwkt/","type":"ogcwkt"},"srid":7203,"type":"link"},"type":"Point"}]}]}]}
END
	$mock_plugin->response_for('/db/json/tx/commit', 'point json' => { json => $json });
	$v = $d->session(database => 'json')->run('point json')->single->get;
	isa_ok $v, 'Neo4j::Types::Point', 'Point';
	is $v->srid, 7203, 'srid';
	is_deeply [$v->coordinates], [5, 7], 'coordinates';
};

done_testing;
