use Test::More tests => 31;
#TODO: test all exceptions
#TODO: file manipulation tests

use OpenGL::PLG;

my $plg = OpenGL::PLG->new();

isa_ok($plg, 'OpenGL::PLG');

# check if we can add vertices in any order
$plg->set_vertex(-1.0, -1.0, 0.0, 3 );
$plg->set_vertex( 1.0, -1.0, 0.0, 2 );
$plg->set_vertex( 0.0,  1.0, 0.0, 1 );

# were the vertices added correctly?
my @a = $plg->get_vertex(1);
is_deeply(\@a, [0.0, 1.0, 0.0], 'get vertex');

@a = $plg->get_vertex(3);
is_deeply(\@a, [-1.0, -1.0, 0.0], 'get vertex');

@a = $plg->get_vertex(2);
is_deeply(\@a, [1.0, -1.0, 0.0], 'get vertex');


# check for exceptions
eval { $plg->set_polygon(1, 1,2) };
like($@, qr/error reading polygon input. Expected 1 vertices but got 2 instead./, 'inserting polygon with mismatching (smaller) number of vertices');

eval { $plg->set_polygon(2, 1) };
like($@, qr/error reading polygon input. Expected 2 vertices but got 1 instead./, 'inserting polygon with mismatching (larger) number of vertices');

eval { $plg->set_vertex(1.0) };
like($@, qr/vertices must have all three coordinates \(x, y, z\)/, 'inserting invalid vertex coordinates (x only)');

eval { $plg->set_vertex(1.0, 1.0) };
like($@, qr/vertices must have all three coordinates \(x, y, z\)/, 'inserting invalid vertex coordinates (x and y only)');

eval { $plg->set_vertex(1.0, 1.0, 1.0, 0) };
like($@, qr/vertex id cannot be zero/, 'inserting vertex in invalid position');

eval { $plg->set_vertices( { 0 => [1.0, 1.0, 1.0] } ) };
like($@, qr/vertex id cannot be zero/, 'inserting vertex in invalid position');

eval { $plg->get_vertices_from_polygon(0) };
like($@, qr/polygon id cannot be zero/, 'invalid polygon id');

eval { $plg->get_vertices_from_polygon(1) };
like($@, qr/get_polygon needs a loaded polygon id/, 'non-existant polygon id');

eval { $plg->get_vertex(0) };
like($@, qr/vertex id cannot be zero/, 'invalid vertex id');

eval { $plg->get_vertex(9) };
like($@, qr/get_vertex needs a loaded vertex id/, 'non-existant vertex id');

eval { $plg->get_polygon(0) };
like($@, qr/polygon id cannot be zero/, 'invalid polygon id');

eval { $plg->get_polygon(1) };
like($@, qr/get_polygon needs a loaded polygon id/, 'non-existant polygon');

eval { $plg->delete_vertex(0) };
like($@, qr/vertex id cannot be zero/, 'deleting invalid vertex');

eval { $plg->delete_vertex(15) };
like($@, qr/delete_vertex needs a loaded vertex id/, 'deleting non-existant vertex');

eval { $plg->delete_polygon(0) };
like($@, qr/polygon id cannot be zero/, 'deleting invalid polygon');

eval { $plg->delete_polygon(1) };
like($@, qr/delete_polygon needs a loaded polygon id/, 'deleting non-existant polygon');


# lets delete vertex 1 and see how it goes:
$plg->delete_vertex(1);

# now vertex 3 should not be there
# (as everything is shifted left after a deletion)
eval { $plg->get_vertex(3) };
like($@, qr/get_vertex needs a loaded vertex id/, 'non-existant vertex');

# Ok, lets now try to add vertices in 'batch' mode
# overwriting previous values (1,2) and setting
# new ones (3)
$plg->set_vertices( {
        1 => [ 0.0,  1.0, 0.0],
        2 => [ 1.0, -1.0, 0.0],
        3 => [-1.0, -1.0, 0.0],
    });

# try to add a vertex using the three-form way (no id)
$plg->set_vertex(1.0, 0.5, 1.0);

# try to get them again to see if everything went smoothly
my @a = $plg->get_vertex(1);
is_deeply(\@a, [0.0, 1.0, 0.0], 'get vertex');

@a = $plg->get_vertex(3);
is_deeply(\@a, [-1.0, -1.0, 0.0], 'get vertex');

@a = $plg->get_vertex(2);
is_deeply(\@a, [1.0, -1.0, 0.0], 'get vertex');

@a = $plg->get_vertex(4);
is_deeply(\@a, [1.0, 0.5, 1.0], 'get_vertex');

# ok, let's create a triangle!
$plg->set_polygon(3, 1,2,3);

my $ref = $plg->get_vertices_from_polygon(1);
my $ref_ok = [
     [ 0.0,  1.0, 0.0],
     [ 1.0, -1.0, 0.0],
     [-1.0, -1.0, 0.0],
    ];

is_deeply($ref, $ref_ok, 'get vertices from polygon');

$plg->set_polygon(2, 1, 4);
my @b = $plg->get_polygon(1);
is_deeply(\@b, [1, 2, 3], 'get polygon');

my @b = $plg->get_polygon(2);
is_deeply(\@b, [1, 4], 'get polygon');

# if we delete the first polygon, number 2 will become number 1
$plg->delete_polygon(1);
eval { $plg->get_polygon(2) };
like($@, qr/get_polygon needs a loaded polygon id/, 'non-existant polygon');

@b = $plg->get_polygon(1);
is_deeply(\@b, [1, 4], 'get polygon');


# ok, so we have a few vertices and a polygon that
# uses a couple of them (1 and 4).
my $code = $plg->dump_code();
my $code_ok = <<'EOCODE';
glBegin(GL_POLYGON);
  glVertex3f(0, 1, 0);
  glVertex3f(1, 0.5, 1);
glEnd();
EOCODE
is($code, $code_ok, 'dump code');








