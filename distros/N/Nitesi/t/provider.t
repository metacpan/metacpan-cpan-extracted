# test for provider objects

use strict;
use warnings;

use Test::More tests => 1;

use Nitesi::Provider::Object qw/api_object/;

my $product = api_object(class => 'Nitesi::Product',
                         name => 'product');

isa_ok($product, 'Nitesi::Product')
    || diag "Result is: ", ref($product);
