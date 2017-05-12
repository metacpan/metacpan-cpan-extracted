#! perl -T
#
# Tests for Nitesi::Cart costs.

use strict;
use warnings;

use Test::More tests => 11;

use Nitesi::Cart;

my ($cart, $item, $ret);

$cart = Nitesi::Cart->new;

# fixed amount to empty cart
$cart->apply_cost(amount => 5, name => 'fee');

$ret = $cart->total;
ok($ret == 5, "Total: $ret");

# get cost by position
$ret = $cart->cost(0);
ok($ret == 5, "Total: $ret");

# get cost by name
$ret = $cart->cost('fee');
ok($ret == 5, "Total: $ret");

$cart->clear_cost();

# relative amount to empty cart
$cart->apply_cost(amount => 0.5, relative => 1);

$ret = $cart->total;
ok($ret == 0, "Total: $ret");

$cart->clear_cost;

# relative amount to cart with one item
$item = {sku => 'ABC', name => 'Foobar', price => 22};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$cart->apply_cost(amount => 0.5, relative => 1, name => 'megatax');

$ret = $cart->total;
ok($ret == 33, "Total: $ret");

$ret = $cart->cost(0);
ok($ret == 11, "Cost: $ret");

$ret = $cart->cost('megatax');
ok($ret == 11, "Cost: $ret");

$cart->clear_cost;

# relative and inclusive amount to cart with one item
$cart->apply_cost(amount => 0.5, relative => 1, inclusive => 1,
		  name => 'megatax');

$ret = $cart->total;
ok($ret == 22, "Total: $ret");

$ret = $cart->cost(0);
ok($ret == 11, "Cost: $ret");

$ret = $cart->cost('megatax');
ok($ret == 11, "Cost: $ret");

$cart->clear_cost;
