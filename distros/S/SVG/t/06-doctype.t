use strict;
use warnings;

use Test::More tests => 8;

use SVG ();

# test: -sysid -pubid -docroot

my $svg = SVG->new();

$svg->text->cdata("Document type declaration test");
my $xml = $svg->dtddecl();

ok( $xml, "dtd reclaration" );

like( $xml, qr/DOCTYPE svg /,                       "doctype found" );
like( $xml, qr{ PUBLIC "-//W3C//DTD SVG 1.0//EN" }, "PUBLIC found" );
like( $xml, qr{ "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">},
    "SVG 1.0 TR" );

$svg = SVG->new( -docroot => "mysvg" );
$xml = $svg->dtddecl();

like( $xml, qr/DOCTYPE mysvg /, "DOCTYPE mysvg" );

$svg = SVG->new( -pubid => "-//ROIT Systems/DTD MyCustomDTD 1.0//EN" );

$xml = $svg->dtddecl();
like( $xml, qr{ PUBLIC "-//ROIT Systems/DTD MyCustomDTD 1.0//EN" },
    "pubid 2" );

$svg = SVG->new( -pubid => undef );
$xml = $svg->dtddecl();

like( $xml,
    qr{ SYSTEM "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">},
    "pubid 3" );

$svg = SVG->new( -sysid => "http://www.perlsvg.com/svg/my_custom_svg10.dtd" );
$xml = $svg->dtddecl();
like( $xml, qr{ "http://www.perlsvg.com/svg/my_custom_svg10.dtd">},
    "custom sysid" );

