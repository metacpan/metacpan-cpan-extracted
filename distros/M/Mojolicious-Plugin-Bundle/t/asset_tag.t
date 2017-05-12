use Test::More qw/no_plan/;
use Test::Mojo;
use File::Spec::Functions;
use FindBin;
use lib "$FindBin::Bin/lib/product/lib";

BEGIN {
    $ENV{MOJO_LOG_LEVEL} ||= 'fatal';
}

use_ok('product');
my $test = Test::Mojo->new( app => 'product' );
my $app = $test->get_ok('/product');
$app->status_is(200);
$app->content_like( qr/list of product/, 'It shows the list of product' );
$app->element_exists(
    'html head script[src="/javascripts/biolib.js"]',
    'It has javascript source via javascript_link_tag'
);
$app->element_exists( 'html head script[src^="/javascripts/fun.js?"]',
    'It has javascript source via javascript_link_tag with asset id' );
$app->element_exists(
    'html head script[src^="/javascripts/custom/jumper.js?"]',
    'It has javascript source via javascript_path with asset id'
);

$app->element_exists(
    'html head link[href="/stylesheets/biostyle.css"]',
    'It has stylesheet link via stylesheet_link tag'
);
$app->element_exists(
    'html head link[href^="/stylesheets/monkey.css?"]',
    'It has stylesheet link via stylesheet_link_tag with asset id'
);
$app->element_exists(
    'html head link[href^="/stylesheets/custom/jumbo.css?"]',
    'It has stylesheet link via stylesheet_path helper'
);

$app->element_exists(
    'body img[src="/images/bioimage.png"]',
    'It has bioimage.png as image source'
);
$app->element_exists(
    'body img[src^="/images/mojolicious-black.png?"]',
    'It has mojolicious logo with asset tag'
);
$app->element_exists(
    'body img[alt="Mojolicious-black"]',
    'It has mojolicious logo with alt attribute'
);
$app->element_exists(
    'body a[id="size"] img[width="10"][height="10"]',
    'It has mojolicious logo with height attribute'
);
$app->element_exists(
    'body a[id="options"] img[width="10"][class="mojo"][id="foo"][border="1"]',
    'It has mojolicious image logo with various attributes'
);
$app->element_exists(
    'body a[id="custom"][href^="/images/custom"]',
    'It has mojolicious logo with custom href url'
);

$app->element_exists(
    'body a[id="withttp"][href^="http://images"]',
    'It has mojolicious logo with passthrough http url'
);

use_ok('byproduct');
$test = Test::Mojo->new( app => 'byproduct' );
my $app2 = $test->get_ok('/product');
$app2->status_is(200);
$app2->content_like( qr/list of product/, 'It shows the list of product' );
$app2->element_exists(
    'html head script[src="/tucker/javascripts/biolib.js"]',
    'It has javascript link with relative url' );
$app2->element_exists(
    'html head script[src^="/tucker/javascripts/fun.js?"]',
    'It has relative javascript source via javascript_link_tag with asset id'
);
$app2->element_exists(
    'html head script[src^="/tucker/javascripts/custom/jumper.js?"]',
    'It has relative javascript source via javascript_path with asset id'
);

$app2->element_exists(
    'body img[src="/tucker/images/bioimage.png"]',
    'It has  bioimage.png as image source with relative url'
);
$app2->element_exists(
    'body img[src^="/tucker/images/mojolicious-black.png?"]',
    'It has mojolicious logo with asset tag with relative url'
);
$app2->element_exists( 'body a[id="size"] img[width="10"][height="10"]',
    'It has mojolicious logo with height attribute with relative url set' );
$app2->element_exists(
    'body a[id="options"] img[width="10"][class="mojo"][id="foo"][border="1"]',
    'It has mojolicious image logo with various attributes with relative url set'
);
$app2->element_exists(
    'body a[id="custom"][href^="/tucker/images/custom"]',
    'It has mojolicious logo with custom href including relative url'
);
