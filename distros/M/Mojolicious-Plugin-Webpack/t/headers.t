use Test::More;
use Test::Mojo;

# Run with MOJO_WEBPACK_BUILD=1 prove -vl t/build-assets.t
plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS} or $ENV{TEST_ALL};

# Load the app and make a test object
$ENV{MOJO_MODE}          = 'production';
$ENV{MOJO_WEBPACK_BUILD} = 1;
use Mojolicious::Lite;
plugin 'Webpack', {process => [qw(css js)]};
get '/' => 'index';
my $t = Test::Mojo->new;

# Find all the tags and make sure they can be loaded
$t->get_ok('/')->status_is(200);

my $css = $t->tx->res->dom->at('link[href][rel=stylesheet]');
my $js  = $t->tx->res->dom->at('script[src]');
$t->get_ok($css->{href})->status_is(200)->header_is('Cache-Control', 'max-age=86400');
$t->get_ok($js->{src})->status_is(200)->header_is('Cache-Control', 'max-age=86400');
$t->get_ok('/no-max-age.txt')->status_is(200)->header_isnt('Cache-Control', 'max-age=86400');

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
