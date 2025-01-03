use strict;
use utf8;
use Test::More;
use Poz qw/z/;
use Time::Piece ();

# Create a substitute for new Date()
my $new_date = sub {
  Time::Piece::localtime->strftime('%Y-%m-%dT%H:%M:%SZ');
};

# Schema for a single item
my $item_schema = z->object({
  # Item name. Limited to 30 characters for convenience
  name => z->string->max(30), 
  # Item price. Limited to 100,000 yen for convenience
  price => z->number->min(0)->max(100000), 
})->as('BurgerShop::Item');

# Schema for an order
my $order_schema = z->object({
  # Item object. Represents which item is being ordered
  item => $item_schema, 
  # Number of items ordered. Up to 20 of the same item can be ordered at once
  amounts => z->number->min(1)->max(20), 
})->as('BurgerShop::Order');

# Schema for staff
my $staff_schema = z->object({
  # Staff ID
  id => z->number->min(1), 
  # Staff name. Limited to 30 characters for convenience
  name => z->string->max(30), 
})->as('BurgerShop::Staff');

# Schema for a receipt
my $receipt_schema = z->object({
  # Table number. Assuming a store with tables numbered 1 to 45
  table_number => z->number->min(1)->max(45), 
  # List of orders
  orders => z->array($order_schema),
  # Record of the date and time the order was placed. Defaults to the current time
  ordered_at => z->datetime->default(sub { $new_date->() }), 
  # Staff who took the order
  staff => $staff_schema,
})->as('BurgerShop::Receipt');

# Test data
my $test_data = {
  table_number => 10,
  orders => [
    {
      item => {
        name => 'Cheeseburger',
        price => 250,
      },
      amounts => 2,
    },
    {
      item => {
        name => 'Fries',
        price => 150,
      },
      amounts => 1,
    },
  ],
  staff => {
    id => 1,
    name => 'Taro Yamada',
  },
};

# Validate test data
my ($result, $error) = $receipt_schema->safe_parse($test_data);

# Test results
is($error, undef, 'expected no error');
is($result->{table_number}, 10, 'table_number is 10');

for my $order (@{$result->{orders}}) {
  isa_ok($order, 'BurgerShop::Order', 'order is BurgerShop::Order: got '. ref($order));
}
is_deeply($result->{orders}, [
  bless({
    item => {
      name => 'Cheeseburger',
      price => 250,
    },
    amounts => 2,
  }, 'BurgerShop::Order'),
  bless({
    item => {
      name => 'Fries',
      price => 150,
    },
    amounts => 1,
  }, 'BurgerShop::Order'),
], 'orders is correct');
isa_ok($result->{staff}, 'BurgerShop::Staff', 'staff is BurgerShop::Staff: got '. ref($result->{staff}));
is_deeply($result->{staff}, bless({
  id => 1,
  name => 'Taro Yamada',
}, 'BurgerShop::Staff'), 'staff is correct');
like($result->{ordered_at}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'ordered_at is correct');

my $is_burger_shop_receipt_schema = z->is('BurgerShop::Receipt');
is($is_burger_shop_receipt_schema->parse($result), $result, 'BurgerShop::Receipt');

done_testing;