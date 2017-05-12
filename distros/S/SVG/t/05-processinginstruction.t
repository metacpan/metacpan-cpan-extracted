use strict;
use warnings;

use Test::More tests => 9;
use SVG;

my $svg = SVG->new( width => 100, height => 100 );

my $pi = $svg->pi( "Hello world", "I am a PI" );
ok( $pi, "PI: add 2 arbitrary processing instructions" );

ok(
    $svg->rect(
        x      => 0,
        y      => 0,
        width  => 10,
        height => 10,
        fill   => 'red',
        stroke => 'brick'
    ),
    "add a drawing element"
);

$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);
$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);
$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);
$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);
$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);
$svg->rect(
    x      => 0,
    y      => 0,
    width  => 10,
    height => 10,
    fill   => 'red',
    stroke => 'brick'
);

my $xml = $svg->xmlify();
ok( $xml, "serialize the svg" );
like( $xml, qr/<\?Hello\sworld\?>/,
    "serialize arbitrary processing instruction 1" );
like( $xml, qr/<\?I\sam\sa\sPI\?>/,
    "serialize arbitrary processing instruction 2" );

like( $xml, qr/rect/, "PI 2: add non-PI elements" );
is( scalar @{ $svg->pi }, 2, "PI 3 - fetch PI array" );

$svg->pi("Third PI entry");
$xml = $svg->xmlify();
like( $xml, qr/<\?Third\sPI\sentry\?>/, "pi 2" );
is( scalar @{ $svg->pi }, 3, "PI 3" );

