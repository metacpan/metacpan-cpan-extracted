use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tester/lib";

sub _get_routes {
    my $t = shift;

    $t->get_ok('/tester')->status_is(200)->content_is('OK');
    $t->get_ok('/example/tester')->status_is(200)->content_is('OK');
    $t->get_ok('/not-my-route')->status_is(404);
    $t->get_ok('/any')->status_is(200);
    $t->post_ok('/any')->status_is(200);
    $t->post_ok('/post')->status_is(200);
}

$ENV{TEST_DIR} = 1;

my $t = Test::Mojo->new('Tester');

_get_routes($t);

$ENV{TEST_DIR} = 0;
$ENV{TEST_FILE} = 1;

$t = Test::Mojo->new('Tester');

_get_routes($t);

done_testing();
