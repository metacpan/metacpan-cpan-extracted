use warnings;
use strict;

use Test::More tests => 8;

use Net::isoHunt;

my $ih = Net::isoHunt->new();
isa_ok( $ih, 'Net::isoHunt' );

my $ih_request = $ih->prepare_request( { 'ihq' => 'ubuntu' } );
isa_ok( $ih_request, 'Net::isoHunt::Request' );

$ih_request->start(21);
$ih_request->rows(20);
$ih_request->sort('seeds');

my $ih_response = $ih_request->execute();
isa_ok( $ih_response, 'Net::isoHunt::Response' );

is( $ih_response->title(), 'isoHunt > All > ubuntu',
                           'title: isoHunt > All > ubuntu' );
is( $ih_response->link(), 'http://isohunt.com', 
                          'link: http://isohunt.com' );
is( $ih_response->description(), 'BitTorrent Search > All > ubuntu',
                                 'description: BitTorrent Search > All > ubuntu' );

subtest 'image' => sub {
    plan tests => 3;

    my $image = $ih_response->image();
    isa_ok( $image, 'Net::isoHunt::Response::Image' );

    is( $image->title(), 'isoHunt > All > ubuntu',
                     'title: isoHunt > All > ubuntu' );
    is( $image->link(), 'http://isohunt.com/', 'link: http://isohunt.com/' );
};

subtest 'item' => sub {
    plan tests => 1;

    my @items = @{ $ih_response->items() };
    my $item  = shift @items;
    isa_ok( $item, 'Net::isoHunt::Response::Item' );
};
