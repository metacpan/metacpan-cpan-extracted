use Test::More tests => 11;

use strict;
use warnings;
use FindBin;

use lib $FindBin::Bin . '/lib';

use_ok( 'Farm::Cow' );

isa_ok( my $cow = Farm::Cow->new(), 'Farm::Cow' );

is( $cow->render, "This cow has 8 spots and goes Moooooooo!\n",
    'default render' );

my $xml = <<"_XML";
<cow sound="Moooooooo" spots="8">
  <hobby name="mooing"/>
  <hobby name="chewing"/>
</cow>
_XML

my $summary = <<"_SUMMARY";

This cow has 8 spots. It mostly spends its time
mooing and chewing. When it is very happy
it exclaims, "Moooooooo!".

_SUMMARY

my $html = "<h1>Cow</h1><p>$summary</p>";

is( $cow->render( source => 'summary' ),
    $summary,
    'render method shortcut (summary)');

is( $cow->render( source => 'html' ),
    $html,
    'render method shortcut (html)');

is( $cow->render( source => 'hTmL' ),
    $html,
    'render method shortcut (hTmL)');

is( $cow->render( source => 'XML' ),
    $xml,
    'render file shortcut (XML)');

is( $cow->render( source => 'XmL' ),
    $xml,
    'render file shortcut (XmL)');

is( $cow->render( source => $FindBin::Bin . '/lib/Farm/Cow.tt' ),
    "This cow has 8 spots and goes Moooooooo!\n",
    'render from file path');

eval { $cow->render( source => "[% self.moo %]!" ) };
like( $@, qr/\[error\]/, "error if couldn't find source" );

is( $cow->render( source => \"[% self.moo %]! [% self.moo %]!!" ),
    "Moooooooo! Moooooooo!!",
    'render from raw text');
