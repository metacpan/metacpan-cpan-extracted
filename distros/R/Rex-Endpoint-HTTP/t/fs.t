use Mojo::Base -strict;

use Test::More tests => 65;
use Test::Mojo;

my $t = Test::Mojo->new("Rex::Endpoint::HTTP");
$t->post_json_ok("/fs/ls" => { path => "/etc" })->status_is(200)->json_has("/ls")->json_has("/ls")->content_like(qr/passwd/);
$t->post_json_ok("/fs/is_dir" => { path => "/etc" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_dir" => { path => "/tmp/test.txt" })->status_is(200)->json_is("/ok" => 0);
$t->post_json_ok("/fs/is_file" => { path => "/tmp/test.txt" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_file" => { path => "/etc" })->status_is(200)->json_is("/ok" => 0);
$t->post_json_ok("/fs/unlink" => { path => "/tmp/test.txt" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/mkdir" => { path => "/tmp/testdir" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_dir" => { path => "/tmp/testdir" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/stat" => { path => "/tmp/testdir" })->status_is(200)->json_is("/ok" => 1)->json_has("/stat");
$t->post_json_ok("/fs/rmdir" => { path => "/tmp/testdir" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_dir" => { path => "/tmp/testdir" })->status_is(200)->json_is("/ok" => 0);
$t->post_json_ok("/fs/is_readable" => { path => "/etc/passwd" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_writable" => { path => "/tmp" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/ln" => { from => "/etc/passwd", to => "/tmp/pass.wd" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/readlink" => { path => "/tmp/pass.wd" })->status_is(200)->json_is("/ok" => 1)->json_is("/link" => "/etc/passwd");
$t->post_json_ok("/fs/rename" => { old => "/tmp/pass.wd", new => "/tmp/pass.wd2" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/is_file" => { path => "/tmp/pass.wd2" })->status_is(200)->json_is("/ok" => 1);
$t->post_json_ok("/fs/glob" => { glob => "/etc/pass*" })->status_is(200)->json_is("/ok" => 1)->json_has("/glob")->content_like(qr/passwd/);
$t->post_json_ok("/fs/glob" => { glob => "/etc/pass*" })->status_is(200)->json_is("/ok" => 1)->json_has("/glob")->content_like(qr/passwd/);



