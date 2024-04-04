package Stancer::Payment::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Card;
use Stancer::Customer;
use Stancer::Payment;
use Stancer::Payment::Status;
use List::Util qw(shuffle);
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars, RequireExtendedFormatting)

sub bad_credential : Tests(3) {
    my $config = Stancer::Config->init();
    my $bad_key = 'stest_' . random_string(24);
    my $good_key = $config->stest;

    $config->keychain($bad_key);

    throws_ok(
        sub { Stancer::Payment->new('paym_' . random_string(24))->populate() },
        'Stancer::Exceptions::Http::Unauthorized',
        'Should throw a Unauthorized (401) error',
    );

    my $exception = $EVAL_ERROR;

    isa_ok($exception->request, 'HTTP::Request', '$exception->request');
    isa_ok($exception->response, 'HTTP::Response', '$exception->response');

    $config->keychain($good_key); # For other tests
}

sub get_data : Tests(9) {
    # 404
    throws_ok(
        sub { Stancer::Payment->new('paym_' . random_string(24))->populate() },
        'Stancer::Exceptions::Http::NotFound',
        'Should throw a NotFound (404) error',
    );

    my $payment = Stancer::Payment->new('paym_FQgpGVJpyGPVJVIuQtO3zy6i');

    is($payment->amount, 7810, 'Should have an amount');
    is($payment->currency, 'usd', 'Should have a currency');
    is($payment->description, 'Automatic test, 78.10 USD', 'Should have a description');
    is($payment->method, 'card', 'Should have a method');

    isa_ok($payment->card, 'Stancer::Card', '$payment->card');
    is($payment->card->id, 'card_nsA0eap90E6HRod6j54pnVWg', 'Card should have an id');

    isa_ok($payment->customer, 'Stancer::Customer', '$payment->customer');
    is($payment->customer->id, 'cust_6FbQaYtxjADzerqdO5gs79as', 'Customer should have an id');
}

sub list : Tests(38) {
    { # 23 tests
        note 'Basic tests';

        my $order_id = random_string(15);
        my @payments = ();

        my @currencies = currencies_provider();
        my @dateparts = localtime;

        my $payment1 = Stancer::Payment->new();

        my $amount1 = random_integer(50, 9999);
        my $description1 = sprintf 'Automatic test for list, %.02f %s', $amount1 / 100, uc $currencies[0];

        my $card1 = Stancer::Card->new();

        $card1->number(valid_card_number_provider());
        $card1->exp_month(random_integer(1, 12));
        $card1->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card1->cvc(sprintf '%d', random_integer(100, 999));

        $payment1->amount($amount1);
        $payment1->currency($currencies[0]);
        $payment1->description($description1);
        $payment1->card($card1);
        $payment1->customer(
            Stancer::Customer->new(
                name => 'John Doe',
                email => 'john.doe+' . random_string(5) . '@example.com',
                external_id => random_string(20),
            ),
        );
        $payment1->order_id($order_id);

        $payment1->send();

        push @payments, $payment1;

        my $payment2 = Stancer::Payment->new();

        my $amount2 = random_integer(50, 9999);
        my $description2 = sprintf 'Automatic test for list, %.02f %s', $amount2 / 100, uc $currencies[1];

        my $card2 = Stancer::Card->new();

        $card2->number(valid_card_number_provider());
        $card2->exp_month(random_integer(1, 12));
        $card2->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card2->cvc(sprintf '%d', random_integer(100, 999));

        $payment2->amount($amount2);
        $payment2->currency($currencies[1]);
        $payment2->description($description2);
        $payment2->card($card2);
        $payment2->customer(
            Stancer::Customer->new(
                name => 'John Doe',
                email => 'john.doe+' . random_string(5) . '@example.com',
                external_id => random_string(20),
            ),
        );
        $payment2->order_id($order_id);

        $payment2->send();

        push @payments, $payment2;

        my $list = Stancer::Payment->list({order_id => $order_id});
        my $index = 0;

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({order_id => $order_id})');

        while (my $payment = $list->next()) {
            my $sent = $payments[$index];

            $index++;

            isa_ok($payment, 'Stancer::Payment', '$list->next() (payment ' . $index . q/)/);

            is($payment->id, $sent->id, 'Should have same id (payment ' . $index . q/)/);
            is($payment->amount, $sent->amount, 'Should have same amount (payment ' . $index . q/)/);
            is($payment->currency, lc $sent->currency, 'Should have same currency (payment ' . $index . q/)/);
            is($payment->description, $sent->description, 'Should have same description (payment ' . $index . q/)/);
            is($payment->order_id, $sent->order_id, 'Should have same order_id (payment ' . $index . q/)/);

            is($payment->customer->id, $sent->customer->id, 'Customer should have same id (payment ' . $index . q/)/);
            is(
                $payment->customer->email,
                $sent->customer->email,
                'Customer should have same email (payment ' . $index . q/)/,
            );
            is(
                $payment->customer->external_id,
                $sent->customer->external_id,
                'Customer should have same external_id (payment ' . $index . q/)/,
            );
            is(
                $payment->customer->name,
                $sent->customer->name,
                'Customer should have same name (payment ' . $index . q/)/,
            );
        }

        is($index, 2, 'Should have made 2 loop');
        is($list->next, undef, 'Should return undef now');
    }

    { # 2 tests
        note 'With no results';

        my $list = Stancer::Payment->list({order_id => '1337'});
        my $index = 0;

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({order_id => $order_id})');

        while (my $payment = $list->next()) {
            fail('Should not find any payment');
        }

        is($index, 0, 'Should not have enter in while loop');
    }

    { # 13 tests
        note 'Compare a static list';

        my $list = Stancer::Payment->list({created => 0});
        my @payments = qw(
            paym_I7XEzC1LTD1o886txarGotEx
            paym_MLdKxTSMLcuSAROISDip9nHh
            paym_JoIXIUaRPoDB3Wz5FZp3hX1z
            paym_I7fM7CvMT9QO0j9PP7pyePMC
            paym_1xg2TJIRX3mkHwndq2qMHf1s
            paym_qANlia15BNMUy06x04YxoglC
            paym_ysg4gKOuBHvYdRGs7yqlcjhn
            paym_d0jDDhuKco1PHiUQ2xRa99RY
            paym_BXg98H2u74AWgWTn7A3dcjp5
            paym_R23cljqS2Zt98jbtn7SWQNiE
            paym_caT8HNnkoPyGRaW8bkyYGlOC
            paym_BA8Ocj87XUgi3yn5dy0UPaDz
        );

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({created => $created})');

        while (my $payment = $list->next()) {
            my $id = shift @payments;

            is($payment->id, $id, 'Should return ' . $id);

            $list->end if scalar @payments == 0;
        }
    }
}

