use strict;
use warnings;

use Test::More tests => 6;
use SVG;

my $svg = SVG->new;
diag "add circle";
my $e = $svg->circle();
isa_ok $e, 'SVG::Element';
my $output = $svg->render();
ok( $output, "nonempty output of render" );
like $output, qr{<\?xml version="1.0" encoding="UTF-8" standalone="yes"\?>};
like $output,
    qr{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">};
like $output,
    qr{<svg height="100%" width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">};
like $output, qr{<circle />};
