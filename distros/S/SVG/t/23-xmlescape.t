use strict;
use warnings;

use Test::More tests => 14;

use SVG ( -printerror => 0, -raiseerror => 0 );

# test: special characters

my $bad_chars = '><!&';
my $esc_chars = '&gt;&lt;!&amp';
my $svg       = SVG->new;

ok( my $out1 = $svg->text()->cdata_noxmlesc( $svg->xmlescp($bad_chars) ),
    "Testing toxic characters to xmlescp" );

like( $out1->xmlify(), qr/$esc_chars/, 'Toxic chars are escaped' );
ok(
    my $out2 = $svg->text()->cdata($bad_chars),
    "Testing toxic characters to cdata"
);
like( $out2->xmlify(), qr/$esc_chars/, 'Toxic chars are escaped' );

$bad_chars = "Line one\nLine two";
$esc_chars = "Line one\nLine two";
ok( my $out3 = $svg->text()->cdata($bad_chars),
    'Testing new line characters' );
like( $out3->xmlify(), qr/$esc_chars/, 'New lines are allowed' );

$bad_chars = "Col1\tcol2";
$esc_chars = "Col1\tcol2";
ok( my $out4 = $svg->text()->cdata($bad_chars), 'Testing tab characters' );
like( $out4->xmlify(), qr/$esc_chars/, 'Tabs are allowed' );

$bad_chars = '`backticks`';
$esc_chars = '`backticks`';
ok( my $out5 = $svg->text()->cdata($bad_chars), 'Testing backticks' );
like( $out5->xmlify(), qr/$esc_chars/, 'Backticks are ok' );

$bad_chars
    = "Remove these: \x01, \x02, \x03, \x04, \x05, \x06, \x07, \x08, \x0b, \x1f";
$esc_chars = 'Remove these: , , , , , , , , , ';
ok( my $out6 = $svg->text()->cdata($bad_chars),
    'Testing restricted characters' );
like( $out6->xmlify(), qr/$esc_chars/, 'Restricted characters removed' );

$bad_chars = '[@hkb:536:8bp]: hkb-536';
$esc_chars = '\[@hkb:536:8bp\]: hkb-536';
ok( my $out7 = $svg->text()->cdata($bad_chars), 'More weird input' );
like( $out7->xmlify(), qr/$esc_chars/ );

