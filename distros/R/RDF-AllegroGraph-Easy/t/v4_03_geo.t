use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

use RDF::AllegroGraph::Utils qw(coord2literal);

my $AG_SERVER = $ENV{AG4_SERVER};

unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

use RDF::AllegroGraph::Server;
my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
# TODO: generate scratch here
use RDF::AllegroGraph::Catalog4;
my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
use Fcntl;
my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

my ($c1, $c2, $c3, $c4);

if (DONE) {
    is ((scalar $model->geotypes), 0, 'initially no geotypes');

    $c1 = $model->cartesian ("100x100", 10);
#    warn $c1;
    like ($c1, qr/franz\.com/, 'cartesian coord system');

    $c2 = $model->cartesian ("100x100+50+50", 100);
#    warn $c2;
    like ($c2, qr/franz\.com/, 'cartesian coord system');

    $c3 = $model->cartesian (50, 50, 150, 150, 100);
#    warn $c3;
    is ($c2, $c3, 'same cartesian coord system');

    ok( eq_set([$c1, $c2],
	       [ $model->geotypes ] ), 'geotypes changed' );


    $c4 = $model->spherical (undef, '5.2 degree');

    like ($c4, qr{spherical},               'spherical');
    like ($c4, qr{-180.0/180.0/-90.0/90.0}, 'around the world');
    like ($c4, qr{5.2},                     'scale');

#    $c4 = $model->spherical ("100x100+50+50", '5 degree');
}

if (DONE) {
    $model->add (
		 [ '<urn:x-me:amsterdam>',    '<urn:x-me:location>', coord2literal ($c4,  4.883333,   52.366665 ) ],
		 [ '<urn:x-me:london>',       '<urn:x-me:location>', coord2literal ($c4, -0.08333333, 51.533333 ) ],
		 [ '<urn:x-me:sanfrancisco>', '<urn:x-me:location>', coord2literal ($c4, -122.433334, 37.783333 )],
		 [ '<urn:x-me:salvador>',     '<urn:x-me:location>', coord2literal ($c4, -88.45,      13.783333)]
		 );
    my @ss = $model->match ([undef, '<urn:x-me:location>', undef]);
    is ((scalar @ss), 4, 'adding location information (spherical)');

    @ss = $model->inBox ($c4, '<urn:x-me:location>', -130.0, 25.0, -70.0, 50.0);
    is ((scalar @ss), 1, 'inBox 1 (spherical)');
    is ($ss[0]->[0], '<urn:x-me:sanfrancisco>', 'found Frisco');

    @ss = $model->inCircle ($c4, '<urn:x-me:location>', -99.08, 19.3994, 20);  # 20 degrees
    is ((scalar @ss), 1, 'inCircle 1 (spherical)');
    is ($ss[0]->[0], '<urn:x-me:salvador>', 'found Salvador');

    @ss = $model->inPolygon ($c4, '<urn:x-me:location>', [2.00, 51.0], [-12.5, 48.0], [-5.0, 60.0] );
#    warn Dumper \@ss;
    is ((scalar @ss), 1, 'inPolygon 1 (spherical)');
    is ($ss[0]->[0], '<urn:x-me:london>', 'found London');

    $model->delete ([undef, '<urn:x-me:location>', undef]);
}

if (DONE) {
    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:location>', coord2literal ($c1, 30, 30)],
		 ['<urn:x-me:catbert>',     '<urn:x-me:location>', coord2literal ($c1, 40, 40)],
		 ['<urn:x-me:tomcat>',      '<urn:x-me:location>', coord2literal ($c1, 60, 60)]);
    my @ss = $model->match ([undef, '<urn:x-me:location>', undef]);
    is ((scalar @ss), 3, 'adding location information');

    @ss = $model->inBox ($c1, '<urn:x-me:location>', 0, 0, 35, 35);
    is ((scalar @ss), 1, 'inBox 1');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 35, 35, 65, 65);
    is ((scalar @ss), 2, 'inBox 2');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 65, 65, 75, 75);
    is ((scalar @ss), 0, 'inBox 0');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 35, 35, 65, 65, { limit => 1 });
    is ((scalar @ss), 1, 'inBox limit 2->1');
    
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 30, 30, 1);
    is ((scalar @ss), 1, 'inCircle 1');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 30, 30, 15);
    is ((scalar @ss), 2, 'inCircle 2');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 40, 40, 40);
    is ((scalar @ss), 3, 'inCircle 3');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 40, 40, 40, { limit => 2 });
    is ((scalar @ss), 2, 'inCircle 3->2');

    @ss = $model->inPolygon ($c1, '<urn:x-me:location>', [10,20], [50,20], [50,60]);
    is ((scalar @ss), 2, 'inPolygon 1');

    @ss = $model->inPolygon ($c1, '<urn:x-me:location>', [50,60], [10,20], [50,20]);
    is ((scalar @ss), 2, 'inPolygon 1, rotated');

    @ss = $model->inPolygon ($c1, '<urn:x-me:location>', [10,20], [50,60], [50,20]);
    is ((scalar @ss), 2, 'inPolygon 1, mirrored');

    ok (
	eq_array ([ sort map {$_->[0]} @ss ],
		  [ '<urn:x-me:catbert>', '<urn:x-me:sacklpicker>' ])
	, 'inPolygon 2');
#    warn Dumper \@ss;

    @ss = $model->inPolygon ($c1, '<urn:x-me:location>', [10,20], [50,20], [50,60], { limit => 1 });
    is ((scalar @ss), 1, 'inPolygon 2');
    @ss = $model->inPolygon ($c1, '<urn:x-me:location>', [10,20], [50,20], [50,60], { limit => 0 });
    is ((scalar @ss), 0, 'inPolygon 3');
}

if (1||DONE) {
}

if (0&&DONE) {
    $model->spherical ({ scale => 5, unit => 'degree' });
    $model->add (['<urn:x-me:vienna>', '<urn:x-me:location>', $model->coordinate (45, 15) ]);
    $model->rectangle (25, 50, 0, 50);
}

END {
    $model->disband if $model;
}

__END__

