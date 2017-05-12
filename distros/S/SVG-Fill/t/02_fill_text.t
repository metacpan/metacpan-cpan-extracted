use strict;
use Test::More 0.98;

use_ok $_ for qw(
    SVG::Fill
);

my $file = SVG::Fill->new( "images/base.svg" );

isa_ok( $file, 'SVG::Fill' );

$file->fill_text("#MyText","Hello World!!!");

$file->save('output.svg');

done_testing;

