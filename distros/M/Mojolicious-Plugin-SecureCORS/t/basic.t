use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;


$ENV{MOJO_LOG_LEVEL} = 'warn';
app->secrets('fuckoff');

my $t = Test::Mojo->new(app);

plugin 'SecureCORS';
my $r = app->routes;

$r->get('/' => {text=>'root'});

my $strict = $r->under_strict_cors('/users/');
$strict->get({'cors.origin'=>'*', text=>'list users'});
$strict->post({text=>'add user'});

my ($r1, $r2);
$r = $r->route('/a')->to('cors.headers' => 'X-Requested-With');
$r = $r->route('/b');
$r = $r->route('/c')->to('cors.credentials' => 1);
$r1 = $r->route('/d1')->to('cors.credentials' => undef);
$r2 = $r->route('/d2');
$r2->cors('(*path)')->to(path=>undef);
$r1->get('/e1', {'cors.origin'=>'http://localhost null', text=>'E1'});
$r2->put('/e2', {'cors.origin'=>qr/\.local\z/, text=>'E2'});
$r2->get('/e3', {text=>'E3'});


$t->get_ok('/')
    ->status_is(200)
    ->content_is('root');
$t->get_ok('/', {'Origin' => 'null'})
    ->status_is(200)
    ->content_is('root');

$t->get_ok('/users/')
    ->status_is(200)
    ->content_is('list users');
$t->get_ok('/users/', {'Origin' => 'null'})
    ->status_is(200)
    ->content_is('list users');
$t->post_ok('/users/')
    ->status_is(200)
    ->content_is('add user');
$t->post_ok('/users/', {'Origin' => 'null'})
    ->status_is(403)
    ->content_is('CORS Forbidden');

$t->options_ok('/a/b/c/d1/e1')
    ->status_is(404);
$t->options_ok('/a/b/c/d2/e2')
    ->status_is(404);
$t->options_ok('/a/b/c/d1/e1', {'Origin'=>'http://ya.ru','Access-Control-Request-Method'=>'GET'})
    ->status_is(404);
$t->options_ok('/a/b/c/d2/e2', {'Origin'=>'http://ya.ru','Access-Control-Request-Method'=>'GET'})
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);
$t->options_ok('/a/b/c/d2/e2', {'Origin'=>'http://ya.ru','Access-Control-Request-Method'=>'PUT'})
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);
$t->options_ok('/a/b/c/d2/e2', {'Origin'=>'http://ya.local','Access-Control-Request-Method'=>'GET'})
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);
$t->options_ok('/a/b/c/d2/e2', {'Origin'=>'http://ya.local','Access-Control-Request-Method'=>'PUT'})
    ->header_is('Access-Control-Allow-Origin', 'http://ya.local')
    ->status_is(204);
$t->options_ok('/a/b/c/d2', {'Origin'=>'http://ya.local','Access-Control-Request-Method'=>'PUT'})
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);

$t->options_ok('/a/b/c/d2/e2', {
        'Origin'                            => 'http://ya.local',
        'Access-Control-Request-Method'     => 'PUT',
        'Access-Control-Request-Headers'    => 'X-Custom',
    })
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);
$t->options_ok('/a/b/c/d2/e2', {
        'Origin'                            => 'http://ya.local',
        'Access-Control-Request-Method'     => 'PUT',
        'Access-Control-Request-Headers'    => 'X-Requested-With',
    })
    ->header_is('Access-Control-Allow-Origin', 'http://ya.local')
    ->header_is('Access-Control-Allow-Methods', 'PUT')
    ->header_is('Access-Control-Allow-Headers', 'X-Requested-With')
    ->header_is('Access-Control-Allow-Credentials', 'true')
    ->status_is(204);
$t->options_ok('/a/b/c/d2/e3', {
        'Origin'                            => 'http://ya.local',
        'Access-Control-Request-Method'     => 'PUT',
        'Access-Control-Request-Headers'    => 'X-Requested-With',
    })
    ->header_is('Access-Control-Allow-Origin', undef)
    ->status_is(204);

$t->get_ok('/a/b/c/d1/e1')
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', undef)
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E1');
$t->get_ok('/a/b/c/d1/e1', {'Origin'=>'http://ya.ru'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', undef)
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E1');
$t->get_ok('/a/b/c/d1/e1', {'Origin'=>'http://localhost'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', 'http://localhost')
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E1');
$t->get_ok('/a/b/c/d1/e1', {'Origin'=>'null'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', 'null')
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E1');
$t->put_ok('/a/b/c/d2/e2', {'Origin'=>'null'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', undef)
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E2');
$t->put_ok('/a/b/c/d2/e2', {'Origin'=>'http://ya.local'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', 'http://ya.local')
    ->header_is('Access-Control-Allow-Credentials', 'true')
    ->content_is('E2');
$t->get_ok('/a/b/c/d2/e3', {'Origin'=>'http://ya.local'})
    ->status_is(200)
    ->header_is('Access-Control-Allow-Origin', undef)
    ->header_is('Access-Control-Allow-Credentials', undef)
    ->content_is('E3');


done_testing();
# app->start('routes');

