use strict;
use warnings;

use Test::More tests => 2;
use SVG;

# test: fe

my $svg    = SVG->new;
my $parent = $svg->group();
my $child1 = $parent->text->cdata("I am the first child");
my $child2 = $parent->text->cdata("I am the second child");
my $fe     = $svg->fe(
    -type => 'diffuselighting',    # required - element name omitting 'fe'
    id    => 'filter_1',
    style => {
        'font'      => [qw(Arial Helvetica sans)],
        'font-size' => 10,
        'fill'      => 'red',
    },
    transform => 'rotate(-45)'
);

ok( $fe, "fe 1: generation" );
my $out = $svg->xmlify;
like( $out, qr/feDiffuseLighting/, "fe 2: result" );
