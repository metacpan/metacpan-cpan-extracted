use strict;
use warnings;
use Test::More tests => 2;

use Object::eBay::Item;

my $item = Object::eBay::Item->new({ item_id => 12345 });
is $item->item_id, 12345, 'item_id method';
is "$item", 12345, 'item_id string context';
