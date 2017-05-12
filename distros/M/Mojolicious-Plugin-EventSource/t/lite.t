use Test::More tests => 29;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/TestApps/lite.pl";

my $t = Test::Mojo->new;

$t->get_ok("/test1")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test1\ndata:\s*ok\n\n/);
$t->get_ok("/test2")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test2\ndata:\s*ok\n\n/);
$t->get_ok("/test3")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test3\ndata:\s*ok\n\n/);
$t->get_ok("/test4")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test4\ndata:\s*ok\n\n/);
$t->get_ok("/test5")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test5\ndata:\s*ok\n\n/);
is($t->app->url_for("bla"), "/test5", "Named EventSource");
$t->get_ok("/test6/42")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test6\ndata:\s*num\n\n/);
$t->get_ok("/test6/ble")->status_is(200)->content_type_is("text/event-stream")->content_like(qr/event:\s*test6\ndata:\s*str\n\n/);