sub patch_card : Tests(10) {
    my $payment = Stancer::Payment->new();
    my $amount = random_integer(50, 9999);
    my $currency = currencies_for_card_provider();
    my $description = sprintf 'Automatic test, PATCH card, %.02f %s', $amount / 100, $currency;
    my @dateparts = localtime;

    my $customer = Stancer::Customer->new();

    $customer->name('John Doe');
    $customer->email('john.doe@example.com');

    $payment->amount($amount);
    $payment->currency($currency);
    $payment->description($description);
    $payment->customer($customer);
    $payment->send();

    like($payment->id, qr/^paym_/sm, 'Should have an id');
    is($payment->card, undef, 'Should not have a card');
    is($payment->sepa, undef, 'Should not have a sepa account');
    is($payment->status, undef, 'Should not have a status');

    my $card = Stancer::Card->new();

    $card->number(valid_card_number_provider());
    $card->exp_month(random_integer(1, 12));
    $card->exp_year(random_integer(10) + $dateparts[5] + 1901);
    $card->cvc(sprintf '%d', random_integer(100, 999));

    $payment->card($card);
    $payment->send();

    is($payment->card, $card, 'Should have a card');
    is($payment->sepa, undef, 'Should not have a sepa account');
    is($payment->status, undef, 'Should not have a status');

    like($card->id, qr/^card_/sm, 'Card should have an id');

    $payment->status(Stancer::Payment::Status::AUTHORIZE);
    $payment->send();

    is($payment->status, Stancer::Payment::Status::AUTHORIZED, 'Should be authorized');

    $payment->status(Stancer::Payment::Status::CAPTURE);
    $payment->send();

    is($payment->status, Stancer::Payment::Status::TO_CAPTURE, 'Should be awating capture');
}

sub patch_sepa : Tests(8) {
    my $payment = Stancer::Payment->new();
    my $amount = random_integer(50, 9999);
    my $currency = currencies_for_sepa_provider();
    my $description = sprintf 'Automatic test, PATCH sepa, %.02f %s', $amount / 100, $currency;

    my $customer = Stancer::Customer->new();

    $customer->name('John Doe');
    $customer->email('john.doe@example.com');

    $payment->amount($amount);
    $payment->currency($currency);
    $payment->description($description);
    $payment->customer($customer);
    $payment->send();

    like($payment->id, qr/^paym_/sm, 'Should have an id');
    is($payment->card, undef, 'Should not have a card');
    is($payment->sepa, undef, 'Should not have a sepa account');
    is($payment->status, undef, 'Should not have a status');

    my $sepa = Stancer::Sepa->new();

    $sepa->bic(bic_provider());
    $sepa->iban(iban_provider());
    $sepa->name('John Doe');

    $payment->sepa($sepa);
    $payment->send();

    is($payment->card, undef, 'Should not have a card');
    is($payment->sepa, $sepa, 'Should have a sepa account');
    is($payment->status, undef, 'Should not have a status');

    like($sepa->id, qr/^sepa_/sm, 'Sepa should have an id');
}

