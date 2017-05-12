use strict;
use warnings;
use autodie;
use Test::Exception;
use Test::More tests => 20;
use Net::Stripe::Simple qw(:all);
use DateTime;

note '!!!!!!';
note "NOTE:\nIf you do not have an Internet connection, "
  . "or cannot see Stripe's API from this connection, this test will fail.";
note '!!!!!!';

# test key from Stripe's API documentation
my $stripe = new_ok( 'Net::Stripe::Simple' =>
      [ 'sk_test_BQokikJOvBiI2HlWgH4olfQ2', '2014-06-17' ] );

my $time = time;
my $customer;
subtest Customers => sub {
    plan tests => 10;
    $customer = $stripe->customers(
        create => {
            metadata => { foo => 'bar' }
        }
    );
    ok defined($customer) && $customer->metadata->foo eq 'bar',
      'created a customer';
    throws_ok {
        $stripe->customers( update => { metadata => { foo => 'baz' } } )
    }
    qr/No id provided/, 'update requires a customer id';
    $customer = $stripe->customers(
        update => {
            id       => $customer,
            metadata => { foo => 'baz' }
        }
    );
    ok defined($customer) && $customer->metadata->foo eq 'baz',
      'updated a customer';
    my $customers = $stripe->customers(
        list => {
            created => { gte => $time - 100 }
        }
    );
    ok defined $customers, 'listed customers';
    ok( ( grep { $_->id eq $customer->id } @{ $customers->data } ),
        'new customer listed' );
    throws_ok { $stripe->customers('retrieve') } qr/No id provided/,
      'retrieve requires a customer id';
    my $id = $customer->id;
    $customer = $stripe->customers( retrieve => $id );
    ok defined($customer) && $customer->id eq $id, 'simple retrieve';
    $customer = $stripe->customers( retrieve => { id => $id } );
    ok defined($customer) && $customer->id eq $id, 'verbose retrieve';
    $customer = $stripe->customers( delete => $id );
    throws_ok { $stripe->customers('delete') } qr/No id provided/,
      'delete requires a customer id';
    ok defined($customer) && $customer->deleted, 'deleted customer';

    # recreate customer for use in other tests
    $customer = $stripe->customers(
        create => {
            metadata => { foo => 'bar' }
        }
    );
};

my $card;
my $expiry = DateTime->now->add( years => 1 );
subtest Cards => sub {
    plan tests => 13;
    throws_ok {
        $card = $stripe->cards(
            create => {
                card => {
                    number    => '4242424242424242',
                    exp_month => $expiry->month,
                    exp_year  => $expiry->year,
                    cvc       => 123
                }
            }
        );
    }
    qr/No customer id provided/, 'create requires customer id';
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
    ok defined($card) && $card->customer eq $customer->id,
      'created a card for a customer';
    throws_ok {
        $stripe->cards(
            update => {
                id   => $card,
                name => 'foo',
            }
        );
    }
    qr/No customer id provided/, 'update requires customer id';
    throws_ok {
        $stripe->cards(
            update => {
                customer => $customer,
                name     => 'foo',
            }
        );
    }
    qr/No id provided/, 'update requires id';
    $card = $stripe->cards(
        update => {
            customer => $customer,
            id       => $card,
            name     => 'foo',
        }
    );
    is $card->name, 'foo', 'updated a card';
    my $id = $card->id;
    throws_ok {
        $stripe->cards(
            retrieve => {
                id => $id
            }
        );
    }
    qr/No customer id provided/, 'retrieve requires customer id';
    throws_ok {
        $stripe->cards(
            retrieve => {
                customer => $customer,
            }
        );
    }
    qr/No id provided/, 'retrieve requires id';
    $card = $stripe->cards(
        retrieve => {
            customer => $customer,
            id       => $id
        }
    );
    ok defined($card) && $card->id eq $id, 'retrieved a card';
    throws_ok { $stripe->cards('list') } qr/No .*\bid provided/,
      'list requires customer id';
    my $cards = $stripe->cards( list => $customer );
    ok(
        (
                  defined $cards
              and @{ $cards->data } == 1
              and $cards->data->[0]->id eq $id
        ),
        'listed cards'
    );
    throws_ok { $stripe->cards( delete => { id => $id } ) }
    qr/No .*\bid provided/, 'delete requires customer id';
    throws_ok { $stripe->cards( delete => { customer => $customer, } ) }
    qr/No .*\bid provided/, 'delete requires id';
    $card = $stripe->cards(
        delete => {
            customer => $customer,
            id       => $id
        }
    );
    ok defined($card) && $card->deleted, 'deleted a card';

    # recreate card for later use
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
};

