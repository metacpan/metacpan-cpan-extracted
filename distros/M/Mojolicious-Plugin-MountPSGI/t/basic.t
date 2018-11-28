use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

app->mode('test');

plugin 'MountPSGI', { '/' => 't/script/basic.psgi' };


my $t = Test::Mojo->new;
$t->get_ok('/foo', {'X-Extra-Header' => 'ok'})
  ->status_is(200)
  ->header_is('X-Extra-Reply' => 'ok')
  ->header_is('X-Load-Mode' => 'test')
  ->header_is('X-Req-Mode'  => 'test')
  ->content_is("hello, world\n");

done_testing;

