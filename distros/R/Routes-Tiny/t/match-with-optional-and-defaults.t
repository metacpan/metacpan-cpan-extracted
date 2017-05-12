use strict;
use warnings;

use Test::More tests => 6;

use Routes::Tiny;

my $r = Routes::Tiny->new;

$r->add_route(
    '/admin/:service(/:action)?',
    name     => 'route',
    defaults => {action => 'list'}
);

my $m = $r->match('/admin/foo');
is_deeply($m->params, {service => 'foo', action => 'list'});
is($r->build_path('route', service => 'foo'), '/admin/foo');

$m = $r->match('/admin/foo/bar');
is_deeply($m->params, {service => 'foo', action => 'bar'});
is($r->build_path('route', service => 'foo', action => 'bar'),
    '/admin/foo/bar');

$m = $r->match('/admin/bar');
is_deeply($m->params, {service => 'bar', action => 'list'});
is($r->build_path('route', service => 'bar'), '/admin/bar');
