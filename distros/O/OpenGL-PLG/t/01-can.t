use Test::More tests => 15;

use OpenGL::PLG;

# tests the existance of the API
my $m = 'OpenGL::PLG';
can_ok($m, 'new');

# file manipulation
can_ok($m, 'parse_file');
can_ok($m, 'render');
can_ok($m, 'dump_code');
can_ok($m, 'dump_code_to_file');
can_ok($m, 'write_to_file');

# vertex manipulation
can_ok($m, 'get_vertex');
can_ok($m, 'set_vertex');
can_ok($m, 'set_vertices');
can_ok($m, 'delete_vertex');
can_ok($m, 'total_vertices');

# polygon manipulation
can_ok($m, 'get_polygon');
can_ok($m, 'set_polygon');
can_ok($m, 'delete_polygon');
can_ok($m, 'total_polygons');

