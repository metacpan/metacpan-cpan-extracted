use strict;
use Test::More 0.98;

use_ok $_ for qw(
    SVG::Fill
);

my $file = SVG::Fill->new( "images/base.svg" );

isa_ok( $file, 'SVG::Fill' );

use DDP;

my $result1 = $file->find_elements('My'); 

ok(@$result1==2,"Elements found");

my $result2 = $file->find_elements('Image'); 
ok(@$result2==1,"Element image found");



done_testing;

