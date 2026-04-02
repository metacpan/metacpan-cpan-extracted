#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test object module with multiple imports from different object types
# This tests import_accessor and import_accessors across multiple classes

# Define multiple object types and import their accessors in BEGIN block
BEGIN {
    require Object::Proto;

    # Define several object types with different properties
    Object::Proto::define('Person', qw(name age email));
    Object::Proto::define('Address', qw(street city zipcode country));
    Object::Proto::define('Product', qw(sku name price quantity));
    Object::Proto::define('Order', qw(id customer_name total status));
    Object::Proto::define('Config', qw(host port timeout debug));

    # Import accessors from multiple objects
    Object::Proto::import_accessors('Person');     # name, age, email
    Object::Proto::import_accessors('Address');    # street, city, zipcode, country

    # Import specific accessors with aliases to avoid conflicts
    Object::Proto::import_accessor('Product', 'name', 'product_name');
    Object::Proto::import_accessor('Product', 'sku', 'product_sku');
    Object::Proto::import_accessor('Product', 'price', 'price');
    Object::Proto::import_accessor('Product', 'quantity', 'qty');

    Object::Proto::import_accessor('Order', 'id', 'order_id');
    Object::Proto::import_accessor('Order', 'customer_name', 'customer');
    Object::Proto::import_accessor('Order', 'total', 'order_total');
    Object::Proto::import_accessor('Order', 'status', 'order_status');

    Object::Proto::import_accessors('Config');     # host, port, timeout, debug
}

use Object::Proto;

# ============================================
# Basic multi-object access
# ============================================

subtest 'basic multi-object creation and access' => sub {
    my $person = new Person 'Alice', 30, 'alice@example.com';
    my $address = new Address '123 Main St', 'Springfield', '12345', 'USA';

    is(name($person), 'Alice', 'Person name accessor');
    is(age($person), 30, 'Person age accessor');
    is(email($person), 'alice@example.com', 'Person email accessor');

    is(street($address), '123 Main St', 'Address street accessor');
    is(city($address), 'Springfield', 'Address city accessor');
    is(zipcode($address), '12345', 'Address zipcode accessor');
    is(country($address), 'USA', 'Address country accessor');
};

subtest 'aliased accessors for conflicting names' => sub {
    # Product has 'name' which conflicts with Person's 'name'
    my $product = new Product 'SKU001', 'Widget', 9.99, 100;

    is(product_name($product), 'Widget', 'Product name via aliased accessor');
    is(product_sku($product), 'SKU001', 'Product SKU accessor');
    is(price($product), 9.99, 'Product price accessor');
    is(qty($product), 100, 'Product quantity via aliased accessor');
};

subtest 'order accessors with aliases' => sub {
    my $order = new Order 'ORD-123', 'Bob Smith', 150.00, 'pending';

    is(order_id($order), 'ORD-123', 'Order id via alias');
    is(customer($order), 'Bob Smith', 'Order customer via alias');
    is(order_total($order), 150.00, 'Order total via alias');
    is(order_status($order), 'pending', 'Order status via alias');
};

# ============================================
# Setters with multiple imports
# ============================================

subtest 'setters work across multiple objects' => sub {
    my $person = new Person 'Charlie', 25, 'charlie@test.com';
    my $address = new Address '456 Oak Ave', 'Shelbyville', '67890', 'USA';

    # Update using function-style setters
    name($person, 'Charles');
    age($person, 26);

    is(name($person), 'Charles', 'Person name updated');
    is(age($person), 26, 'Person age updated');

    city($address, 'Capital City');
    zipcode($address, '99999');

    is(city($address), 'Capital City', 'Address city updated');
    is(zipcode($address), '99999', 'Address zipcode updated');
};

subtest 'aliased setters work correctly' => sub {
    my $product = new Product 'SKU002', 'Gadget', 19.99, 50;

    product_name($product, 'Super Gadget');
    price($product, 24.99);
    qty($product, 75);

    is(product_name($product), 'Super Gadget', 'Product name updated via alias');
    is(price($product), 24.99, 'Product price updated');
    is(qty($product), 75, 'Product quantity updated via alias');

    # Verify method accessors also see the updates
    is($product->name, 'Super Gadget', 'Method accessor sees alias update');
    is($product->quantity, 75, 'Method accessor sees alias update');
};

