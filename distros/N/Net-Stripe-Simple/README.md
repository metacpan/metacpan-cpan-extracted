# NAME

Net::Stripe::Simple - simple, non-Moose interface to the Stripe API

# SYNOPSIS

    use Net::Stripe::Simple;

    my $stripe = Net::Stripe::Simple->new('sk_test_00000000000000000000000000');

    # when the only argument is an id, that's all you need
    my $c1 = $stripe->customers( retrieve => 'cus_meFAKEfakeFAKE' );

    # you can provide arguments as a hash reference
    my $c2 = $stripe->customers( retrieve => { id => 'cus_ImFAKEfakeFAKE' } );

    # or as key-value list
    my $c3 = $stripe->customers( 'retrieve', id => 'cus_I2FAKEfakeFAKE', expand => 1 );

# DESCRIPTION

A lightweight, limited-dependency client to the stripe.com API. This is just
a thin wrapper around stripe's RESTful API. It is "simple" in the sense that it
is simple to write and maintain and it maps simply onto Stripe's web
documentation, so it is simple to use. When you get a response back, it's just
the raw JSON blessed with some convenience methods: stringification to ids and
autoloaded attributes ([Net::Stripe::Simple::Data](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple%3A%3AData)). If there is an error, the
error that is thrown is again just Stripe's JSON with a little blessing
([Net::Stripe::Simple::Error](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple%3A%3AError)).

This simplicity comes at a cost: [Net::Stripe::Simple](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple) does not
validate your parameters aside from those required to construct the URL before
constructing a request and sending it off to Stripe. This means that if you've
done it wrong it takes a round trip to find out.

For the full details of stripe's API, see [https://stripe.com/docs/api](https://stripe.com/docs/api).

## Method Invocation

Following the organization scheme of Stripe's API, actions are grouped by entity
type, each entity corresponding to a method. For a given method there are
generally a number of actions, which are treated as the primary key in a
parameter hash. Parameters for these actions are provided by a parameter hash
which is the value of the primary key. However, there is some flexibility.

Methods that require only an id are flexible. All the following will work:

    $stripe->plans( retrieve => { id => $id } );
    $stripe->plans( 'retrieve', id => $id );
    $stripe->plans( retrieve => $id );

Methods that require no arguments are also flexible:

    $stripe->plans( list => { } );
    $stripe->plans('list');

## Export Tags

[Net::Stripe::Simple](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple) exports nothing by default. It has four exportable
constants and one exportable function:

- true
- false
- null
- data\_object

To facilitate their export, it has two tags:

- :const

    The three constants.

- :all

    The three constants plus `data_object`.

# NAME

Net::Stripe::Simple - simple, non-Moose interface to the Stripe API

# METHODS

## new

    Net::Stripe::Simple->('sk_test_00000000000000000000000000', '2014-01-31')

The class constructor method. The API key is required. The version date is
optional. If not supplied, the value of `$Net::Stripe::Simple::STRIPE_VERSION`
will be supplied. [Net::Stripe::Simple](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple) was implemented or has been updated
for the following versions:

- 2014-01-31
- 2014-06-17

The default version will always be the most recent version whose handling
required an update to [Net::Stripe::Simple](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple).

## charges

