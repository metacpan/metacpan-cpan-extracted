use strict;
use warnings;

use Test::More tests => 20;

use Routes::Tiny;

my $r = Routes::Tiny->new;

$r->add_route(':year(/:month/:day)?', name => 'route');

my $m = $r->match('2009');
is_deeply($m->params, {year => 2009, month => undef, day => undef});
is($r->build_path('route', year => 2009), '/2009');

$m = $r->match('2009/12/10');
is_deeply($m->params, {year => 2009, month => 12, day => 10});
is($r->build_path('route', year => 2009, month => 12, day => 10),
    '/2009/12/10');


$r = Routes::Tiny->new;
$r->add_route(':year(/:month)?/:day', name => 'route');

$m = $r->match('2009/12');
is_deeply($m->params, {year => 2009, month => undef, day => 12});
is($r->build_path('route', year => 2009, day => 12), '/2009/12');

$m = $r->match('2009/12/2');
is_deeply($m->params, {year => 2009, month => 12, day => 2});
is($r->build_path('route', year => 2009, month => 12, day => 2),
    '/2009/12/2');


$r = Routes::Tiny->new;
$r->add_route(':year/(:month)?/:day', name => 'route');

$m = $r->match('2009/12');
ok(!$m);

$m = $r->match('2009/12/2');
is_deeply($m->params, {year => 2009, month => 12, day => 2});
is($r->build_path('route', year => 2009, month => 12, day => 2),
    '/2009/12/2');

$m = $r->match('2009//2');
is_deeply($m->params, {year => 2009, month => undef, day => 2});
TODO: {
    local $TODO = "Fix empty part";
    is($r->build_path('route', year => 2009, day => 2), '/2009//2');
}


$r = Routes::Tiny->new;
$r->add_route(':year/month(:month)?/:day', name => 'route');

$m = $r->match('2009/12/2');
ok(!$m);

$m = $r->match('2009/month/2');
is_deeply($m->params, {year => 2009, month => undef, day => 2});
is($r->build_path('route', year => 2009, day => 2), '/2009/month/2');

$m = $r->match('2009/month08/2');
is_deeply($m->params, {year => 2009, month => '08', day => 2});
is($r->build_path('route', year => 2009, month => '08', day => 2),
    '/2009/month08/2');

$r = Routes::Tiny->new;
$r->add_route('(/:year)?/:month/:day', name => 'route');

$m = $r->match('/2009/12/2');
is_deeply($m->params, {year => 2009, month => 12, day => 2});

$m = $r->match('/12/2');
is_deeply($m->params, {year => undef, month => 12, day => 2});