# ============================================
# Multiple objects in loops
# ============================================

subtest 'iterate multiple persons with function accessors' => sub {
    my @people = (
        new Person('Alice', 30, 'alice@test.com'),
        new Person('Bob', 25, 'bob@test.com'),
        new Person('Carol', 35, 'carol@test.com'),
    );

    my @names = map { name($_) } @people;
    my @ages = map { age($_) } @people;

    is_deeply(\@names, ['Alice', 'Bob', 'Carol'], 'map names from people');
    is_deeply(\@ages, [30, 25, 35], 'map ages from people');

    # Filter by age
    my @adults = grep { age($_) >= 30 } @people;
    is(scalar(@adults), 2, 'grep filtered adults');
};

subtest 'iterate mixed object types' => sub {
    my @items = (
        new Person('Alice', 30, 'alice@test.com'),
        new Address('123 Main', 'City', '12345', 'USA'),
    );

    # Use method syntax when mixing types
    my @results;
    for my $item (@items) {
        if ($item->isa('Person')) {
            push @results, "Person: " . name($item);
        } elsif ($item->isa('Address')) {
            push @results, "Address: " . city($item);
        }
    }

    is_deeply(\@results, ['Person: Alice', 'Address: City'], 'mixed type iteration');
};

# ============================================
# Complex workflows with multiple objects
# ============================================

subtest 'e-commerce workflow with multiple objects' => sub {
    # Create customer
    my $customer = new Person 'Dave', 40, 'dave@shop.com';

    # Create shipping address
    my $shipping = new Address '789 Pine Rd', 'Anytown', '54321', 'USA';

    # Create products
    my @products = (
        new Product('SKU-A', 'Item A', 10.00, 2),
        new Product('SKU-B', 'Item B', 20.00, 1),
        new Product('SKU-C', 'Item C', 5.00, 4),
    );

    # Calculate order total
    my $total = 0;
    for my $p (@products) {
        $total += price($p) * qty($p);
    }

    # Create order
    my $order = new Order 'ORD-001', name($customer), $total, 'processing';

    is(order_total($order), 60.00, 'Order total calculated correctly');
    is(customer($order), 'Dave', 'Order customer matches person name');

    # Update order status
    order_status($order, 'shipped');
    is(order_status($order), 'shipped', 'Order status updated');
};

subtest 'config management with function accessors' => sub {
    my $dev_config = new Config 'localhost', 3000, 30, 1;
    my $prod_config = new Config 'api.example.com', 443, 60, 0;

    is(host($dev_config), 'localhost', 'dev host');
    is(port($dev_config), 3000, 'dev port');
    is(debug($dev_config), 1, 'dev debug enabled');

    is(host($prod_config), 'api.example.com', 'prod host');
    is(port($prod_config), 443, 'prod port');
    is(debug($prod_config), 0, 'prod debug disabled');

    # Update timeout across configs
    timeout($dev_config, 120);
    timeout($prod_config, 90);

    is(timeout($dev_config), 120, 'dev timeout updated');
    is(timeout($prod_config), 90, 'prod timeout updated');
};

# ============================================
# Simultaneous access to same-named properties
# ============================================

subtest 'same property name different objects' => sub {
    # Both Person and Product have 'name', but Product is aliased
    my $person = new Person 'Eve', 28, 'eve@test.com';
    my $product = new Product 'SKU-X', 'Thingamajig', 15.00, 10;

    # name() is for Person
    is(name($person), 'Eve', 'name() accesses Person');

    # product_name() is for Product
    is(product_name($product), 'Thingamajig', 'product_name() accesses Product');

    # Both objects unchanged by accessing the other
    is(name($person), 'Eve', 'Person name still correct');
    is(product_name($product), 'Thingamajig', 'Product name still correct');
};

# ============================================
# Nested data structures with objects
# ============================================