See [https://stripe.com/docs/api#charges](https://stripe.com/docs/api#charges).

**Available Actions**

- create

        $charge = $stripe->charges(
            create => {
                customer => $customer,
                amount   => 100,
                currency => 'usd',
                capture  => 'false',
            }
        );

- retrieve

        $charge = $stripe->charges( retrieve => $id );

- update

        $charge = $stripe->charges(
            update => {
                id          => $charge,
                description => 'foo',
            }
        );

- refund

    Availability may depend on version of API.
        $charge = $stripe->charges( refund => $id );

- capture

        $charge = $stripe->charges( capture => $id );

- list

        my $charges = $stripe->charges('list');

## refunds

See [https://stripe.com/docs/api#refunds](https://stripe.com/docs/api#refunds).

**Available Actions**

- create

        my $refund = $stripe->refunds(
            create => {
                id     => $charge,
                amount => 50
            }
        );

- retrieve

        $refund = $stripe->refunds(
            retrieve => {
                id     => $refund,
                charge => $charge
            }
        );

- update

        $refund = $stripe->refunds(
            update => {
                id       => $refund,
                charge   => $charge,
                metadata => { foo => 'bar' }
            }
        );

- list

        my $refunds = $stripe->refunds( list => $charge );

## customers

See [https://stripe.com/docs/api#customers](https://stripe.com/docs/api#customers).

**Available Actions**

- create

        $customer = $stripe->customers(
            create => {
                metadata => { foo => 'bar' }
            }
        );

- retrieve

        $customer = $stripe->customers( retrieve => $id );

- update

        $customer = $stripe->customers(
            update => {
                id       => $customer,
                metadata => { foo => 'baz' }
            }
        );

- delete

        $customer = $stripe->customers( delete => $id );

- list

        my $customers = $stripe->customers(
            list => {
                created => { gte => $time - 100 }
            }
        );

## cards

See [https://stripe.com/docs/api#cards](https://stripe.com/docs/api#cards).

**Available Actions**

- create

        $card = $stripe->cards(
            create => {
                customer => $customer,
                card     => {
                    number    => '4242424242424242',
                    exp_month => $expiry->month,
                    exp_year  => $expiry->year,
                    cvc       => 123
                }
            }
        );

- retrieve

        $card = $stripe->cards(
            retrieve => {
                customer => $customer,
                id       => $id
            }
        );

- update

        $card = $stripe->cards(
            update => {
                customer => $customer,
                id       => $card,
                name     => 'foo',
            }
        );

- delete

        $card = $stripe->cards(
            delete => {
                customer => $customer,
                id       => $id
            }
        );

- list

        my $cards = $stripe->cards( list => $customer );

## subscriptions

See [https://stripe.com/docs/api#subscriptions](https://stripe.com/docs/api#subscriptions).

**Available Actions**

- create

        $subscription = $stripe->subscriptions(
            create => {
                customer => $customer,
                plan     => $plan,
            }
        );

- retrieve

        $subscription = $stripe->subscriptions(
            retrieve => {
                id       => $id,
                customer => $customer,
            }
        );

- update

        $subscription = $stripe->subscriptions(
            update => {
                id       => $id,
                customer => $customer,
                metadata => { foo => 'bar' }
            }
        );

- cancel

        $subscription = $stripe->subscriptions(
            cancel => {
                id       => $id,
                customer => $customer,
            }
        );

- list

        my $subscriptions = $stripe->subscriptions( list => $customer );

## plans

See [https://stripe.com/docs/api#plans](https://stripe.com/docs/api#plans).

**Available Actions**

- create

        $plan = $stripe->plans(
            create => {
                id       => $id,
                amount   => 100,
                currency => 'usd',
                interval => 'week',
                name     => 'Foo',
            }
        );

- retrieve

        $plan = $stripe->plans( retrieve => $id );

- update

        $plan = $stripe->plans(
            update => {
                id       => $id,
                metadata => { bar => 'baz' }
            }
        );

- delete

        $plan = $stripe->plans( delete => $id );

- list

        my $plans = $stripe->plans('list');

## coupons

**Available Actions**

See [https://stripe.com/docs/api#coupons](https://stripe.com/docs/api#coupons).

- create

        $coupon = $stripe->coupons(
            create => {
                percent_off => 1,
                duration    => 'forever',
            }
        );

- retrieve

        $coupon = $stripe->coupons( retrieve => $id );

- delete

        $coupon = $stripe->coupons( delete => $coupon );

- list

        my $coupons = $stripe->coupons('list');

## discounts

See [https://stripe.com/docs/api#discounts](https://stripe.com/docs/api#discounts).

**Available Actions**

- customer

        my $deleted = $stripe->discounts( customer => $c );

- subscription

        $deleted = $stripe->discounts(
            subscription => {
                customer     => $c,
                subscription => $s,
            }
        );

## invoices

See [https://stripe.com/docs/api#invoices](https://stripe.com/docs/api#invoices).

**Available Actions**

- create

        my $new_invoice = $stripe->invoices(
            create => {
                customer => $customer,
            }
        );

- retrieve

        $invoice = $stripe->invoices( retrieve => $id );

- lines

        my $lines = $stripe->invoices( lines => $invoice );

- update

        $stripe->subscriptions(
            update => {
                customer => $customer,
                id       => $subscription,
                plan     => $spare_plan,
            }
        );

- pay

        $new_invoice = $stripe->invoices( pay => $new_invoice );

- list

        my $invoices = $stripe->invoices( list => { customer => $customer } );

- upcoming

        $new_invoice = $stripe->invoices( upcoming => $customer );

## invoice\_items

See [https://stripe.com/docs/api#invoiceitems](https://stripe.com/docs/api#invoiceitems).

**Available Actions**

- create

        my $item = $stripe->invoice_items(
            create => {
                customer => $customer,
                amount   => 100,
                currency => 'usd',
                metadata => { foo => 'bar' }
            }
        );

- retrieve

        $item = $stripe->invoice_items( retrieve => $id );

- update

        $item = $stripe->invoice_items(
            update => {
                id       => $item,
                metadata => { foo => 'baz' }
            }
        );

- delete

        $item = $stripe->invoice_items( delete => $item );

- list

        my $items = $stripe->invoice_items( list => { customer => $customer } );

## disputes

See [https://stripe.com/docs/api#disputes](https://stripe.com/docs/api#disputes).

**Available Actions**

- update

        $stripe->disputes(
            update => {
                id       => $charge,
                metadata => { foo => 'bar' }
            }
        );

- close

        $stripe->disputes( close => $charge );

## transfers

See [https://stripe.com/docs/api#transfers](https://stripe.com/docs/api#transfers).

**Available Actions**

- create

        my $transfer = $stripe->transfers(
            create => {
                amount    => 1,
                currency  => 'usd',
                recipient => $recipient,
            }
        );

- retrieve

        $transfer = $stripe->transfers( retrieve => $id );

- update

        $transfer = $stripe->transfers(
            update => {
                id       => $transfer,
                metadata => { foo => 'bar' }
            }
        );

- cancel

        $transfer = $stripe->transfers( cancel => $transfer );

- list

        my $transfers = $stripe->transfers(
            list => {
                created => { gt => $time }
            }
        );

## recipients

See [https://stripe.com/docs/api#recipients](https://stripe.com/docs/api#recipients).

**Available Actions**

- create

        $recipient = $stripe->recipients(
            create => {
                name => 'I Am An Example',
                type => 'individual',
            }
        );

- retrieve

        $recipient = $stripe->recipients( retrieve => $id );

- update

        $recipient = $stripe->recipients(
            update => {
                id       => $recipient,
                metadata => { foo => 'bar' },
            }
        );

- delete

        $recipient = $stripe->recipients( delete => $id );

- list

        my $recipients = $stripe->recipients('list');

## application\_fees

See [https://stripe.com/docs/api#application\_fees](https://stripe.com/docs/api#application_fees).

**Available Actions**

- retrieve

        my $fee = $stripe->application_fees( retrieve => $id );

- refund

        my $fee = $stripe->application_fees( refund => $id );

- list

        my $fees = $stripe->application_fees('list');

## account

See [https://stripe.com/docs/api#account](https://stripe.com/docs/api#account).

**Available Actions**

- retrieve

        my $account = $stripe->account('retrieve');  # or
        $account = $stripe->account;

## balance

See [https://stripe.com/docs/api#balance](https://stripe.com/docs/api#balance).

**Available Actions**

- retrieve

        my $balance = $stripe->balance('retrieve');

- history

        my $history = $stripe->balance('history');

- transaction

        $balance = $stripe->balance( transaction => $charge );

## events

See [https://stripe.com/docs/api#events](https://stripe.com/docs/api#events).

**Available Actions**

- retrieve

        $event = $stripe->events( retrieve => $id );

- list

        my $events = $stripe->events( list => { created => { gt => $time } } );

## tokens

See [https://stripe.com/docs/api#tokens](https://stripe.com/docs/api#tokens).

**Available Actions**

- create

        $token = $stripe->tokens(
            create => {
                card => {
                    number    => '4242424242424242',
                    exp_month => $expiry->month,
                    exp_year  => $expiry->year,
                    cvc       => 123
                }
            }
        );
        $token = $stripe->tokens(
            create => {
                bank_account => {
                    country        => 'US',
                    routing_number => '110000000',
                    account_number => '000123456789',
                }
            }
        );

- retrieve

        $token = $stripe->tokens( retrieve => $id );

- bank

    To preserve the parallel with the Stripe's API documentation, there is a
    special "bank" action, but it is simply a synonym for the code above.
        $token = $stripe->tokens(
            bank => {
                bank\_account => {
                    country        => 'US',
                    routing\_number => '110000000',
                    account\_number => '000123456789',
                }
            }
        );

# FUNCTIONS

## data\_object($hash\_ref)

This function recursively converts a hash ref into a data object. This is just
[Net::Stripe::Simple::Data](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple%3A%3AData), whose only function is to autoload accessors for
all the keys in the hash. It is made for adding magic to JSON objects. If you
try to give it something that contains blessed references whose class is
outside the JSON namespace it will die.

# SEE ALSO

[Net::Stripe](https://metacpan.org/pod/Net%3A%3AStripe), [Business::Stripe](https://metacpan.org/pod/Business%3A%3AStripe)

# EXPORTED CONSTANTS

These are just the corresponding [JSON](https://metacpan.org/pod/JSON) constants. They are exported by
[Net::Stripe::Simple](https://metacpan.org/pod/Net%3A%3AStripe%3A%3ASimple) for convenience.

    use Net::Stripe::Simple qw(:const);
    ...
    my $subscription = $stripe->subscriptions(
        update => {
            id       => $id,
            customer => $customer_id,
            plan     => $plan_id,
            prorate  => true,
        }
    );

You can import the constants individually or all together with `:const`.

- true
- false
- null

# AUTHORS

- Andy Beverley <andy@andybev.com>
- Grant Street Group <developers@grantstreet.com>
- David F. Houghton <dfhoughton@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHORS

- Grant Street Group <developers@grantstreet.com>
- David F. Houghton <dfhoughton@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
