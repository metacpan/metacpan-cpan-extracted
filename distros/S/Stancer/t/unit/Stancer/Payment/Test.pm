package Stancer::Payment::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use TestCase qw(:lwp); # Must be called first to initialize logs
use DateTime;
use DateTime::Span;
use English qw(-no_match_vars);
use Stancer::Auth::Status;
use Stancer::Card;
use Stancer::Core::Object::Stub;
use Stancer::Customer;
use Stancer::Device;
use Stancer::Payment;
use Stancer::Refund::Status;
use Stancer::Sepa;
use List::Util qw(shuffle);

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars, RequireExtendedFormatting)

sub instanciate : Tests(30) {
    { # 4 tests
        note 'Basic tests';

        my $object = Stancer::Payment->new();

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Payment->new()');

        ok($object->does('Stancer::Role::Amount::Write'), 'Should use Stancer::Role::Amount::Write');
        ok($object->does('Stancer::Role::Country'), 'Should use Stancer::Role::Country');
    }

    { # 12 tests
        note 'With card';

        my $id = random_string(29);
        my $amount = random_integer(50, 9999);
        my $auth = Stancer::Auth->new();
        my $card = Stancer::Card->new();
        my $customer = Stancer::Customer->new();
        my $currency = currencies_provider();
        my $description = random_string(60);
        my $order_id = random_string(10);
        my $unique_id = random_string(10);

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);
        my $device = Stancer::Device->new(ip => $ip, port => $port);

        my $object = Stancer::Payment->new(
            id => $id,
            amount => $amount,
            auth => $auth,
            card => $card,
            customer => $customer,
            currency => $currency,
            description => $description,
            device => $device,
            order_id => $order_id,
            unique_id => $unique_id,
        );

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->amount, $amount, 'Should have a value for `amount` property');
        is($object->auth, $auth, 'Should have a value for `auth` property');
        is($object->card, $card, 'Should have a value for `card` property');
        is($object->customer, $customer, 'Should have a value for `customer` property');
        is($object->currency, lc $currency, 'Should have a value for `currency` property');
        is($object->description, $description, 'Should have a value for `description` property');
        is($object->device, $device, 'Should have a value for `device` property');
        is($object->order_id, $order_id, 'Should have a value for `order_id` property');
        is($object->unique_id, $unique_id, 'Should have a value for `unique_id` property');

        my $exported = {
            amount => $amount,
            auth => {
                status => Stancer::Auth::Status::REQUEST,
            },
            card => {},
            customer => {},
            currency => lc $currency,
            description => $description,
            device => {
                ip => $ip,
                port => $port,
            },
            order_id => $order_id,
            unique_id => $unique_id,
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }

    { # 11 tests
        note 'With SEPA';

        my $id = random_string(29);
        my $amount = random_integer(50, 9999);
        my $customer = Stancer::Customer->new();
        my $currency = currencies_provider();
        my $description = random_string(60);
        my $order_id = random_string(10);
        my $sepa = Stancer::Sepa->new();
        my $auth_return_url = 'https://' . random_string(30);

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = $ip;
        local $ENV{SERVER_PORT} = $port;

        my $device = Stancer::Device->new();

        my $object = Stancer::Payment->new(
            id => $id,
            amount => $amount,
            auth => $auth_return_url,
            customer => $customer,
            currency => $currency,
            description => $description,
            device => $device,
            order_id => $order_id,
            sepa => $sepa,
        );

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->amount, $amount, 'Should have a value for `amount` property');
        is($object->auth->return_url, $auth_return_url, 'Should have a value for `auth` property');
        is($object->customer, $customer, 'Should have a value for `customer` property');
        is($object->currency, lc $currency, 'Should have a value for `currency` property');
        is($object->description, $description, 'Should have a value for `description` property');
        is($object->device, $device, 'Should have a value for `device` property');
        is($object->order_id, $order_id, 'Should have a value for `order_id` property');
        is($object->sepa, $sepa, 'Should have a value for `sepa` property');

        my $exported = {
            amount => $amount,
            auth => {
                return_url => $auth_return_url,
                status => Stancer::Auth::Status::REQUEST,
            },
            customer => {},
            currency => lc $currency,
            description => $description,
            device => {},
            order_id => $order_id,
            sepa => {},
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }

    { # 3 tests
        note 'With a string as instance parameter';

        $mock_response->set_always('decoded_content', undef);

        my $id = random_string(29);
        my $object = Stancer::Payment->new($id);

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->new($id)');

        is($object->id, $id, 'Should add a value for `id` property');

        ok($object->is_not_modified, 'Modified list should be empty');
    }
}

sub endpoint : Test {
    my $object = Stancer::Payment->new();

    is($object->endpoint, 'checkout');
}

