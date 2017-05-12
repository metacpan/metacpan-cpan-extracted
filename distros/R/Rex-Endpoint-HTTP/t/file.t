use Mojo::Base -strict;

use Test::More tests => 19;
use Test::Mojo;

my $t = Test::Mojo->new("Rex::Endpoint::HTTP");

unlink("/tmp/test.txt") if (-f "/tmp/test.txt");

$t->post_json_ok("/file/open" => { mode => "<", path => "/etc/passwd" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/file/open" => { mode => ">", path => "/tmp/test.txt" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/file/close" => {})->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/file/write_fh" => { path => "/tmp/test.txt", start => 0, buf => "aGk=" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/file/read" => { path => "/tmp/test.txt", len => 200, start => 0 })->status_is(200)->json_is("/ok" => 1)->json_is("/buf" => "aGk=\n");
$t->post_json_ok("/file/seek" => {})->status_is(200)->json_is("/ok" => 1);

