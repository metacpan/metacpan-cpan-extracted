use strict;
use warnings;
use Test::More;
use Object::eBay;

my %tests = (
    Quantity       => 'quantity',
    Title          => 'title',
    SellingStatus  => 'selling_status',
    ListingDetails => 'listing_details',
    ItemID         => 'item_id',
);

plan tests => 2*(scalar keys %tests);

while ( my ($ebay, $method) = each %tests ) { 
    is(
        Object::eBay->ebay_name_to_method_name($ebay),
        $method,
        "$ebay -> $method",
    );

    is(
        Object::eBay->method_name_to_ebay_name($method),
        $ebay,
        "$method -> $ebay",
    );
}
