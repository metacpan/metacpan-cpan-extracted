use strict;
use warnings;

use Test::More tests => 10;

use Routes::Tiny;

my $r = Routes::Tiny->new;
$r->add_route('/admin/', name => 'route');

my $m = $r->match('/admin');
ok(!$m);

$m = $r->match('/admin/');
ok($m);
is($r->build_path('route'), '/admin/');

$r = Routes::Tiny->new;
$r->add_route('/admin/:service(/:action)?', name => 'route');

$m = $r->match('/admin/foo');
ok($m);
is($r->build_path('route', service => 'foo'), '/admin/foo');

$m = $r->match('/admin/foo/bar');
ok($m);
is($r->build_path('route', service => 'foo', action => 'bar'),
    '/admin/foo/bar');

$r = Routes::Tiny->new;
$r->add_route('/admin/:service/(:action)?', name => 'route');

$m = $r->match('/admin/foo');
ok(!$m);

$m = $r->match('/admin/foo/');
ok($m);
is($r->build_path('route', service => 'foo'), '/admin/foo/');
