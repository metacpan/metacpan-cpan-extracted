use Test::More;
use Test::Mojo;

# Run with TEST_BUILD_ASSETS=1 prove -vl t/build-assets.t
plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS};

# Load the app and make a test object
$ENV{MOJO_MODE}          = 'production';
$ENV{MOJO_WEBPACK_BUILD} = 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
require "$FindBin::Bin/../example/webpack/lite.pl";
my $t = Test::Mojo->new;

# Find all the tags and make sure they can be loaded
$t->get_ok("/")->status_is(200);
$t->element_count_is('script[src], link[href][rel=stylesheet]', 2);
$t->tx->res->dom->find("script[src], link[href][rel=stylesheet]")->each(sub {
  $t->get_ok($_->{href} || $_->{src})->status_is(200);
});

done_testing;