my $charge;
subtest Charges => sub {
    plan tests => 9;
    $charge = $stripe->charges(
        create => {
            customer => $customer,
            amount   => 100,
            currency => 'usd',
            capture  => false,
        }
    );
    ok defined($charge) && !$charge->captured, 'created an uncaptured charge';
    throws_ok { $stripe->charges( update => { description => 'foo', } ) }
    qr/No .*\bid provided/, 'update requires id';
    $charge = $stripe->charges(
        update => {
            id          => $charge,
            description => 'foo',
        }
    );
    is $charge->description, 'foo', 'updated charge';
    throws_ok { $stripe->charges('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    my $id = $charge->id;
    $charge = $stripe->charges( retrieve => $id );
    is $charge->id, $id, 'retrieved a charge';
    throws_ok { $stripe->charges('capture') } qr/No .*\bid provided/,
      'capture requires id';
    $charge = $stripe->charges( capture => $id );
    ok $charge->captured, 'captured a charge';
    my $charges = $stripe->charges( list => {} );
    ok( ( grep { $_->id eq $charge->id } @{ $charges->data } ),
        'zero-arg list' );
    $charges = $stripe->charges( list => { customer => $customer } );
    ok( ( grep { $_->id eq $charge->id } @{ $charges->data } ),
        'multi-arg list' );
};

subtest Refunds => sub {
    plan tests => 7;
    throws_ok { $stripe->refunds( create => { amount => 50 } ) }
    qr/No .*\bid provided/, 'create requires id';
    my $refund = $stripe->refunds(
        create => {
            id     => $charge,
            amount => 50
        }
    );
    is $refund->object, 'refund', 'created a refund';
    throws_ok { $stripe->refunds( retrieve => { charge => $charge } ) }
    qr/No .*\bid provided/, 'retrieve requires id';
    $refund = $stripe->refunds(
        retrieve => {
            id     => $refund,
            charge => $charge
        }
    );
    is $refund->amount, 50, 'retrieved a refund';
    throws_ok {
        $stripe->refunds(
            update => {
                charge   => $charge,
                metadata => { foo => 'bar' }
            }
          )
    }
    qr/No .*\bid provided/, 'update requires id';
    $refund = $stripe->refunds(
        update => {
            id       => $refund,
            charge   => $charge,
            metadata => { foo => 'bar' }
        }
    );
    is $refund->metadata->foo, 'bar', 'updated a refund';
    my $refunds = $stripe->refunds( list => $charge );
    ok( ( grep { $_->id eq $refund->id } @{ $refunds->data } ),
        'listed refunds' );
};

my ( $plan, $spare_plan );
subtest Plans => sub {
    plan tests => 8;
    my $id = $$ . 'foo' . time;
    $plan = $stripe->plans(
        create => {
            id       => $id,
            amount   => 100,
            currency => 'usd',
            interval => 'week',
            name     => 'Foo',
        }
    );
    is $plan->id, $id, 'created a plan';
    throws_ok { $stripe->plans('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $plan = $stripe->plans( retrieve => $id );
    is $plan->id, $id, 'retrieved plan';
    throws_ok { $stripe->plans( update => { metadata => { bar => 'baz' } } ) }
    qr/No .*\bid provided/, 'update requires id';
    $plan = $stripe->plans(
        update => {
            id       => $id,
            metadata => { bar => 'baz' }
        }
    );
    is $plan->metadata->bar, 'baz', 'updated plan';
    my $plans = $stripe->plans('list');
    ok scalar @{ $plans->data },
      'listed plans';    # this fake account may have many
    throws_ok { $stripe->plans('delete') } qr/No .*\bid provided/,
      'delete requires id';
    $plan = $stripe->plans( delete => $id );
    ok $plan->deleted, 'deleted a plan';

    # keep around
    $plan = $stripe->plans(
        create => {
            id       => $id,
            amount   => 100,
            currency => 'usd',
            interval => 'week',
            name     => 'Foo',
        }
    );
    $spare_plan = $stripe->plans(
        create => {
            id       => $$ . 'bar' . time,
            amount   => 100000,
            currency => 'usd',
            interval => 'week',
            name     => 'Bar',
        }
    );
};

my $subscription;
subtest Subscriptions => sub {
    plan tests => 12;
    throws_ok { $stripe->subscriptions( create => { plan => $plan, } ) }
    qr/No .*\bid provided/, 'create requires id';
    $subscription = $stripe->subscriptions(
        create => {
            customer => $customer,
            plan     => $plan,
        }
    );
    is $subscription->plan->id, $plan->id, 'created a subscription';
    my $id = $subscription->id;
    throws_ok {
        $stripe->subscriptions( retrieve => { customer => $customer, } )
    }
    qr/No .*\bid provided/, 'retrieve requires id';
    throws_ok { $stripe->subscriptions( retrieve => { id => $id, } ) }
    qr/No .*\bid provided/, 'retrieve requires customer';
    $subscription = $stripe->subscriptions(
        retrieve => {
            id       => $id,
            customer => $customer,
        }
    );
    is $subscription->id, $id, 'retrieved a subscription';
    throws_ok {
        $stripe->subscriptions(
            update => { customer => $customer, metadata => { foo => 'bar' } } )
    }
    qr/No .*\bid provided/, 'update requires id';
    throws_ok {
        $stripe->subscriptions(
            update => { id => $id, metadata => { foo => 'bar' } } )
    }
    qr/No .*\bid provided/, 'update requires customer';
    $subscription = $stripe->subscriptions(
        update => {
            id       => $id,
            customer => $customer,
            metadata => { foo => 'bar' }
        }
    );
    is $subscription->metadata->foo, 'bar', 'updated a subscription';
    my $subscriptions = $stripe->subscriptions( list => $customer );
    is $subscriptions->data->[0]->id, $id, 'listed subscriptions';
    throws_ok { $stripe->subscriptions( cancel => { customer => $customer, } ) }
    qr/No .*\bid provided/, 'cancel requires id';
    throws_ok { $stripe->subscriptions( cancel => { id => $id, } ) }
    qr/No .*\bid provided/, 'cancel requires customer';
    $subscription = $stripe->subscriptions(
        cancel => {
            id       => $id,
            customer => $customer,
        }
    );
    is $subscription->status, 'canceled', 'canceled a subscription';

    # burden this customer with a subscription again
    $subscription = $stripe->subscriptions(
        create => {
            customer => $customer,
            plan     => $plan,
        }
    );
};

my $invoice;
subtest Invoices => sub {
    plan tests => 11;
    my $invoices = $stripe->invoices( list => { customer => $customer } );
    $invoice = $invoices->data->[0];
    is $invoice->customer, $customer->id, 'listed invoices for customer';
    my $id = $invoice->id;
    throws_ok { $stripe->invoices('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $invoice = $stripe->invoices( retrieve => $id );
    is $invoice->id, $id, 'retrieved specific invoice';
    throws_ok {
        $stripe->invoices( update => { metadata => { foo => 'bar' } } )
    }
    qr/No .*\bid provided/, 'update requires id';
    $invoice = $stripe->invoices(
        update => {
            id       => $id,
            metadata => { foo => 'bar' }
        }
    );
    is $invoice->metadata->foo, 'bar', 'updated invoice';
    $stripe->subscriptions(
        update => {
            customer => $customer,
            id       => $subscription,
            plan     => $spare_plan,
        }
    );
    my $new_invoice = $stripe->invoices(
        create => {
            customer => $customer,
        }
    );
    throws_ok { $stripe->invoices('pay') } qr/No .*\bid provided/,
      'pay requires id';
    $new_invoice = $stripe->invoices( pay => $new_invoice );
    ok $new_invoice->paid, 'paid invoice';
    throws_ok { $stripe->invoices('upcoming') } qr/No .*\bid provided/,
      'upcoming requires id';
    $new_invoice = $stripe->invoices( upcoming => $customer );
    is $new_invoice->customer, $customer->id, 'retrieved an upcoming invoice';
    throws_ok { $stripe->invoices('lines') } qr/No .*\bid provided/,
      'lines requires id';
    my $lines = $stripe->invoices( lines => $invoice );
    is $lines->object, 'list', 'retrieved line items for invoice';
};

subtest 'Invoice Items' => sub {
    plan tests => 8;
    my $new_invoice = $stripe->invoices( upcoming => $customer );
    my $item = $stripe->invoice_items(
        create => {
            customer => $customer,
            amount   => 100,
            currency => 'usd',
            metadata => { foo => 'bar' }
        }
    );
    is $item->metadata->foo, 'bar', 'created invoice item';
    my $id = $item->id;
    throws_ok { $stripe->invoice_items('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $item = $stripe->invoice_items( retrieve => $id );
    is $item->id, $id, 'retrieved invoice item';
    throws_ok {
        $stripe->invoice_items(
            update => {
                metadata => { foo => 'baz' }
            }
          )
    }
    qr/No .*\bid provided/, 'update requires id';
    $item = $stripe->invoice_items(
        update => {
            id       => $item,
            metadata => { foo => 'baz' }
        }
    );
    is $item->metadata->foo, 'baz', 'updated invoice item';
    my $items = $stripe->invoice_items( list => { customer => $customer } );
    ok( ( grep { $_->id eq $item->id } @{ $items->data } ),
        'listed invoice items' );
    throws_ok { $stripe->invoice_items('delete') } qr/No .*\bid provided/,
      'delete requires id';
    $item = $stripe->invoice_items( delete => $item );
    ok $item->deleted, 'deleted invoice item';
};

my $coupon;
subtest Coupons => sub {
    plan tests => 6;
    $coupon = $stripe->coupons(
        create => {
            percent_off => 1,
            duration    => 'forever',
        }
    );
    is $coupon->duration, 'forever', 'created a coupon';
    my $id = $coupon->id;
    throws_ok { $stripe->coupons('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $coupon = $stripe->coupons( retrieve => $id );
    is $coupon->id, $id, 'retrieved coupon';
    my $coupons = $stripe->coupons('list');
    ok scalar @{ $coupons->data }, 'listed coupons';
    throws_ok { $stripe->coupons('delete') } qr/No .*\bid provided/,
      'delete requires id';
    $coupon = $stripe->coupons( delete => $coupon );
    ok $coupon->deleted, 'deleted a coupon';
    $coupon = $stripe->coupons(
        create => {
            percent_off => 1,
            duration    => 'forever',
        }
    );
};

subtest Discounts => sub {
    plan tests => 5;
    my $c = $stripe->customers(
        create => {
            metadata => { foo => 'bar' },
            coupon   => $coupon,
        }
    );
    my $card = $stripe->cards(
        create => {
            customer => $c,
            card     => {
                number    => '4242424242424242',
                exp_month => $expiry->month,
                exp_year  => $expiry->year,
                cvc       => 123
            }
        }
    );
    my $s = $stripe->subscriptions(
        create => {
            customer => $c,
            plan     => $plan,
            coupon   => $coupon,
        }
    );
    throws_ok { $stripe->discounts('customer') } qr/No .*\bid provided/,
      'customer requires id';
    my $deleted = $stripe->discounts( customer => $c );
    ok $deleted->deleted, 'deleted a customer discount';
    throws_ok {
        $stripe->discounts(
            subscription => {
                subscription => $s,
            }
          )
    }
    qr/No .*\bid provided/, 'subscription requires customer';
    throws_ok {
        $stripe->discounts(
            subscription => {
                customer => $c,
            }
          )
    }
    qr/No .*\bid provided/, 'subscription requires subscription';
    $deleted = $stripe->discounts(
        subscription => {
            customer     => $c,
            subscription => $s,
        }
    );
    ok $deleted->deleted, 'deleted a subscription discount';
    $stripe->subscriptions(
        cancel => {
            id       => $s,
            customer => $c,
        }
    );
    $stripe->customers( delete => $c );
};

subtest Disputes => sub {
    plan tests => 4;

    # we don't actually have any disputes, but this will suffice to confirm
    # that we are calling the API correctly
    eval {
        throws_ok {
            $stripe->disputes(
                update => {
                    metadata => { foo => 'bar' }
                }
              )
        }
        qr/No .*\bid provided/, 'update requires id';
        $stripe->disputes(
            update => {
                id       => $charge,
                metadata => { foo => 'bar' }
            }
        );
    };
    my $e = $@;
    is $e->message, "No dispute for charge: $charge", 'updated a dispute';
    eval {
        throws_ok { $stripe->disputes('close'); } qr/No .*\bid provided/,
          'close requires id';
        $stripe->disputes( close => $charge );
    };
    $e = $@;
    is $e->message, "No dispute for charge: $charge", 'closed a dispute';
};

my $token;
subtest Tokens => sub {
    plan tests => 5;
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
    is $token->type, 'card', 'created a card token';
    $token = $stripe->tokens(
        bank => {
            bank_account => {
                country        => 'US',
                routing_number => '110000000',
                account_number => '000123456789',
            }
        }
    );
    is $token->type, 'bank_account', 'created a bank account token with bank';
    $token = $stripe->tokens(
        create => {
            bank_account => {
                country        => 'US',
                routing_number => '110000000',
                account_number => '000123456789',
            }
        }
    );
    is $token->type, 'bank_account', 'created a bank account token with create';
    my $id = $token->id;
    throws_ok { $stripe->tokens('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $token = $stripe->tokens( retrieve => $id );
    is $token->id, $id, 'retrieved a token';
};

my $recipient;
subtest Recipients => sub {
    plan tests => 8;
    $recipient = $stripe->recipients(
        create => {
            name => 'I Am An Example',
            type => 'individual',
        }
    );
    ok $recipient, 'created a recipient';
    my $id = $recipient->id;
    throws_ok { $stripe->recipients('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $recipient = $stripe->recipients( retrieve => $id );
    is $recipient->id, $id, 'retrieved recipient';
    my $recipients = $stripe->recipients('list');
    ok scalar @{ $recipients->data }, 'listed recipients';
    throws_ok {
        $stripe->recipients(
            update => {
                metadata => { foo => 'bar' },
            }
          )
    }
    qr/No .*\bid provided/, 'update requires id';
    $recipient = $stripe->recipients(
        update => {
            id       => $recipient,
            metadata => { foo => 'bar' },
        }
    );
    is $recipient->metadata->foo, 'bar', 'updated recipient';
    throws_ok { $stripe->recipients('delete') } qr/No .*\bid provided/,
      'delete requires id';
    $recipient = $stripe->recipients( delete => $id );
    ok $recipient->deleted, 'deleted recipient';
    $recipient = $stripe->recipients(
        create => {
            name         => 'I Am An Example',
            type         => 'individual',
            bank_account => $token,
        }
    );
};

subtest Transfers => sub {
    plan tests => 8;
    my $transfer = $stripe->transfers(
        create => {
            amount    => 1,
            currency  => 'usd',
            recipient => $recipient,
        }
    );
    ok $transfer, 'created a transfer';
    my $id = $transfer->id;
    throws_ok { $stripe->transfers('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $transfer = $stripe->transfers( retrieve => $id );
    is $transfer->id, $id, 'retrieved a transfer';
    my $transfers = $stripe->transfers(
        list => {
            created => { gt => $time }
        }
    );
    ok( ( grep { $_->id eq $id } @{ $transfers->data } ), 'listed transfers' );
    throws_ok {
        $stripe->transfers(
            update => {
                metadata => { foo => 'bar' }
            }
          )
    }
    qr/No .*\bid provided/, 'update requires id';
    $transfer = $stripe->transfers(
        update => {
            id       => $transfer,
            metadata => { foo => 'bar' }
        }
    );
    is $transfer->metadata->foo, 'bar', 'updated a transfer';
    eval {
        throws_ok { $stripe->transfers('cancel') } qr/No .*\bid provided/,
          'cancel requires id';
        $transfer = $stripe->transfers( cancel => $transfer );
        ok $transfer->canceled, 'canceled a transfer';
    };
    if ( my $e = $@ ) {    # at least the path worked
        ok $e->message =~
          /Transfers to non-Stripe accounts can currently only be reversed while they are pending/,
          'canceled a transfer';
    }
};

subtest 'Application Fees' => sub {
    plan tests => 5;
    my $fees = $stripe->application_fees('list');
    ok $fees, 'listed application fees';
    my $id = 'fee_4KuzXIHPLEjY8n';    # borrowing from API
    eval {
        throws_ok { $stripe->application_fees('retrieve') }
        qr/No .*\bid provided/, 'retrieve requires id';
        my $fee = $stripe->application_fees( retrieve => $id );
        is $fee->id, $id, 'retrieved application fee';
    };
    if ( my $e = $@ ) {               # at least the path worked
        is $e->message, "No such application fee: $id",
          'retrieved application fee';
    }
    eval {
        throws_ok { $stripe->application_fees('refund') }
        qr/No .*\bid provided/, 'refund requires id';
        my $fee = $stripe->application_fees( refund => $id );
        is $fee->id, $id, 'refunded application fee';
    };
    if ( my $e = $@ ) {               # at least the path worked
        is $e->message, "No such application fee: $id",
          'refunded application fee';
    }
};

subtest Account => sub {
    plan tests => 1;
    my $account = $stripe->account;
    ok $account, 'retrieved account details';
};

subtest Balance => sub {
    plan tests => 4;
    my $balance = $stripe->balance('retrieve');
    ok $balance, 'retrieved balance';
    my $history = $stripe->balance('history');
    ok $history, 'retrieved balance history';

    # this will suffice to test our paths
    eval {
        throws_ok { $stripe->balance('transaction') } qr/No .*\bid provided/,
          'transaction requires id';
        $balance = $stripe->balance( transaction => $charge );
        ok $balance, 'retrieved a balance transaction';
    };
    if ( my $e = $@ ) {
        is $e->message, "No such balance transaction: $charge",
          'retrieved a balance transaction';
    }
};

subtest Events => sub {
    plan tests => 3;
    my $events = $stripe->events( list => { created => { gt => $time } } );
    ok scalar @{ $events->data }, 'listed events';
    my $event = $events->data->[0];
    my $id    = $event->id;
    throws_ok { $stripe->events('retrieve') } qr/No .*\bid provided/,
      'retrieve requires id';
    $event = $stripe->events( retrieve => $id );
    is $event->id, $id, 'retrieved an event';
};

subtest 'Various Exports' => sub {
    plan tests => 4;
    my $do = data_object( { foo => 'bar' } );
    is $do->foo, 'bar', 'created a data object';
    like ref(true),  qr/JSON/, 'exported true';
    like ref(false), qr/JSON/, 'exported false';
    eval { null };
    ok !$@, 'exported null';
};

done_testing;

# clean up
END {
    eval { $stripe->plans( delete => $plan )       if $plan };
    eval { $stripe->plans( delete => $spare_plan ) if $spare_plan };
    eval {
        $stripe->subscriptions(
            cancel => {
                id       => $subscription,
                customer => $customer,
            }
        ) if $subscription;
    };
    eval { $stripe->customers( delete => $customer ) if $customer };
    eval { $stripe->coupons( delete => $coupon ) if $coupon };
    eval { $stripe->recipients( delete => $recipient ) if $recipient };
}