sub send_global : Tests(49) {
    my $customer_email = 'john.doe+' . random_string(10) . '@example.com';
    my $customer_mobile = '+33684858687';
    my $customer_name = 'John Doe';
    my $customer_id;
    my $card_id;

    { # 4 tests
        note 'Basic test';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Automatic test, %.02f %s', $amount / 100, $currency;

        my $card = Stancer::Card->new();
        my @dateparts = localtime;

        $card->number(valid_card_number_provider());
        $card->exp_month(random_integer(1, 12));
        $card->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card->cvc(sprintf '%d', random_integer(100, 999));

        my $customer = Stancer::Customer->new();

        $customer->email($customer_email);
        $customer->mobile($customer_mobile);
        $customer->name($customer_name);

        $payment->amount($amount);
        $payment->currency($currency);
        $payment->description($description);
        $payment->card($card);
        $payment->customer($customer);

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($card->id, qr/^card_/sm, 'Card should have an id');
        like($customer->id, qr/^cust_/sm, 'Customer should have an id');

        $card_id = $card->id;
        $customer_id = $customer->id;
    }

    { # 10 tests
        note 'With authentication';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Automatic auth test, %.02f %s', $amount / 100, $currency;
        my $return_url = 'https://www.example.org/?' . random_string(30);

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        # You may not need to do that, we will use SERVER_ADDR and SERVER_PORT environment variable as IP and port
        #  (they are populated by Apache or nginx)
        my $device = Stancer::Device->new(ip => $ip, port => $port);

        my $card = Stancer::Card->new();
        my @dateparts = localtime;

        $card->number(valid_card_number_provider());
        $card->exp_month(random_integer(1, 12));
        $card->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card->cvc(sprintf '%d', random_integer(100, 999));

        my $customer = Stancer::Customer->new();

        $customer->email($customer_email);
        $customer->mobile($customer_mobile);
        $customer->name($customer_name);

        $payment->amount($amount);
        $payment->auth($return_url);
        $payment->card($card);
        $payment->currency($currency);
        $payment->customer($customer);
        $payment->description($description);
        $payment->device($device);

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($card->id, qr/^card_/sm, 'Card should have an id');
        like($customer->id, qr/^cust_/sm, 'Customer should have an id');
        is($customer->id, $customer_id, 'Customer should be recovered from previous call');

        isa_ok($payment->auth, 'Stancer::Auth', '$payment->auth');
        is($payment->auth->status, Stancer::Auth::Status::AVAILABLE, 'Auth should be available');
        like($payment->auth->redirect_url, qr/^https:\/\/3ds[.]/sm, 'Should have an authentication redirection URL');
        is($payment->auth->return_url, $return_url, 'Should have an authentication return URL');

        is($payment->status, undef, 'Should not have a status');
    }

    { # 9 tests
        note 'For payment page';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Authenticated payment page test, %.02f %s', $amount / 100, $currency;

        my @dateparts = localtime;

        my $customer = Stancer::Customer->new();

        $customer->name('John Doe');
        $customer->email('john.doe@example.com');

        $payment->amount($amount);
        $payment->auth(1);
        $payment->currency($currency);
        $payment->customer($customer);
        $payment->description($description);
        $payment->methods_allowed('card');

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($customer->id, qr/^cust_/sm, 'Customer should have an id');

        is($payment->method, undef, 'Should not have a method');
        is($payment->status, undef, 'Should not have a status');

        isa_ok($payment->auth, 'Stancer::Auth', '$payment->auth');
        is($payment->auth->status, Stancer::Auth::Status::REQUESTED, 'Auth should be requested');
        is($payment->auth->redirect_url, undef, 'Should have an authentication redirection URL');
        is($payment->auth->return_url, undef, 'Should have an authentication return URL');
    }

    { # 6 tests
        note 'For payment page without authentication';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Non authenticated payment page test, %.02f %s', $amount / 100, $currency;

        my @dateparts = localtime;

        my $customer = Stancer::Customer->new();

        $customer->name('John Doe');
        $customer->email('john.doe@example.com');

        $payment->amount($amount);
        $payment->auth(0);
        $payment->currency($currency);
        $payment->customer($customer);
        $payment->description($description);
        $payment->methods_allowed('card');

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($customer->id, qr/^cust_/sm, 'Customer should have an id');

        is($payment->auth, undef, 'Should not have a auth object');
        is($payment->method, undef, 'Should not have a method');
        is($payment->status, undef, 'Should not have a status');
    }

    { # 10 tests
        note 'Patch status';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Patch status test, %.02f %s', $amount / 100, $currency;

        my @dateparts = localtime;

        my $customer = Stancer::Customer->new(
            name => 'John Doe',
            email => 'john.doe@example.com',
        );

        $payment->amount($amount);
        $payment->currency($currency);
        $payment->customer($customer);
        $payment->description($description);

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($customer->id, qr/^cust_/sm, 'Customer should have an id');

        is($payment->method, undef, 'Should not have a method');
        is($payment->status, undef, 'Should not have a status');

        my $card = Stancer::Card->new(
            cvc => sprintf('%d', random_integer(100, 999)),
            exp_month => random_integer(1, 12),
            exp_year => random_integer(10) + $dateparts[5] + 1901,
            number => valid_card_number_provider(),
        );

        $payment->card($card);

        $payment->send();

        like($card->id, qr/^card_/sm, 'Card should have an id');

        is($payment->method, 'card', 'Should have a method now');
        is($payment->status, undef, 'But still no status');

        $payment->status(Stancer::Payment::Status::AUTHORIZE);
        $payment->send();

        is(
            $payment->status,
            Stancer::Payment::Status::AUTHORIZED,
            'At least, we have updated the status, can we do it again ?',
        );

        $payment->status(Stancer::Payment::Status::CAPTURE);
        $payment->send();

        is($payment->status, Stancer::Payment::Status::TO_CAPTURE, 'Payment is awaiting capture, all is good');
    }

    { # 6 tests
        note 'With unique ID';

        my $payment = Stancer::Payment->new();
        my $amount_1 = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description_1 = sprintf 'Payment with unique ID, %.02f %s', $amount_1 / 100, $currency;
        my $unique_id = sprintf '%08x-%04x-%04x-%04x-%012x', (
            random_integer(2 ** 32),
            random_integer(2 ** 16),
            random_integer(2 ** 16),
            random_integer(2 ** 16),
            random_integer(2 ** 48),
        );

        my $card = Stancer::Card->new();
        my @dateparts = localtime;

        $card->number(valid_card_number_provider());
        $card->exp_month(random_integer(1, 12));
        $card->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card->cvc(sprintf '%d', random_integer(100, 999));

        my $customer = Stancer::Customer->new();

        $customer->name('John Doe');
        $customer->email('john.doe@example.com');

        $payment->amount($amount_1);
        $payment->currency($currency);
        $payment->description($description_1);
        $payment->card($card);
        $payment->customer($customer);
        $payment->unique_id($unique_id);

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        like($card->id, qr/^card_/sm, 'Card should have an id');
        like($customer->id, qr/^cust_/sm, 'Customer should have an id');

        my $duplicate = Stancer::Payment->new();
        my $amount_2 = random_integer(50, 9999);
        my $description_2 = 'Duplicate payment, trigger by unique ID';

        $duplicate->amount($amount_2);
        $duplicate->currency($currency);
        $duplicate->card($card);
        $duplicate->customer($customer);
        $duplicate->description($description_2);
        $duplicate->unique_id($unique_id);

        my $message = 'Payment already exists, duplicate unique_id';

        throws_ok { $duplicate->send() } 'Stancer::Exceptions::Http::Conflict', 'Payment already exists';
        like($EVAL_ERROR->message, qr/^$message [(]paym_\w{24}[)]$/sm, 'Should indicate the error');
    }

    { # 4 tests
        note 'With IDs';

        my $payment = Stancer::Payment->new();
        my $amount = random_integer(50, 9999);
        my $currency = currencies_for_card_provider();
        my $description = sprintf 'Reuse a card, %.02f %s', $amount / 100, $currency;

        my $card = Stancer::Card->new($card_id);
        my $customer = Stancer::Customer->new($customer_id);

        $payment->amount($amount);
        $payment->currency($currency);
        $payment->description($description);
        $payment->card($card);
        $payment->customer($customer);

        $payment->send();

        like($payment->id, qr/^paym_/sm, 'Should have an id');
        isa_ok($payment->created, 'DateTime', '$payment->created');

        is($card->id, $card_id, 'Card should have the same id');
        is($customer->id, $customer_id, 'Customer should have the same id');
    }
}

1;
