use Test::More;
use Test::Mojo;

# Run with MOJO_WEBPACK_RUN=1 prove -vl t/build-assets.t
plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS} or $ENV{TEST_ALL};

# Load the app and make a test object
$ENV{MOJO_MODE}        = 'production';
$ENV{MOJO_WEBPACK_RUN} = 1;
use Mojolicious::Lite;
plugin 'Webpack', {process => [qw(css js)]};
get '/' => 'index';
my $t = Test::Mojo->new;

# Find all the tags and make sure they can be loaded
$t->get_ok('/')->status_is(200);
my $tags = $t->tx->res->dom->find('script[src], link[href][rel=stylesheet]');
$t->element_count_is('script[src], link[href][rel=stylesheet]', 2);
$t->tx->res->dom->find("script[src], link[href][rel=stylesheet]")->each(sub {
  $t->get_ok($_->{href} || $_->{src})->status_is(200);
});

done_testing;

__DATA__
@@ index.html.ep
<html>
<head>
  %= asset "myapp.css"
</head>
<body>
  <h1>Test</h1>
  %= asset "myapp.js"
</body>
</html>
