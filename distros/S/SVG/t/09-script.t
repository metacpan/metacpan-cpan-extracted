use strict;
use warnings;

use Test::More tests => 8;
use SVG;

my $svg = SVG->new;

my $tag = $svg->script( type => "text/ecmascript" );

# populate the script tag with cdata
# be careful to manage the javascript line ends.
# qq│text│ or qq§text§ where text is the script
# works well for this.

$tag->CDATA(
    qq|
function d(){
//simple display function
for(cnt = 0; cnt < d.length; cnt++)
document.write(d[cnt]);//end for loop
document.write("<hr>");//write a line break
document.write('<br>');//write a horizontal rule
}|
);

ok( $tag, "create script element" );
my $out = $svg->xmlify;

like( $out, qr{"text/ecmascript"}, "specify script type" );
like( $out, qr/function/,          "generate script content" );
like( $out, qr/'<br>'/,            "handle single quotes" );
like( $out, qr/"<hr>/,             "handle double quotes" );

#test for adding scripting commands in an element

$out = $svg->xmlify;

my $rect = $svg->rect(
    x       => 10,
    y       => 10,
    fill    => 'red',
    stroke  => 'black',
    width   => '10',
    height  => '10',
    onclick => "alert('hello'+' '+'world')"
);

$out = $rect->xmlify;

like( $out, qr/'hello'/, 'mouse event' );
like( $out, qr/'world'/, "mouse event script call" );

$svg = new SVG;
$svg->script()->CDATA("TESTTESTTEST");
$out = $svg->xmlify;
chomp $out;

like(
    $out,
    qr/<script\s*><!\[CDATA\[TESTTESTTEST\]\]>\s*<\/script>/,
    "script without type"
);