sub auth : Tests(14) {
    { # 3 tests
        note 'With an Auth object';

        my $object = Stancer::Payment->new();
        my $auth = Stancer::Auth->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($auth);

        is($object->auth, $auth, 'Should be updated');

        my $exported = {
            auth => {
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 5 tests
        note 'With an url';

        my $object = Stancer::Payment->new();
        my $return_url = 'https://' . random_string(30);

        is($object->auth, undef, 'Undefined by default');

        $object->auth($return_url);

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->return_url, $return_url, 'Should update `return_url` attribute');
        is($object->auth->status, Stancer::Auth::Status::REQUEST, 'Should have a `request` status');

        my $exported = {
            auth => {
                return_url => $return_url,
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 4 tests
        note 'With a true value';

        my $object = Stancer::Payment->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($true);

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->status, Stancer::Auth::Status::REQUEST, 'Should have a `request` status');

        my $exported = {
            auth => {
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 2 tests
        note 'With a false value';

        my $object = Stancer::Payment->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($false);

        is($object->auth, undef, 'Still undefined');
    }
}

sub capture : Tests(3) {
    my $object = Stancer::Payment->new();

    is($object->capture, undef, 'Undefined by default');

    $object->capture(1);
    is($object->capture, 1);

    $object->capture(0);
    is($object->capture, 0);
}

sub card : Tests(4) {
    my $object = Stancer::Payment->new();
    my $card = Stancer::Card->new();

    is($object->card, undef, 'Undefined by default');

    $object->card($card);

    is($object->card, $card, 'Should be updated');
    is($object->method, 'card', 'Should update method');
    cmp_deeply_json($object, { card => {} }, 'Should be exported');
}

sub country : Tests(3) {
    my $object = Stancer::Payment->new();
    my $country = random_string(2);

    is($object->country, undef, 'Undefined by default');

    $object->hydrate(country => $country);

    is($object->country, $country, 'Should have a value');

    throws_ok { $object->country($country) } qr/country is a read-only accessor/sm, 'Not writable';
}

sub currency : Tests(21) {
    { # 2 tests * 10 entries => 20
        note 'Should alert if a method is asked with an unsupported currency';

        my $payment = Stancer::Payment->new();

        $payment->methods_allowed('sepa');

        for my $currency (currencies_for_card_provider()) {
            next if $currency eq 'EUR';

            throws_ok {
                $payment->currency($currency)
            } 'Stancer::Exceptions::InvalidCurrency', 'Should throw an error (' . $currency . ')';

            is(
                $EVAL_ERROR->message,
                'You can not ask for "' . $currency . '" with "sepa" method.',
                'Should indicate the error (' . $currency . ')',
            );
        }
    }

    { # 1 test * 1 entry
        note 'Should allow supported currencies';

        my $payment = Stancer::Payment->new();

        $payment->methods_allowed('sepa');

        for my $currency (currencies_for_sepa_provider()) {
            $payment->currency($currency);

            is($payment->currency, lc $currency, 'Should have new value');
        }
    }
}

sub customer : Tests(3) {
    my $object = Stancer::Payment->new();
    my $customer = Stancer::Customer->new();

    is($object->customer, undef, 'Undefined by default');

    $object->customer($customer);

    is($object->customer, $customer, 'Should be updated');
    cmp_deeply_json($object, { customer => {} }, 'Should be exported');
}

sub date_bank : Tests(5) {
    my $object = Stancer::Payment->new();
    my $date = random_integer(1_500_000_000, 1_600_000_000);

    my $config = Stancer::Config->init();
    my $delta = random_integer(1, 6);
    my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

    $config->default_timezone($tz);

    is($object->date_bank, undef, 'Undefined by default');

    throws_ok { $object->date_bank($date) } qr/date_bank is a read-only accessor/sm, 'Not writable';

    $object->hydrate(date_bank => $date);

    isa_ok($object->date_bank, 'DateTime', '$object->date_bank');
    is($object->date_bank->epoch, $date, 'Date is correct');
    is($object->date_bank->time_zone, $tz, 'Should have the same timezone now');
}

sub del : Tests(2) {
    my $object = Stancer::Payment->new();

    throws_ok { $object->del } 'Stancer::Exceptions::BadMethodCall', 'Always throw an error';
    is(
        $EVAL_ERROR->message,
        'You are not allowed to delete a payment, you need to refund it instead.',
        'Should indicate the error',
    );
}

sub description : Tests(3) {
    my $object = Stancer::Payment->new();
    my $description = random_string(60);

    is($object->description, undef, 'Undefined by default');

    $object->description($description);

    is($object->description, $description, 'Should be updated');
    cmp_deeply_json($object, { description => $description }, 'Should be exported');
}

sub device : Tests(3) {
    my $object = Stancer::Payment->new();
    my $ip = ipv4_provider();
    my $port = random_integer(1, 65_535);
    my $device = Stancer::Device->new(ip => $ip, port => $port);

    is($object->device, undef, 'Undefined by default');

    $object->device($device);

    is($object->device, $device, 'Should be updated');
    cmp_deeply_json($object, { device => { ip => $ip, port => $port } }, 'Should be exported');
}

sub hydrate : Tests(6) {
    { # 6 tests
        note 'Prevent using defaults values on Device';

        my $accept = random_string(100);
        my $agent = random_string(100);
        my $ip = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        my $languages = random_string(32);
        my $port = random_integer(1, 65_535);

        local $ENV{HTTP_ACCEPT} = $accept;
        local $ENV{HTTP_ACCEPT_LANGUAGE} = $languages;
        local $ENV{HTTP_USER_AGENT} = $agent;

        my $payment = Stancer::Payment->new();

        my $data = {
            device => {
                ip => $ip,
                port => $port,
            },
        };

        isa_ok($payment->hydrate($data), 'Stancer::Payment', '$payment->hydrate($data)');

        my $device = $payment->device;

        is($device->ip, $ip, 'Should have a value for `ip` property');
        is($device->port, $port, 'Should have a value for `port` property');

        is($device->http_accept, undef, 'Should not have a value for `http_accept` property');
        is($device->languages, undef, 'Should not have a value for `languages` property');
        is($device->user_agent, undef, 'Should not have a value for `user_agent` property');
    }
}

sub is_success : Tests(68) {
    { # 4 tests
        note 'Default values';

        my $payment = Stancer::Payment->new();

        is($payment->is_error, $false, 'undef => not an error');
        is($payment->is_success, $false, 'undef => not a success');

        is($payment->is_not_error, $true, 'undef => reverse for "error"');
        is($payment->is_not_success, $true, 'undef => reverse for "success"');
    }

    my @others = (
        Stancer::Payment::Status::CANCELED,
        Stancer::Payment::Status::DISPUTED,
        Stancer::Payment::Status::EXPIRED,
        Stancer::Payment::Status::FAILED,
    );

    { # 32 tests
        note 'With capture';

        { # 4 tests
            my $status = Stancer::Payment::Status::TO_CAPTURE;

            note 'With capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $true, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::CAPTURE_SENT;

            note 'With capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $true, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::CAPTURED;

            note 'With capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $true, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::AUTHORIZED;

            note 'With capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $true, status => $status);

            is($payment->is_error, $true, q/"/ . $status . '" => an error');
            is($payment->is_success, $false, q/"/ . $status . '" => not a success');

            is($payment->is_not_error, $false, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $true, q/"/ . $status . '" => reverse for "success"');
        }

        for my $status (@others) { # 4 tests x 4 status
            note 'With capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $true, status => $status);

            is($payment->is_error, $true, q/"/ . $status . '" => an error');
            is($payment->is_success, $false, q/"/ . $status . '" => not a success');

            is($payment->is_not_error, $false, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $true, q/"/ . $status . '" => reverse for "success"');
        }
    }

    { # 32 tests
        note 'Without capture';

        { # 4 tests
            my $status = Stancer::Payment::Status::TO_CAPTURE;

            note 'Without capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $false, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::CAPTURE_SENT;

            note 'Without capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $false, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::CAPTURED;

            note 'Without capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $false, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        { # 4 tests
            my $status = Stancer::Payment::Status::AUTHORIZED;

            note 'Without capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $false, status => $status);

            is($payment->is_error, $false, q/"/ . $status . '" => not an error');
            is($payment->is_success, $true, q/"/ . $status . '" => a success');

            is($payment->is_not_error, $true, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $false, q/"/ . $status . '" => reverse for "success"');
        }

        for my $status (@others) { # 4 tests x 4 status
            note 'Without capture, status is "' . $status . q/"/;

            my $payment = Stancer::Payment->new(capture => $false, status => $status);

            is($payment->is_error, $true, q/"/ . $status . '" => an error');
            is($payment->is_success, $false, q/"/ . $status . '" => not a success');

            is($payment->is_not_error, $false, q/"/ . $status . '" => reverse for "error"');
            is($payment->is_not_success, $true, q/"/ . $status . '" => reverse for "success"');
        }
    }
}

sub list : Tests(136) {
    { # 19 test
        note 'Basic tests';

        my $content1 = read_file '/t/fixtures/payment/list-1.json';
        my $content2 = read_file '/t/fixtures/payment/list-2.json';

        $mock_response->set_series('decoded_content', $content1, $content2);
        $mock_ua->clear();

        my $order_id = random_string(10);

        my $list = Stancer::Payment->list({order_id => $order_id});

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({order_id => $order_id})');

        my $payment;

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (1st)');
        is($payment->id, 'paym_JnU7xyTGJvxRWZuxvj78qz7e', 'Should be expected payment (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/order_id=$order_id/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (2nd)');
        is($payment->id, 'paym_p5tjCrXHy93xtVtVqvEJoC1c', 'Should be expected payment (2nd)');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (3rd)');
        is($payment->id, 'paym_5IptC9R1Wu2wKBR5cjM2so7k', 'Should be expected payment (3rd)');

        # Called a second time as the response says "has more"
        is($mock_ua->called_count('request'), 2, 'Should have done a second call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/order_id=$order_id/sm, 'Should use parameter');
        like($mock_request->url, qr/start=2/sm, 'Should start at 2 now');

        $payment = $list->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 2, 'No more calls');
    }

    { # 3 tests
        note 'No response from API';

        $mock_ua->clear();

        $mock_response->set_always('code', 404);
        $mock_response->set_always('decoded_content', q//);

        my $order_id = random_string(10);

        my $failed = Stancer::Payment->list(order_id => $order_id);

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        my $payment = $failed->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'One call');
    }

    { # 31 tests
        note 'Exceptions';

        my $date = DateTime->now->add(days => 1);
        my $i = 0;
        my $message = sub {
            my $count = ++$i;

            if ($count < 10) {
                $count = q/ / . $i;
            }

            return 'Should indicate the error (' . $count . q/)/;
        };

        note 'Exceptions - created';
        # 9 tests

        throws_ok {
            Stancer::Payment->list(created => time + 100)
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Created must be in the past (with integer)';
        is($EVAL_ERROR->message, 'Created must be in the past.', $message->());

        throws_ok {
            Stancer::Payment->list(created => $date)
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Created must be in the past (with DateTime)';
        is($EVAL_ERROR->message, 'Created must be in the past.', $message->());

        throws_ok {
            Stancer::Payment->list(created => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Should only works with integer and DateTime instance';
        is($EVAL_ERROR->message, 'Created must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Payment->list(created => Stancer::Card->new())
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Should not accept blessed variable other than DataTime';
        is($EVAL_ERROR->message, 'Created must be a position integer or a DateTime object.', $message->());

        isa_ok(
            Stancer::Payment->list(created => time - 1000),
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(created => $created)',
        );

        note 'Exceptions - created until';
        # 11 tests

        throws_ok {
            Stancer::Payment->list(created_until => time + 100)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be in the past (with integer)';
        is($EVAL_ERROR->message, 'Created until must be in the past.', $message->());

        throws_ok {
            Stancer::Payment->list(created_until => $date)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be in the past (with DateTime)';
        is($EVAL_ERROR->message, 'Created until must be in the past.', $message->());

        throws_ok {
            Stancer::Payment->list(created_until => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Should only works with integer and DateTime instance';
        is($EVAL_ERROR->message, 'Created until must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Payment->list(created_until => Stancer::Card->new())
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Should not accept blessed variable other than DataTime';
        is($EVAL_ERROR->message, 'Created until must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Payment->list(created => time - 100, created_until => time - 200)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be after created';
        is($EVAL_ERROR->message, 'Created until can not be before created.', $message->());

        isa_ok(
            Stancer::Payment->list(created_until => time - 1000),
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(created_until => $created_until)',
        );

        note 'Exceptions - limit';
        # 7 tests

        throws_ok {
            Stancer::Payment->list(limit => 0)
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be at least 1';
        is($EVAL_ERROR->message, 'Limit must be between 1 and 100.', $message->());

        throws_ok {
            Stancer::Payment->list(limit => 101)
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be maximum 100';
        is($EVAL_ERROR->message, 'Limit must be between 1 and 100.', $message->());

        throws_ok {
            Stancer::Payment->list(limit => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be an integer';
        is($EVAL_ERROR->message, 'Limit must be an integer.', $message->());

        isa_ok(
            Stancer::Payment->list(limit => random_integer(99) + 1),
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(limit => $limit)',
        );

        note 'Exceptions - start';
        # 5 tests

        throws_ok {
            Stancer::Payment->list(start => -1)
        } 'Stancer::Exceptions::InvalidSearchStart', 'Start must be positive';
        is($EVAL_ERROR->message, 'Start must be a positive integer.', $message->());

        throws_ok {
            Stancer::Payment->list(start => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchStart', 'Start must be an integer';
        is($EVAL_ERROR->message, 'Start must be a positive integer.', $message->());

        isa_ok(
            Stancer::Payment->list(start => random_integer(100)),
            'Stancer::Core::Iterator::Payment',
            'Should accept start filter otherwise',
        );

        note 'Exceptions - empty';
        # 4 tests

        throws_ok {
            Stancer::Payment->list()
        } 'Stancer::Exceptions::InvalidSearchFilter', 'Search filter are mandatory';
        is($EVAL_ERROR->message, 'Invalid search filters.', $message->());

        throws_ok {
            Stancer::Payment->list(foo => random_string(5))
        } 'Stancer::Exceptions::InvalidSearchFilter', 'Only known filters works';
        is($EVAL_ERROR->message, 'Invalid search filters.', $message->());

        note 'Exceptions - order_id';
        # 3 tests

        throws_ok {
            Stancer::Payment->list(order_id => random_string(50))
        } 'Stancer::Exceptions::InvalidSearchOrderId', 'Order ID must be 36 characters long maximum';
        is($EVAL_ERROR->message, 'Invalid order ID.', $message->());

        isa_ok(
            Stancer::Payment->list(order_id => random_string(36)),
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(order_id => $order_id)',
        );

        note 'Exceptions - unique_id';
        # 3 tests

        throws_ok {
            Stancer::Payment->list(unique_id => random_string(50))
        } 'Stancer::Exceptions::InvalidSearchUniqueId', 'Unique ID must be 36 characters long maximum';
        is($EVAL_ERROR->message, 'Invalid unique ID.', $message->());

        isa_ok(
            Stancer::Payment->list(unique_id => random_string(36)),
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(unique_id => $unique_id)',
        );
    }

    { # 11 tests
        note 'Other errors';

        $mock_ua->clear();

        my $error = random_string(10);
        my $failed;

        # die/croak

        ## no critic (RequireCarping)
        $mock_response->mock('decoded_content', sub { die $error });

        $failed = Stancer::Payment->list(order_id => random_string(10));

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        dies_ok { $failed->next() } 'Should still die';
        like($EVAL_ERROR, qr/$error/sm, 'Should have the message passed to die/croak');

        # Not Moo object
        $mock_response->mock('decoded_content', sub { die bless {} }); ## no critic (ClassHierarchies::ProhibitOneArgBless)

        $failed = Stancer::Payment->list(order_id => random_string(10));

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        dies_ok { $failed->next() } 'Not Moo object, should still die';

        # Not Throwable object
        $mock_response->mock('decoded_content', sub { die Stancer::Core::Object::Stub->new() });

        $failed = Stancer::Payment->list(order_id => random_string(10));

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        dies_ok { $failed->next() } 'Not Throwable object, should still die';

        # exceptions

        # 404

        $mock_response->set_always('code', 404);
        $mock_response->set_always('decoded_content', q//);
        $mock_response->set_always('is_success', 0);

        $failed = Stancer::Payment->list(order_id => random_string(10));

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        is($failed->next(), undef, 'Should not throw a not found error');

        # other one (409 for testing)

        $mock_response->set_always('code', 409);

        $failed = Stancer::Payment->list(order_id => random_string(10));

        isa_ok($failed, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(order_id => $order_id)');

        throws_ok { $failed->next() } 'Stancer::Exceptions::Http::Conflict', 'Should still throw a conflict';

        $mock_response->set_always('is_success', 1); # back to normal
    }

    { # 9 tests
        note 'Everything together';

        my %filters = (
            created => time - 1000,
            created_until => time - 100,
            limit => random_integer(99) + 1,
            order_id => random_string(36),
            start => random_integer(100),
            unique_id => random_string(36),
        );

        $mock_ua->clear();

        my $list = Stancer::Payment->list(%filters);

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list(%filters)');

        $list->next();

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/created=$filters{created}/sm, 'Should created parameter');
        like($mock_request->url, qr/limit=$filters{limit}/sm, 'Should limit parameter');
        like($mock_request->url, qr/order_id=$filters{order_id}/sm, 'Should order_id parameter');
        like($mock_request->url, qr/start=$filters{start}/sm, 'Should start parameter');
        like($mock_request->url, qr/unique_id=$filters{unique_id}/sm, 'Should unique_id parameter');

        unlike($mock_request->url, qr/created_until/sm, 'Should not have created_until parameter');
    }

    { # 14 test
        note 'Validate until';

        my $content = read_file '/t/fixtures/payment/list-3.json';

        $mock_response->set_always(decoded_content => $content);
        $mock_ua->clear();

        my $list = Stancer::Payment->list({created => 1_541_586_400, created_until => 1_541_586_569});

        isa_ok(
            $list,
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list(created => $created, created_until => $created_until)',
        );

        my $payment;

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (1st)');
        is($payment->id, 'paym_JnU7xyTGJvxRWZuxvj78qz7e', 'Should be expected payment (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/created=1541586400/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (2nd)');
        is($payment->id, 'paym_p5tjCrXHy93xtVtVqvEJoC1c', 'Should be expected payment (2nd)');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (3rd)');
        is($payment->id, 'paym_wQtKq1cnf1mWh6iLE5Ni0Wf1', 'Should be expected payment (3rd)');

        $payment = $list->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 14 test
        note 'Allow DateTime::Span with included dates';

        my $content = read_file '/t/fixtures/payment/list-3.json';

        $mock_response->set_always(decoded_content => $content);
        $mock_ua->clear();

        my $created = 1_541_586_400;
        my $date1 = DateTime->from_epoch(epoch => $created);
        my $date2 = DateTime->from_epoch(epoch => 1_541_586_569);
        my $span = DateTime::Span->from_datetimes(start => $date1, end => $date2);

        my $list = Stancer::Payment->list({created => $span});

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({created => $span})');

        my $payment;

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (1st)');
        is($payment->id, 'paym_JnU7xyTGJvxRWZuxvj78qz7e', 'Should be expected payment (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (2nd)');
        is($payment->id, 'paym_p5tjCrXHy93xtVtVqvEJoC1c', 'Should be expected payment (2nd)');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (3rd)');
        is($payment->id, 'paym_wQtKq1cnf1mWh6iLE5Ni0Wf1', 'Should be expected payment (3rd)');

        $payment = $list->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 10 test
        note 'Allow DateTime::Span with excluded dates';

        my $content = read_file '/t/fixtures/payment/list-3.json';

        $mock_response->set_always(decoded_content => $content);
        $mock_ua->clear();

        my $created = 1_541_586_400;
        my $date1 = DateTime->from_epoch(epoch => $created - 1);
        my $date2 = DateTime->from_epoch(epoch => 1_541_586_569);
        my $span = DateTime::Span->from_datetimes(after => $date1, before => $date2);

        my $list = Stancer::Payment->list({created => $span});

        isa_ok($list, 'Stancer::Core::Iterator::Payment', 'Stancer::Payment->list({created => $span})');

        my $payment;

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (1st)');
        is($payment->id, 'paym_JnU7xyTGJvxRWZuxvj78qz7e', 'Should be expected payment (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $payment = $list->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 14 test
        note 'A DateTime::Span will ignore created_until value';

        my $content = read_file '/t/fixtures/payment/list-3.json';

        $mock_response->set_always(decoded_content => $content);
        $mock_ua->clear();

        my $created = 1_541_586_400;
        my $date1 = DateTime->from_epoch(epoch => $created);
        my $date2 = DateTime->from_epoch(epoch => 1_541_586_569);
        my $span = DateTime::Span->from_datetimes(start => $date1, end => $date2);

        my $list = Stancer::Payment->list({created => $span, created_until => $created + 100});

        isa_ok(
            $list,
            'Stancer::Core::Iterator::Payment',
            'Stancer::Payment->list({created => $created, created_until => $created_until})',
        );

        my $payment;

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (1st)');
        is($payment->id, 'paym_JnU7xyTGJvxRWZuxvj78qz7e', 'Should be expected payment (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/checkout/sm, 'Should use payment endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (2nd)');
        is($payment->id, 'paym_p5tjCrXHy93xtVtVqvEJoC1c', 'Should be expected payment (2nd)');

        $payment = $list->next();

        isa_ok($payment, 'Stancer::Payment', '$list->next() (3rd)');
        is($payment->id, 'paym_wQtKq1cnf1mWh6iLE5Ni0Wf1', 'Should be expected payment (3rd)');

        $payment = $list->next();

        is($payment, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }
}

sub method : Tests(3) {
    my $object = Stancer::Payment->new();
    my $method = random_string(4);

    is($object->method, undef, 'Undefined by default');

    $object->hydrate(method => $method);

    is($object->method, $method, 'Should have a value');

    throws_ok { $object->method($method) } qr/method is a read-only accessor/sm, 'Not writable';
}

sub methods_allowed : Tests(100) {
    my @methods = shuffle qw(card sepa);
    my $method = $methods[0];

    { # 1 test
        my $payment = Stancer::Payment->new();

        is($payment->methods_allowed, undef, 'Undefined by default');
    }

    { # 4 tests
        note 'Should work with string';

        my $payment = Stancer::Payment->new();

        $payment->methods_allowed($method);

        my $results = $payment->methods_allowed;

        is(ref $results, 'ARRAY', 'Should return an array');
        ok(scalar @{$results} == 1, 'Should have only one allowed method');

        is($results->[0], $method, 'Should have expected value');
        cmp_deeply_json($payment, { methods_allowed => $results }, 'Should be exported');
    }

    { # 4 tests
        note 'Should work with array ref';

        my $payment = Stancer::Payment->new();

        $payment->methods_allowed(\@methods);

        my $results = $payment->methods_allowed;

        is(ref $results, 'ARRAY', 'Should return an array');
        ok(scalar @{$results} == scalar @methods, 'Should have as much entries as we passed');

        eq_or_diff($results, \@methods, 'Should have expected values');
        cmp_deeply_json($payment, { methods_allowed => $results }, 'Should be exported');
    }

    { # 91 tests
        { # 4 tests * 10 entries => 40
            note 'Should alert if a method is asked with an unsupported currency';

            my $payment = Stancer::Payment->new();

            for my $currency (currencies_for_card_provider()) {
                next if $currency eq 'EUR';

                $payment->currency($currency);

                throws_ok {
                    $payment->methods_allowed(\@methods)
                } 'Stancer::Exceptions::InvalidMethod', 'Should throw an error';
                is(
                    $EVAL_ERROR->message,
                    'You can not ask for "sepa" with "' . $currency . '" currency.',
                    'Should indicate the error',
                );

                throws_ok {
                    $payment->methods_allowed('sepa')
                } 'Stancer::Exceptions::InvalidMethod', 'Should throw an error';
                is(
                    $EVAL_ERROR->message,
                    'You can not ask for "sepa" with "' . $currency . '" currency.',
                    'Should indicate the error',
                );
            }
        }

        { # 4 tests * 11 entries => 44
            note 'Should still work with other method';

            my $payment = Stancer::Payment->new();
            my $local_method = 'card';

            for my $currency (currencies_for_card_provider()) {
                $payment->currency($currency);
                $payment->methods_allowed($local_method);

                my $results = $payment->methods_allowed;

                is(ref $results, 'ARRAY', 'Should return an array');
                ok(scalar @{$results} == 1, 'Should have only one allowed method');

                is($results->[0], $local_method, 'Should have expected value');
                cmp_deeply_json(
                    $payment,
                    { currency => lc $currency, methods_allowed => [$local_method] },
                    'Should be exported',
                );
            }
        }

        { # 4 tests * 1 entry
            note 'Should still work with supported currency';

            my $payment = Stancer::Payment->new();
            my $local_method = 'sepa';

            for my $currency (currencies_for_sepa_provider()) {
                $payment->currency($currency);
                $payment->methods_allowed($local_method);

                my $results = $payment->methods_allowed;

                is(ref $results, 'ARRAY', 'Should return an array');
                ok(scalar @{$results} == 1, 'Should have only one allowed method');

                is($results->[0], $local_method, 'Should have expected value');
                cmp_deeply_json(
                    $payment,
                    { currency => lc $currency, methods_allowed => [$local_method] },
                    'Should be exported',
                );
            }
        }

        { # 3 tests
            note 'Should work with automatic retrieval';

            my $content = read_file '/t/fixtures/payment/read.json', json => 1;

            $content->{currency} = 'EUR';
            $content->{methods_allowed} = \@methods;

            $mock_response->set_always(decoded_content => encode_json $content);

            my $payment = Stancer::Payment->new($content->{id});
            my $results = $payment->methods_allowed;

            is(ref $results, 'ARRAY', 'Should return an array');
            ok(scalar @{$results} == scalar @methods, 'Should have as much entries as we passed');

            eq_or_diff($results, \@methods, 'Should have expected values');
        }
    }
}

sub order_id : Tests(3) {
    my $object = Stancer::Payment->new();
    my $order_id = random_string(10);

    is($object->order_id, undef, 'Undefined by default');

    $object->order_id($order_id);

    is($object->order_id, $order_id, 'Should be updated');
    cmp_deeply_json($object, { order_id => $order_id }, 'Should be exported');
}

sub payment_page_url : Tests(9) {
    my $object = Stancer::Payment->new();

    $mock_ua->clear();

    $object->amount(random_integer(50, 99_999));
    $object->currency(currencies_provider());

    my $content = read_file '/t/fixtures/payment/create-no-method.json';
    my $date = DateTime->from_epoch(epoch => 1_562_085_759);

    $mock_response->set_always(decoded_content => $content);

    # We need a return url
    throws_ok { $object->payment_page_url } 'Stancer::Exceptions::MissingReturnUrl', 'A return url is mandatory';
    is(
        $EVAL_ERROR->message,
        'You must provide a return URL before going to the payment page.',
        'Should indicate the error',
    );

    $object->return_url('https://' . random_string(25));

    # We need an id
    throws_ok { $object->payment_page_url } 'Stancer::Exceptions::MissingPaymentId', 'A payment ID is mandatory';
    is(
        $EVAL_ERROR->message,
        'A payment ID is mandatory to obtain a payment page URL. Maybe you forgot to send the payment.',
        'Should indicate the error',
    );

    $object->send();

    # We need a public key
    throws_ok { $object->payment_page_url } 'Stancer::Exceptions::MissingApiKey', 'A public key is mandatory';
    is(
        $EVAL_ERROR->message,
        'A public API key is needed to obtain a payment page URL.',
        'Should indicate the error',
    );

    my $config = Stancer::Config->init();
    my $ptest = 'ptest_' . random_string(24);

    $config->ptest($ptest);

    my $url = $object->uri;
    my $endpoint = $object->endpoint;
    my $key = $config->public_key;
    my $version = q(v) . $config->version . q(/);

    $url =~ s/api/payment/gsm;
    $url =~ s/$version//gsm;
    $url =~ s/$endpoint/$key/gsm;

    is($object->payment_page_url, $url, 'Should have a valid URL');

    my $lang = random_string(2);
    my $full_url = $url . '?lang=' . $lang;
    my %params = (
        lang => $lang,
    );

    is($object->payment_page_url(%params), $full_url, 'Should allow HASH parameters');
    is($object->payment_page_url(\%params), $full_url, 'Should allow HASHREF parameters');
}

sub pay : Tests(37) {
    my $card = Stancer::Card->new();
    my $sepa = Stancer::Sepa->new();

    my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
    my $year = random_integer(15) + $y + 1901;
    my $month = random_integer(1, 12);

    my $bic = 'ILADFRPP'; # From fixtures
    my $cvc = random_integer(100, 999);
    my $iban = 'FR39 0000 0000 0000 0026 06'; # From fixtures
    my $name = random_string(10);
    my $number = '5555555555554444'; # To correspond to fixtures

    my $amount = random_integer(50, 99_999);

    $card->cvc($cvc);
    $card->name($name);
    $card->number($number);
    $card->exp_month($month);
    $card->exp_year($year);

    $sepa->bic($bic);
    $sepa->iban($iban);
    $sepa->name($name);

    my $ip = ipv4_provider();
    my $port = random_integer(1, 65_535);

    local $ENV{SERVER_ADDR} = $ip;
    local $ENV{SERVER_PORT} = $port;

    { # 18 tests
        note 'With card';

        $mock_ua->clear();

        my $content = read_file '/t/fixtures/payment/create-card.json';
        my $date = DateTime->from_epoch(epoch => 1_538_564_253);

        $mock_response->set_always(decoded_content => $content);

        my $object = Stancer::Payment->pay($amount, 'eur', $card);

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->pay($amount, $currency, $card)');

        is($object->is_success, 1, 'This payment was a success');
        is($card->id, 'card_xognFbZs935LMKJYeHyCAYUd', 'Card should have updated');

        is($object->amount, 100, 'Should have an amount');
        is($object->capture, 1, 'Should indicate a captured payment');
        is($object->card, $card, 'Should not change card object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'le test restfull v1', 'Should have a description');
        is($object->id, 'paym_KIVaaHi7G8QAYMQpQOYBrUQE', 'Should have an id');
        is($object->method, 'card', 'Should indicate a card payment');
        is($object->response, '00', 'Should have a response code');
        is($object->status, 'to_capture', 'Should have a status');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with %s "%s"', (
            $object->amount / 100,
            $object->currency,
            'MasterCard',
            $card->last4,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');
    }

    { # 18 tests
        note 'With SEPA';

        $mock_ua->clear();

        my $content = read_file '/t/fixtures/payment/create-sepa.json';
        my $date = DateTime->from_epoch(epoch => 1_538_564_504);

        $mock_response->set_always(decoded_content => $content);

        my $object = Stancer::Payment->pay($amount, 'eur', $sepa);

        isa_ok($object, 'Stancer::Payment', 'Stancer::Payment->pay($amount, $currency, $card)');

        is($object->is_success, 1, 'This payment was a success');
        is($sepa->id, 'sepa_oazGliEo6BuqUlyCzE42hcNp', 'Sepa should have updated');

        is($object->amount, 100, 'Should have an amount');
        is($object->capture, 1, 'Should indicate a captured payment');
        is($object->sepa, $sepa, 'Should not change sepa object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'le test restfull v1', 'Should have a description');
        is($object->id, 'paym_5IptC9R1Wu2wKBR5cjM2so7k', 'Should have an id');
        is($object->method, 'sepa', 'Should indicate a sepa payment');
        is($object->response, '00', 'Should have a response code');
        is($object->status, 'to_capture', 'Should have a status');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with IBAN "%s" / BIC "%s"', (
            $object->amount / 100,
            $object->currency,
            $sepa->last4,
            $sepa->bic,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');
    }

    # We need a card or a sepa account
    throws_ok {
        Stancer::Payment->pay($amount, 'eur')
    } 'Stancer::Exceptions::MissingPaymentMethod', 'A payment method is mandatory';
}

sub populate : Tests(12) {
    my %props = (
        amount => 3406,
        country => 'FR',
        currency => 'eur',
        method => 'card',
        description => 'Fake payment',
        order_id => '815730837',
        response => '00',
        status => 'to_capture',
        created => 1_538_492_150,
        card => 'card_jSmaDq5t5lMnz6H8tCZ0AbRG',
    );

    my $content = read_file '/t/fixtures/payment/read.json';

    $mock_response->set_always(decoded_content => $content);

    foreach my $key (keys %props) {
        my $object = Stancer::Payment->new('paym_SKMLflt8NBATuiUzgvTYqsw5');

        if ($key eq 'created') {
            isa_ok($object->created, 'DateTime', '$object->created');
            is($object->created->epoch, $props{$key}, 'created should have right value');
        } elsif ($key eq 'card') {
            isa_ok($object->card, 'Stancer::Card', '$object->card');
            is($object->card->id, $props{$key}, 'created should have right value');
        } else {
            is($object->$key, $props{$key}, $key . ' should trigger populate');
        }
    }
}

sub refund : Tests(41) {
    { # 39 tests
        note 'Basic test';

        my $id = 'paym_SKMLflt8NBATuiUzgvTYqsw5';
        my $payment = Stancer::Payment->new($id);
        my $refunds;

        my $payment_content = read_file '/t/fixtures/payment/read.json';
        my $refund_content_1 = read_file '/t/fixtures/refunds/read.json', json => 1;
        my $refund_content_2 = read_file '/t/fixtures/refunds/read.json', json => 1;

        my $paid = 3406;
        my $amount_1 = random_integer($paid / 2) + 50;
        my $amount_2 = $paid - $amount_1;
        my $currency = 'EUR';

        my $id_1 = random_string(29);
        my $id_2 = random_string(29);

        $refund_content_1->{amount} = $amount_1;
        $refund_content_2->{amount} = $amount_2;
        $refund_content_1->{id} = $id_1;
        $refund_content_2->{id} = $id_2;

        $mock_response->set_series(
            'decoded_content',
            $payment_content,
            encode_json $refund_content_1,
            encode_json $refund_content_2,
        );
        $mock_ua->clear();

        $refunds = $payment->refunds;

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 0, 'Should be empty');

        my $too_much = random_integer(1, 1000) + $paid;
        my $not_enough = random_integer(49);

        throws_ok {
            $payment->refund($too_much);
        } 'Stancer::Exceptions::InvalidAmount', 'Can not refund more than paid';
        is(
            $EVAL_ERROR->message,
            'You are trying to refund (' . sprintf('%.02f', $too_much / 100) . ' EUR) more than paid (34.06 EUR).',
            'Should indicate the error',
        );

        throws_ok {
            $payment->refund($not_enough);
        } 'Stancer::Exceptions::InvalidAmount', 'Can not refund less than 50 €/$/£';
        is(
            $EVAL_ERROR->message,
            'Amount must be an integer and at least 50, "' . $not_enough . '" given.',
            'Should indicate the error',
        );

        # First refund

        isa_ok($payment->refund($amount_1), 'Stancer::Payment', '$payment->refund($amount)');

        $refunds = $payment->refunds;

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 1, 'Should have one refund');

        is($refunds->[0]->id, $id_1, 'Should return first refund');
        is($refunds->[0]->amount, $amount_1, sprintf 'Should be a %.2f %s refund', $amount_1 / 100, 'EUR');

        ok($payment->is_not_modified, 'Should not update modified list on payment');
        ok($refunds->[0]->is_not_modified, 'Should not update modified flag on refunds');
        is($refunds->[0]->payment, $payment, 'Should have same instance of orignal payment');

        # Can not refund more than refundable amout

        my $pattern = 'You are trying to refund (%.02f EUR) more than paid (%.02f EUR with %.02f EUR already refunded).';
        my $message = sprintf $pattern, $paid / 100, $paid / 100, $amount_1 / 100;

        throws_ok {
            $payment->refund($paid)
        } 'Stancer::Exceptions::InvalidAmount', 'Can not refund more than refundable';
        is($EVAL_ERROR->message, $message, 'Should indicate the error');

        # Second refund, without amount

        isa_ok($payment->refund(), 'Stancer::Payment', '$payment->refund()');

        $refunds = $payment->refunds;

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 2, 'Should have two refunds');

        is($refunds->[0]->id, $id_1, 'Should return first refund');
        is($refunds->[1]->id, $id_2, 'Should return second refund');
        is($refunds->[1]->amount, $amount_2, sprintf 'Should be a %.2f %s refund', $amount_2 / 100, 'EUR');
        is($refunds->[1]->payment, $payment, 'Should have same instance of orignal payment');

        ok($payment->is_not_modified, 'Should not update modified flag on payment');
        ok($refunds->[0]->is_not_modified, 'Should not update modified flag on refunds (1)');
        ok($refunds->[1]->is_not_modified, 'Should not update modified flag on refunds (2)');

        # Logs
        my $messages = $log->msgs;

        is(scalar @{$messages}, 7, 'Should have logged seven message'); # First one is a GET on payment

        is($messages->[1]->{level}, 'debug', 'Should be a debug message');
        is($messages->[1]->{message}, 'API call: POST https://api.stancer.com/v1/refunds', 'Should log API call');

        is($messages->[2]->{level}, 'info', 'Should be a info message');
        is(
            $messages->[2]->{message},
            'Refund ' . $refunds->[0]->id . ' created',
            'Should indicate refund creation (1)',
        );

        is($messages->[3]->{level}, 'info', 'Should be a info message');
        is(
            $messages->[3]->{message},
            sprintf('Refund of %.02f %s on payment "%s"', $amount_1 / 100, $currency, $id),
            'Should indicate a refund (1)',
        );

        is($messages->[4]->{level}, 'debug', 'Should be a debug message');
        is($messages->[4]->{message}, 'API call: POST https://api.stancer.com/v1/refunds', 'Should log API call');

        is($messages->[5]->{level}, 'info', 'Should be a info message');
        is(
            $messages->[5]->{message},
            'Refund ' . $refunds->[1]->id . ' created',
            'Should indicate refund creation (1)',
        );

        is($messages->[6]->{level}, 'info', 'Should be a info message');
        is(
            $messages->[6]->{message},
            sprintf('Refund of %.02f %s on payment "%s"', $amount_2 / 100, $currency, $id),
            'Should indicate a refund (2)',
        );
    }

    { # 2 tests
        note 'Invalid refund';

        my $payment = Stancer::Payment->new;

        throws_ok { $payment->refund() } 'Stancer::Exceptions::MissingPaymentId', 'Can not refund payment without ID';
        is(
            $EVAL_ERROR->message,
            'A payment ID is mandatory. Maybe you forgot to send the payment.',
            'Should indicate the error',
        );
    }
}

sub refundable_amount : Tests(6) {
    my $payment_content = read_file '/t/fixtures/payment/read.json';
    my $refund_content_1 = read_file '/t/fixtures/refunds/read.json', json => 1;
    my $refund_content_2 = read_file '/t/fixtures/refunds/read.json', json => 1;

    my $paid = 3406;
    my $amount_1 = random_integer(50, $paid / 3);
    my $amount_2 = random_integer(50, $paid / 3);

    $refund_content_1->{amount} = $amount_1;
    $refund_content_2->{amount} = $amount_2;

    $mock_response->set_series(
        'decoded_content',
        $payment_content,
        encode_json $refund_content_1,
        encode_json $refund_content_2,
    );

    {
        note 'Without data';

        my $payment = Stancer::Payment->new;
        my $refunds;

        is($payment->refundable_amount, undef, 'Should return undef');
    }

    {
        note 'With data';

        my $payment = Stancer::Payment->new('paym_SKMLflt8NBATuiUzgvTYqsw5');

        is($payment->refundable_amount, $paid, 'Should return whole amount without refund');

        $payment->refund($amount_1);

        is($payment->amount, $paid, 'Should not change amount (1st call)');
        is($payment->refundable_amount, $paid - $amount_1, 'Should return not refunded amount (1st call)');

        $payment->refund($amount_2);

        is($payment->amount, $paid, 'Should not change amount (2nd call)');
        is($payment->refundable_amount, $paid - $amount_1 - $amount_2, 'Should return not refunded amount (2nd call)');
    }
}

sub refunds : Tests(10) {
    my $payment = Stancer::Payment->new('paym_FQgpGVJpyGPVJVIuQtO3zy6i');

    my $content = read_file '/t/fixtures/payment/with-refunds.json';

    $mock_response->set_series('decoded_content', $content);

    my $refunds = $payment->refunds;

    is(ref $refunds, 'ARRAY', 'Should return an array');
    ok(scalar @{$refunds} == 2, 'Should have two refunds');

    is($refunds->[0]->id, 'refd_4DjKQJefwKnWFjbttj1Sy0iP', 'Should have an id (1st refund)');
    is($refunds->[0]->amount, 4810, 'Should have an amount (1st refund)');
    is($refunds->[0]->currency, 'usd', 'Should have a currency (1st refund)');
    is($refunds->[0]->status, Stancer::Refund::Status::TO_REFUND, 'Should have a status (1st refund)');

    is($refunds->[1]->id, 'refd_THvpT5pWZMnDFD47GsanGan9', 'Should have an id (2nd refund)');
    is($refunds->[1]->amount, 3000, 'Should have an amount (2nd refund)');
    is($refunds->[1]->currency, 'usd', 'Should have a currency (2nd refund)');
    is($refunds->[1]->status, Stancer::Refund::Status::REFUNDED, 'Should have a status (2nd refund)');
}

sub response : Tests(3) {
    my $object = Stancer::Payment->new();
    my $response = random_string(2);

    is($object->response, undef, 'Undefined by default');

    $object->hydrate(response => $response);

    is($object->response, $response, 'Should have a value');

    throws_ok { $object->response($response) } qr/response is a read-only accessor/sm, 'Not writable';
}

sub response_author : Tests(3) {
    my $object = Stancer::Payment->new();
    my $response_author = random_string(6);

    is($object->response_author, undef, 'Undefined by default');

    $object->hydrate(response_author => $response_author);

    is($object->response_author, $response_author, 'Should have a value');

    throws_ok {
        $object->response_author($response_author)
    } qr/response_author is a read-only accessor/sm, 'Not writable';
}

sub return_url : Tests(4) {
    my $object = Stancer::Payment->new();
    my $return_url = 'https://' . random_string(10);
    my $http_return = 'http://' . random_string(10);

    is($object->return_url, undef, 'Undefined by default');

    $object->return_url($return_url);

    is($object->return_url, $return_url, 'Should be updated');
    cmp_deeply_json($object, { return_url => $return_url }, 'Should be exported');

    dies_ok { $object->return_url($http_return) } 'Throw error for non-HTTPS URL';
}

sub send_global : Tests(221) {
    { # 40 tests
        note 'With card';

        my $object = Stancer::Payment->new();
        my $card = Stancer::Card->new();

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $bad_year = $y + 1900 - random_integer(15) - 1;
        my $year = random_integer(15) + $y + 1901;
        my $month = random_integer(1, 12);

        my $amount = random_integer(50, 99_999);
        my $currency = 'eur';
        my $name = random_string(10);
        my $number = '5555555555554444'; # To correspond to fixtures
        my $cvc = random_integer(100, 999);

        $card->hydrate({
            name => $name,
            number => $number,
            exp_year => $bad_year,
            exp_month => $month,
            cvc => $cvc,
        });

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = $ip;
        local $ENV{SERVER_PORT} = $port;

        $mock_ua->clear();

        $object->card($card);

        # We need an amount
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidAmount', 'A valid amount is mandatory';

        $object->amount($amount);

        # We need a currency
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidCurrency', 'A valid currency is mandatory';

        $object->currency($currency);

        # We need a not expired card
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidCardExpiration', 'A not expired card is mandatory';

        $card->exp_year($year);

        is($mock_ua->called('request'), 0, 'Exceptions prevent API calls');

        my $content = read_file '/t/fixtures/payment/create-card.json';
        my $date = DateTime->from_epoch(epoch => 1_538_564_253);
        my $req_content = $object->toJSON;

        $mock_response->set_always(decoded_content => $content);
        $mock_request->mock(content => sub {
            my $this = shift;
            my $value = shift;

            if ($value) {
                $req_content = $value;
            }

            return $req_content;
        });

        $object->send();

        ok($object->is_success, 'This payment was a success');
        is($card->id, 'card_xognFbZs935LMKJYeHyCAYUd', 'Card should have updated');

        is($object->amount, 100, 'Should have an amount');
        ok($object->capture, 'Should indicate a captured payment');
        is($object->card, $card, 'Should not change card object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'le test restfull v1', 'Should have a description');
        is($object->id, 'paym_KIVaaHi7G8QAYMQpQOYBrUQE', 'Should have an id');
        is($object->method, 'card', 'Should indicate a card payment');
        is($object->response, '00', 'Should have a response code');
        is($object->status, 'to_capture', 'Should have a status');

        isa_ok($object->customer, 'Stancer::Customer', '$object->customer');
        # send will not do it, we check it because we fake a return containing a customer

        is($object->customer->id, 'cust_9Cle7TXKkjhwqcWx4Kl5cQYk', 'Customer should have an id');

        ok($object->is_not_modified, 'Should not be modified anymore');
        ok($card->is_not_modified, 'Card too');
        ok($object->customer->is_not_modified, 'Customer too');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with %s "%s"', (
            $object->amount / 100,
            $object->currency,
            'MasterCard',
            $card->last4,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 4, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{card}, 'HASH', 'Should have passed "card"');
            is($data->{card}->{cvc}, $cvc, 'Card should have "cvc" property');
            is($data->{card}->{exp_month}, $month, 'Card should have "exp_month" property');
            is($data->{card}->{exp_year}, $year, 'Card should have "exp_year" property');
            is($data->{card}->{name}, $name, 'Card should have "name" property');
            is($data->{card}->{number}, $number, 'Card should have "number" property');

            is(not(defined $data->{auth}), 1, 'Should not have passed "auth"');

            is(ref $data->{device}, 'HASH', 'Should have passed "device"');
            is($data->{device}->{ip}, $ip, 'Auth should have "ip" property');
            is($data->{device}->{port}, $port, 'Auth should have "port" property');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Calls
        my $call = Stancer::Config->init()->last_call;
        my $json = decode_json $call->request->content;

        is($json->{card}->{number}, 'xxxxxxxxxxxx4444', 'Should not show real card number');

        $mock_request->unmock('content');
    }

    { # 26 tests
        note 'With SEPA';

        my $object = Stancer::Payment->new();
        my $sepa = Stancer::Sepa->new();

        my $amount = random_integer(50, 99_999);
        my $currency = 'eur';
        my $name = random_string(10);
        my $bic = 'ILADFRPP'; # From fixtures
        my $iban = 'FR39 0000 0000 0000 0026 06'; # From fixtures
        my $spaceless = $iban;

        $spaceless =~s/\s//gsm;

        $sepa->hydrate({
            name => $name,
            bic => $bic,
            iban => $iban,
        });

        $mock_ua->clear();

        $object->sepa($sepa);

        # We need an amount
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidAmount', 'A valid amount is mandatory';

        $object->amount($amount);

        # We need a currency
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidCurrency', 'A valid currency is mandatory';

        $object->currency($currency);

        is($mock_ua->called('request'), 0, 'Exceptions prevent API calls');

        my $content = read_file '/t/fixtures/payment/create-sepa.json';
        my $date = DateTime->from_epoch(epoch => 1_538_564_504);
        my $req_content = $object->toJSON;

        $mock_response->set_always(decoded_content => $content);
        $mock_request->mock(request => sub {
            my ($this, $value) = @_;

            if ($value) {
                $req_content = $value;
            }

            return $req_content;
        });

        $object->send();

        is($object->is_success, 1, 'This payment was a success');
        is($sepa->id, 'sepa_oazGliEo6BuqUlyCzE42hcNp', 'Sepa should have updated');

        is($object->amount, 100, 'Should have an amount');
        is($object->capture, 1, 'Should indicate a captured payment');
        is($object->sepa, $sepa, 'Should not change sepa object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'le test restfull v1', 'Should have a description');
        is($object->id, 'paym_5IptC9R1Wu2wKBR5cjM2so7k', 'Should have an id');
        is($object->method, 'sepa', 'Should indicate a sepa payment');
        is($object->response, '00', 'Should have a response code');
        is($object->status, 'to_capture', 'Should have a status');

        isa_ok($object->customer, 'Stancer::Customer', '$object->customer');
        # send will not do it, we check it because we fake a return containing a customer

        is($object->customer->id, 'cust_9Cle7TXKkjhwqcWx4Kl5cQYk', 'Customer should have an id');

        ok($object->is_not_modified, 'Should have an empty modified list');
        ok($sepa->is_not_modified, 'Sepa too');
        ok($object->customer->is_not_modified, 'Customer too');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with IBAN "%s" / BIC "%s"', (
            $object->amount / 100,
            $object->currency,
            $sepa->last4,
            $sepa->bic,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 3, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{sepa}, 'HASH', 'Should have passed "sepa"');
            is($data->{sepa}->{name}, $name, 'SEPA should have "name" property');
            is($data->{sepa}->{bic}, $bic, 'SEPA should have "bic" property');
            is($data->{sepa}->{iban}, $spaceless, 'SEPA should have "iban" property');

            is(not(defined $data->{auth}), 1, 'Should not have passed "auth"');
            is(not(defined $data->{device}), 1, 'Should not have passed "device"');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Calls
        my $call = Stancer::Config->init()->last_call;
        my $json = decode_json $call->request->content;

        is($json->{sepa}->{iban}, 'xxxxxxxxxxxxxxxxxx2606', 'Should not show real IBAN');

        $mock_request->unmock('content');
    }

    { # 16 tests
        note 'Without any method';

        my $object = Stancer::Payment->new();

        $mock_ua->clear();

        # We need an amount
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidAmount', 'A valid amount is mandatory';

        $object->amount(random_integer(50, 99_999));

        # We need a currency
        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidCurrency', 'A valid currency is mandatory';

        $object->currency(currencies_provider());

        is($mock_ua->called('request'), 0, 'Exceptions prevent API calls');

        my $content = read_file '/t/fixtures/payment/create-no-method.json';
        my $date = DateTime->from_epoch(epoch => 1_562_085_759);

        $mock_response->set_always(decoded_content => $content);

        $object->send();

        is($object->amount, 10_000, 'Should have an amount');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'Test payment without any card or sepa account', 'Should have a description');
        is($object->id, 'paym_pia9ossoqujuFFbX0HdS3FLi', 'Should have an id');
        is($object->method, undef, 'Should not indicate a method');
        is($object->response, undef, 'Should not have a response code');
        is($object->status, undef, 'Should not have a status');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s without payment method', (
            $object->amount / 100,
            $object->currency,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');
    }

    { # 42 tests
        note 'With authentication return URL';

        my $object = Stancer::Payment->new();
        my $card = Stancer::Card->new();

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $year = random_integer(15) + $y + 1901;
        my $month = random_integer(1, 12);

        my $name = random_string(10);
        my $number = '5555555555554444'; # To correspond to fixtures
        my $cvc = random_integer(100, 999);

        my $amount = random_integer(50, 99_999);
        my $currency = currencies_provider();
        my $return_url = 'https://www.example.org/?' . random_string(50);

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        $card->hydrate({
            name => $name,
            number => $number,
            exp_year => $year,
            exp_month => $month,
            cvc => $cvc,
        });

        $mock_ua->clear();

        $object->amount($amount);
        $object->auth($return_url);
        $object->card($card);
        $object->currency($currency);

        my $content = read_file '/t/fixtures/payment/create-card-auth.json';
        my $date = DateTime->from_epoch(epoch => 1_567_094_428);
        my $req_content = $object->toJSON;

        $mock_response->set_always(decoded_content => $content);
        $mock_request->mock(content => sub {
            my $this = shift;
            my $value = shift;

            if ($value) {
                $req_content = $value;
            }

            return $req_content;
        });

        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidIpAddress', 'IP address is mandatory';

        local $ENV{SERVER_ADDR} = $ip;

        throws_ok { $object->send() } 'Stancer::Exceptions::InvalidPort', 'Port is mandatory';

        local $ENV{SERVER_PORT} = $port;

        $object->send();

        is($card->id, 'card_xognFbZs935LMKJYeHyCAYUd', 'Card should have updated');

        is($object->amount, 1337, 'Should have an amount');
        is($object->capture, 1, 'Should indicate a captured payment');
        is($object->card, $card, 'Should not change card object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'Auth test', 'Should have a description');
        is($object->id, 'paym_RMLytyx2xLkdXkATKSxHOlvC', 'Should have an id');
        is($object->method, 'card', 'Should indicate a card payment');
        is($object->response, undef, 'Should not have a response code');
        is($object->status, undef, 'Should not have a status');

        isa_ok($object->customer, 'Stancer::Customer', '$object->customer');
        # send will not do it, we check it because we fake a return containing a customer

        is($object->customer->id, 'cust_bZ7e17VDlD252dkgHg7JJgBa', 'Customer should have an id');

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->return_url, 'https://www.free.fr', 'Should have a return URL for authentication');
        is($object->auth->status, Stancer::Auth::Status::AVAILABLE, 'Should have an authentication status');

        ok($object->is_not_modified, 'Should have an empty modified list');
        ok($card->is_not_modified, 'Card too');
        ok($object->customer->is_not_modified, 'Customer too');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with %s "%s"', (
            $object->amount / 100,
            $object->currency,
            'MasterCard',
            $card->last4,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 5, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{card}, 'HASH', 'Should have passed "card"');
            is($data->{card}->{cvc}, $cvc, 'Card should have "cvc" property');
            is($data->{card}->{exp_month}, $month, 'Card should have "exp_month" property');
            is($data->{card}->{exp_year}, $year, 'Card should have "exp_year" property');
            is($data->{card}->{name}, $name, 'Card should have "name" property');
            is($data->{card}->{number}, $number, 'Card should have "number" property');

            is(ref $data->{auth}, 'HASH', 'Should have passed "auth"');
            is($data->{auth}->{return_url}, $return_url, 'Auth should have "return_url" property');
            is($data->{auth}->{status}, Stancer::Auth::Status::REQUEST, 'Auth should have a "request" status');

            is(ref $data->{device}, 'HASH', 'Should have passed "device"');
            is($data->{device}->{ip}, $ip, 'Auth should have "ip" property');
            is($data->{device}->{port}, $port, 'Auth should have "port" property');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Calls
        my $call = Stancer::Config->init()->last_call;
        my $json = decode_json $call->request->content;

        is($json->{card}->{number}, 'xxxxxxxxxxxx4444', 'Should not show real card number');

        $mock_request->unmock('content');
    }

    { # 19 tests
        note 'With authentication for payment page';

        my $object = Stancer::Payment->new();

        $mock_ua->clear();

        my $amount = random_integer(50, 99_999);
        my $currency = currencies_provider();

        $object->amount($amount);
        $object->auth(1);
        $object->currency($currency);

        my $content = read_file '/t/fixtures/payment/create-no-method-auth.json';
        my $date = DateTime->from_epoch(epoch => 1_567_094_428);

        $mock_response->set_always(decoded_content => $content);
        $mock_request->set_always(content => q//);

        $object->send();

        is($object->amount, 1337, 'Should have an amount');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'Auth test', 'Should have a description');
        is($object->id, 'paym_RMLytyx2xLkdXkATKSxHOlvC', 'Should have an id');
        is($object->method, undef, 'Should not indicate a method');
        is($object->response, undef, 'Should not have a response code');
        is($object->status, undef, 'Should not have a status');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s without payment method', (
            $object->amount / 100,
            $object->currency,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 3, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{auth}, 'HASH', 'Should have passed "auth"');
            is($data->{auth}->{return_url}, undef, 'Auth should not have "return_url" property');
            is($data->{auth}->{status}, Stancer::Auth::Status::REQUEST, 'Auth should have a "request" status');
        }
    }

    { # 40 tests
        note 'With auth and device';

        my $config = Stancer::Config->init();
        my $nb_calls = scalar @{ $config->calls };

        $config->debug(0);

        my $object = Stancer::Payment->new();
        my $card = Stancer::Card->new();

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $year = random_integer(15) + $y + 1901;
        my $month = random_integer(1, 12);

        my $name = random_string(10);
        my $number = '5555555555554444'; # To correspond to fixtures
        my $cvc = random_integer(100, 999);

        my $amount = random_integer(50, 99_999);
        my $currency = currencies_provider();
        my $return_url = 'https://www.example.org/?' . random_string(50);

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);
        my $device = Stancer::Device->new(ip => $ip, port => $port);

        $card->hydrate({
            name => $name,
            number => $number,
            exp_year => $year,
            exp_month => $month,
            cvc => $cvc,
        });

        $mock_ua->clear();

        $object->amount($amount);
        $object->auth($return_url);
        $object->card($card);
        $object->currency($currency);
        $object->device($device);

        my $content = read_file '/t/fixtures/payment/create-card-auth.json';
        my $date = DateTime->from_epoch(epoch => 1_567_094_428);
        my $req_content = $object->toJSON;

        $mock_response->set_always(decoded_content => $content);
        $mock_request->mock(content => sub {
            my $this = shift;
            my $value = shift;

            if ($value) {
                $req_content = $value;
            }

            return $req_content;
        });

        $object->send();

        is($card->id, 'card_xognFbZs935LMKJYeHyCAYUd', 'Card should have updated');

        is($object->amount, 1337, 'Should have an amount');
        is($object->capture, 1, 'Should indicate a captured payment');
        is($object->card, $card, 'Should not change card object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'Auth test', 'Should have a description');
        is($object->id, 'paym_RMLytyx2xLkdXkATKSxHOlvC', 'Should have an id');
        is($object->method, 'card', 'Should indicate a card payment');
        is($object->response, undef, 'Should not have a response code');
        is($object->status, undef, 'Should not have a status');

        isa_ok($object->customer, 'Stancer::Customer', '$object->customer');
        # send will not do it, we check it because we fake a return containing a customer

        is($object->customer->id, 'cust_bZ7e17VDlD252dkgHg7JJgBa', 'Customer should have an id');

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->return_url, 'https://www.free.fr', 'Should have a return URL for authentication');
        is($object->auth->status, Stancer::Auth::Status::AVAILABLE, 'Should have an authentication status');

        ok($object->is_not_modified, 'Should have an empty modified list');
        ok($card->is_not_modified, 'Card too');
        ok($object->customer->is_not_modified, 'Customer too');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with %s "%s"', (
            $object->amount / 100,
            $object->currency,
            'MasterCard',
            $card->last4,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 5, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{card}, 'HASH', 'Should have passed "card"');
            is($data->{card}->{cvc}, $cvc, 'Card should have "cvc" property');
            is($data->{card}->{exp_month}, $month, 'Card should have "exp_month" property');
            is($data->{card}->{exp_year}, $year, 'Card should have "exp_year" property');
            is($data->{card}->{name}, $name, 'Card should have "name" property');
            is($data->{card}->{number}, $number, 'Card should have "number" property');

            is(ref $data->{auth}, 'HASH', 'Should have passed "auth"');
            is($data->{auth}->{return_url}, $return_url, 'Auth should have "return_url" property');
            is($data->{auth}->{status}, Stancer::Auth::Status::REQUEST, 'Auth should have a "request" status');

            is(ref $data->{device}, 'HASH', 'Should have passed "device"');
            is($data->{device}->{ip}, $ip, 'Auth should have "ip" property');
            is($data->{device}->{port}, $port, 'Auth should have "port" property');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Calls
        is(scalar @{ $config->calls }, $nb_calls, 'No call list without debug mode');
    }

    { # 34 tests
        note 'Without authentication, device or environment variables to create a device';

        my $config = Stancer::Config->init();
        my $nb_calls = scalar @{ $config->calls };

        $config->debug(0);

        my $object = Stancer::Payment->new();
        my $card = Stancer::Card->new();

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $year = random_integer(15) + $y + 1901;
        my $month = random_integer(1, 12);

        my $amount = random_integer(50, 99_999);
        my $currency = 'eur';
        my $name = random_string(10);
        my $number = '5555555555554444'; # To correspond to fixtures
        my $cvc = random_integer(100, 999);

        $card->hydrate({
            name => $name,
            number => $number,
            exp_year => $year,
            exp_month => $month,
            cvc => $cvc,
        });

        $mock_ua->clear();

        $object->amount($amount);
        $object->card($card);
        $object->currency($currency);

        my $content = read_file '/t/fixtures/payment/create-card.json';
        my $date = DateTime->from_epoch(epoch => 1_538_564_253);
        my $req_content = $object->toJSON;

        $mock_response->set_always(decoded_content => $content);
        $mock_request->mock(content => sub {
            my $this = shift;
            my $value = shift;

            if ($value) {
                $req_content = $value;
            }

            return $req_content;
        });

        $object->send();

        ok($object->is_success, 'This payment was a success');
        is($card->id, 'card_xognFbZs935LMKJYeHyCAYUd', 'Card should have updated');

        is($object->amount, 100, 'Should have an amount');
        ok($object->capture, 'Should indicate a captured payment');
        is($object->card, $card, 'Should not change card object');
        is($object->created, $date, 'Should have a creation date');
        is($object->currency, 'eur', 'Should have a currency');
        is($object->description, 'le test restfull v1', 'Should have a description');
        is($object->id, 'paym_KIVaaHi7G8QAYMQpQOYBrUQE', 'Should have an id');
        is($object->method, 'card', 'Should indicate a card payment');
        is($object->response, '00', 'Should have a response code');
        is($object->status, 'to_capture', 'Should have a status');

        isa_ok($object->customer, 'Stancer::Customer', '$object->customer');
        # send will not do it, we check it because we fake a return containing a customer

        is($object->customer->id, 'cust_9Cle7TXKkjhwqcWx4Kl5cQYk', 'Customer should have an id');

        ok($object->is_not_modified, 'Should not be modified anymore');
        ok($card->is_not_modified, 'Card too');
        ok($object->customer->is_not_modified, 'Customer too');

        my $messages = $log->msgs;
        my $log_message = sprintf 'Payment of %.2f %s with %s "%s"', (
            $object->amount / 100,
            $object->currency,
            'MasterCard',
            $card->last4,
        );

        is(scalar @{$messages}, 3, 'Should have three logged messages'); # the first one is the API call
        is($messages->[1]->{level}, 'info', 'Should indicate an info message');
        is($messages->[1]->{message}, 'Payment ' . $object->id . ' created', 'Should indicate a creation');

        is($messages->[2]->{level}, 'info', 'Should indicate an info message');
        is($messages->[2]->{message}, $log_message, 'Should have amount and last 4 digits on message');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 3, 'Should send all setted data');
            is($data->{amount}, $amount, 'Should have passed "amount"');
            is($data->{currency}, lc $currency, 'Should have passed "currency"');

            is(ref $data->{card}, 'HASH', 'Should have passed "card"');
            is($data->{card}->{cvc}, $cvc, 'Card should have "cvc" property');
            is($data->{card}->{exp_month}, $month, 'Card should have "exp_month" property');
            is($data->{card}->{exp_year}, $year, 'Card should have "exp_year" property');
            is($data->{card}->{name}, $name, 'Card should have "name" property');
            is($data->{card}->{number}, $number, 'Card should have "number" property');

            ok(not(defined $data->{auth}), 'Should not have passed "auth"');
            ok(not(defined $data->{device}), 'Should not have passed "device"');

            last; # We only check it once, as the "content" method should be used again in debug mode
        }

        # Calls
        is(scalar @{ $config->calls }, $nb_calls, 'No call list without debug mode');
    }

    { # 2 tests
        note 'Validate issue #1';

        my $config = Stancer::Config->init();

        $config->debug(1);

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $exp_year = random_integer(1, 15) + $y + 1900;
        my $exp_month = random_integer(1, 12);

        my $card = Stancer::Card->new(
            number    => '4000000000000002',
            cvc       => '123',
            exp_month => $exp_month,
            exp_year  => $exp_year,
        );

        my $payment = Stancer::Payment->new(
            amount    => 3999,
            currency  => 'eur',
            card      => $card,
            customer  => Stancer::Customer->new(),
            order_id  => 'A123',
        );

        my $content = read_file '/t/fixtures/payment/issue/1.json';

        splice @{ $config->calls }; # Pretend you did not see this

        $mock_ua->clear();
        $mock_response->set_always(decoded_content => $content);

        $payment->send();

        is(scalar @{ $config->calls }, 1, 'Should only have the "send" call');

        $payment->customer->name;

        is(scalar @{ $config->calls }, 1, 'Even when you try to populate the object');
    }

    { # 2 tests
        note 'Validate issue #3';

        my ($sec, $min, $hour, $mday, $mon, $y, $wday, $yday, $isdst) = localtime;
        my $exp_year = random_integer(5, 15) + $y + 1900;
        my $exp_month = random_integer(1, 12);

        my $card = Stancer::Card->new(
            number => '4000000000000002',
            cvc => '123',
            exp_month => $exp_month,
            exp_year => $exp_year,
        );

        my $payment = Stancer::Payment->new(
            amount => 3999,
            auth => 'https://www.example.org/?' . random_string(50),
            currency => 'eur',
            card => $card,
            device => {},
        );

        throws_ok {
            $payment->send()
        } 'Stancer::Exceptions::InvalidIpAddress', 'Manually added device must be checked for valid IP';

        my $ip = ipv4_provider();
        local $ENV{SERVER_ADDR} = $ip;

        throws_ok {
            $payment->send()
        } 'Stancer::Exceptions::InvalidPort', 'Manually added device must be checked for valid port';
    }
}

sub sepa : Tests(4) {
    my $object = Stancer::Payment->new();
    my $sepa = Stancer::Sepa->new();

    is($object->sepa, undef, 'Undefined by default');

    $object->sepa($sepa);

    is($object->sepa, $sepa, 'Should be updated');
    is($object->method, 'sepa', 'Should update method');
    cmp_deeply_json($object, { sepa => {} }, 'Should be exported');
}

sub status : Tests(3) {
    my $object = Stancer::Payment->new();
    my $status = random_string(10);

    is($object->status, undef, 'Undefined by default');

    $object->status($status);

    is($object->status, $status, 'Should be updated');
    cmp_deeply_json($object, { status => $status }, 'Should be exported');
}

sub uri : Tests(2) {
    my $without_id = Stancer::Payment->new();

    is($without_id->uri, 'https://api.stancer.com/v1/checkout', 'Check default URI');

    my $id = random_string(29);
    my $with_id = Stancer::Payment->new($id);

    is($with_id->uri, 'https://api.stancer.com/v1/checkout/' . $id, 'Check defined payment URI');
}

sub unique_id : Tests(3) {
    my $object = Stancer::Payment->new();
    my $id = random_string(10);

    is($object->unique_id, undef, 'Undefined by default');

    $object->unique_id($id);

    is($object->unique_id, $id, 'Should be updated');
    cmp_deeply_json($object, { unique_id => $id }, 'Should be exported');
}

1;
