use strict;
use warnings;

use Test::More tests => 6;
use SVG;

# test: style

my $svg  = SVG->new;
my $defs = $svg->defs();

# generate an anchor
my $tag0 = $svg->anchor( -href => 'http://here.com/some/simpler/SVG.svg' );

# add a circle to the anchor. The circle can be clicked on.
$tag0->circle( cx => 10, cy => 10, r => 1 );

# more complex anchor with both URL and target
$svg->comment("anchor with: -href, target");
my $tag1 = $svg->anchor(
    -href  => 'http://example.com/some/page.html',
    target => 'new_window_1',
);
$tag1->circle( cx => 10, cy => 10, r => 1 );

$svg->comment("anchor with: -href, -title, -actuate, -show");
my $tag2 = $svg->anchor(
    -href    => 'http://example.com/some/other/page.html',
    -actuate => 'onLoad',
    -title   => 'demotitle',
    -show    => 'embed',
);
$tag2->circle( cx => 10, cy => 10, r => 1 );

my $out = $tag0->xmlify;
like(
    $out,
    qr{http://here\.com/some/simpler/SVG\.svg},
    "anchor 3: xlink href"
);

$out = $tag1->xmlify;
like( $out, qr/target="new_window_1"/, "anchor 4: target" );

$out = $tag2->xmlify;
like( $out, qr/xlink:title="demotitle"/, "anchor 6: title" );
$out = $tag2->xmlify;
like( $out, qr/actuate/, "anchor 7: actuate" );

$out = $tag2->xmlify;
like( $out, qr/xlink:show="embed"/, "anchor 8: show" );

my $tag3 = $svg->a(
    -href  => 'http://example.com/some/page.html',
    -title => 'direct_a_tag',
    target => 'new_window_1',
);

$out = $tag3->xmlify;
like( $out, qr/direct_a_tag/, "anchor 9: direct a method" );

