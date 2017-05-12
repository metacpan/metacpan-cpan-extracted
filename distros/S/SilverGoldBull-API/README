[![Build Status](https://travis-ci.org/dboys/SilverGoldBull-API.png?branch=master)](https://travis-ci.org/dboys/SilverGoldBull-API)


# NAME

SilverGoldBull::API - Perl client for the SilverGoldBull(https://silvergoldbull.com/) web service

# VERSION

version 0.01

# INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

# SYNOPSIS
    use SilverGoldBull::API;
    use SilverGoldBull::API::BillingAddress;
    use SilverGoldBull::API::ShippingAddress;
    use SilverGoldBull::API::Item;
    use SilverGoldBull::API::Order;

    my $sgb = SilverGoldBull::API->new(api_key => <API_KEY>);#or use SILVERGOLDBULL_API_KEY env variable
    
    #get available currency list
    my $response = $sgb->get_currency_list();
    if ($response->is_success) {
        my $currency_list = $response->data();
    }
    
    my $billing_addr = SilverGoldBull::API::BillingAddress->new({
      'city'       => 'Calgary',
      'first_name' => 'John',
      'region'     => 'AB',
      'email'      => 'sales@silvergoldbull.com',
      'last_name'  => 'Smith',
      'postcode'   => 'T2P 5C5',
      'street'     => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
      'phone'      => '+1 (403) 668 8648',
      'country'    => 'CA'
    });
    
    my $shipping_addr = SilverGoldBull::API::ShippinggAddress->new({
      'city'       => 'Calgary',
      'first_name' => 'John',
      'region'     => 'AB',
      'email'      => 'sales@silvergoldbull.com',
      'last_name'  => 'Smith',
      'postcode'   => 'T2P 5C5',
      'street'     => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
      'phone'      => '+1 (403) 668 8648',
      'country'    => 'CA'
    });
    
    my $item = SilverGoldBull::API::Item->new({
        'bid_price' => 468.37,
        'qty'       => 1,
        'id'        => '2706',
    });
    
    my $order_info = {
      "currency"        => "USD",
      "declaration"     => "TEST",
      "shipping_method" => "1YR_STORAGE",
      "payment_method"  => "paypal",
      "shipping"        => $shipping,#or raw hashref
      "billing"         => $billing,#or raw hashref
      "items"           => [$item],#or raw array of hashrefs
    };
    my $order = SilverGoldBull::API::Order->new($order_info);
    my $response = $sgb->create_order($order);

# OVERVIEW

This is a Perl client for the SilverGoldBull API at [SilverGoldBull API docs](https://silvergoldbull.com/api-docs).

# METHODS

All methods return SilverGoldBull::API::Response object.

## get\_currency\_list

Input: nothing

Result: An available currency list.

## get\_payment\_method\_list

Input: nothing

Result: An available payment method list.

## get\_shipping\_method\_list

Input: nothing

Result: An available shipping method list.

## get\_product\_list

Input: nothing

Result: An available product list.

## get\_product

Input: product id;

Result: Product information.

## get\_order

Input: order id;

Result: Order information.

## create\_order

Input: SilverGoldBull::API::Order object;

Result: Product information.

## create\_quote

Input: SilverGoldBull::API::Quote object;

Result: Quote information.




# SEE ALSO

- [SilverGoldBull API docs](https://silvergoldbull.com/api-docs)

# LICENSE AND COPYRIGHT

Copyright (C) 2016 Denis Boyun

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