subtest 'array of objects with function accessors' => sub {
    my @addresses = (
        new Address('111 First St', 'Town A', '11111', 'USA'),
        new Address('222 Second St', 'Town B', '22222', 'USA'),
        new Address('333 Third St', 'Town C', '33333', 'USA'),
    );

    # Extract all cities
    my @cities = map { city($_) } @addresses;
    is_deeply(\@cities, ['Town A', 'Town B', 'Town C'], 'extracted cities');

    # Find address by zipcode
    my ($found) = grep { zipcode($_) eq '22222' } @addresses;
    is(street($found), '222 Second St', 'found address by zipcode');
};

subtest 'hash of objects' => sub {
    my %configs = (
        dev  => new Config('localhost', 3000, 30, 1),
        test => new Config('test.example.com', 8080, 45, 1),
        prod => new Config('api.example.com', 443, 60, 0),
    );

    is(host($configs{dev}), 'localhost', 'hash access dev host');
    is(port($configs{test}), 8080, 'hash access test port');
    is(timeout($configs{prod}), 60, 'hash access prod timeout');

    # Update via hash access
    debug($configs{prod}, 1);  # Enable debug in prod (oops!)
    is(debug($configs{prod}), 1, 'updated via hash access');
};

# ============================================
# Object transformation pipelines
# ============================================

subtest 'transform objects in pipeline' => sub {
    my @people = (
        new Person('alice', 30, 'alice@test.com'),
        new Person('bob', 25, 'bob@test.com'),
        new Person('charlie', 35, 'charlie@test.com'),
    );

    # Capitalize names
    for my $p (@people) {
        name($p, ucfirst(name($p)));
    }

    # Verify each name individually (order may vary due to hash internals)
    is(name($people[0]), 'Alice', 'first name capitalized');
    is(name($people[1]), 'Bob', 'second name capitalized');
    is(name($people[2]), 'Charlie', 'third name capitalized');

    # Increment ages
    for my $p (@people) {
        age($p, age($p) + 1);
    }

    is(age($people[0]), 31, 'first age incremented');
    is(age($people[1]), 26, 'second age incremented');
    is(age($people[2]), 36, 'third age incremented');
};

subtest 'filter and transform products' => sub {
    my @products = (
        new Product('SKU-1', 'Cheap Item', 5.00, 100),
        new Product('SKU-2', 'Mid Item', 25.00, 50),
        new Product('SKU-3', 'Expensive Item', 100.00, 10),
        new Product('SKU-4', 'Another Cheap', 8.00, 80),
    );

    # Find products under $20
    my @cheap = grep { price($_) < 20 } @products;
    is(scalar(@cheap), 2, 'found 2 cheap products');

    # Apply 10% discount to cheap products
    for my $p (@cheap) {
        price($p, price($p) * 0.9);
    }

    # Verify discounts applied (check the specific products, not grep order)
    is(price($products[0]), 4.50, 'SKU-1 (cheap) discounted to 4.50');
    is(price($products[3]), 7.20, 'SKU-4 (cheap) discounted to 7.20');
    is(price($products[1]), 25.00, 'SKU-2 (mid) unchanged');
    is(price($products[2]), 100.00, 'SKU-3 (expensive) unchanged');

    # Calculate total inventory value
    my $total_value = 0;
    for my $p (@products) {
        $total_value += price($p) * qty($p);
    }
    ok($total_value > 0, "total inventory value: $total_value");
};

# ============================================
# Verify no cross-contamination
# ============================================

subtest 'objects remain independent' => sub {
    my $p1 = new Person 'Person One', 20, 'p1@test.com';
    my $p2 = new Person 'Person Two', 30, 'p2@test.com';
    my $a1 = new Address 'Addr One', 'City One', '10000', 'Country One';
    my $a2 = new Address 'Addr Two', 'City Two', '20000', 'Country Two';

    # Modify p1
    name($p1, 'Modified One');

    # Others unchanged
    is(name($p2), 'Person Two', 'p2 name unchanged');
    is(street($a1), 'Addr One', 'a1 street unchanged');
    is(street($a2), 'Addr Two', 'a2 street unchanged');

    # Modify a1
    city($a1, 'Modified City');

    # Others still unchanged
    is(name($p1), 'Modified One', 'p1 name still modified');
    is(name($p2), 'Person Two', 'p2 name still unchanged');
    is(city($a2), 'City Two', 'a2 city unchanged');
};

done_testing();
