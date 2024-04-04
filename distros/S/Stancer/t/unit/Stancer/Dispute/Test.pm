package Stancer::Dispute::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use DateTime;
use DateTime::Span;
use English qw(-no_match_vars);
use Stancer::Dispute;
use Stancer::Payment;
use TestCase qw(:lwp);

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(8) {
    { # 3 tests
        note 'Empty new instance';

        my $object = Stancer::Dispute->new();

        isa_ok($object, 'Stancer::Dispute', 'Stancer::Dispute->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Dispute->new()');

        ok($object->does('Stancer::Role::Amount::Read'), 'Should use Stancer::Role::Amount::Read');
    }

    { # 5 tests
        note 'Instance completed at creation';

        my $id = random_string(29);
        my $order_id = random_string(10);
        my $payment = Stancer::Payment->new();

        my $object = Stancer::Dispute->new(
            id => $id,
            order_id => $order_id,
            payment => $payment,
        );

        isa_ok($object, 'Stancer::Dispute', 'Stancer::Dispute->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->order_id, $order_id, 'Should have a value for `order_id` property');
        is($object->payment, $payment, 'Should have a value for `payment` property');

        my $exported = {
            order_id => $order_id,
            payment => {},
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }
}

sub amount : Tests(3) {
    { # 2 tests
        note 'Should alert if amount is used as a setter';

        my $object = Stancer::Dispute->new();

        is($object->amount, undef, 'Undefined by default');

        throws_ok { $object->amount(random_integer(50, 99_999)) } qr/amount is a read-only accessor/sm, 'Not writable';
    }

    { # 1 test
        note 'Can return a value on call';

        my $content = read_file '/t/fixtures/disputes/get.json';

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content);

        my $dispute = Stancer::Dispute->new(random_string(29));

        is($dispute->amount, 5247, 'Should have an amount');
    }
}

sub currency : Tests(3) {
    { # 2 tests
        note 'Should alert if currency is used as a setter';

        my $object = Stancer::Dispute->new();
        my $currency = currencies_provider();

        is($object->currency, undef, 'Undefined by default');

        throws_ok { $object->currency($currency) } qr/currency is a read-only accessor/sm, 'Not writable';
    }

    { # 1 test
        note 'Can return a value on call';

        my $content = read_file '/t/fixtures/disputes/get.json';

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content);

        my $dispute = Stancer::Dispute->new(random_string(29));

        is($dispute->currency, 'eur', 'Should have a currency');
    }
}

sub endpoint : Test {
    my $object = Stancer::Dispute->new();

    is($object->endpoint, 'disputes');
}

sub list : Tests(117) {
    { # 19 tests
        note 'Basic tests';

        my $content1 = read_file '/t/fixtures/disputes/list-1.json';
        my $content2 = read_file '/t/fixtures/disputes/list-2.json';
        my $dispute;

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content1, $content2);

        my $created = random_integer(1_000_000);

        my $list = Stancer::Dispute->list({created => $created});

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list({created => $created})');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (1st)');
        is($dispute->id, 'dspt_kkyLpFvqM8JYQrBJlhN9bxSY', 'Should be expected dispute (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (2nd)');
        is($dispute->id, 'dspt_VIk2SufjagxqT6ZtoRbqUkUm', 'Should be expected dispute (2nd)');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (3rd)');
        is($dispute->id, 'dspt_lkR6152bNJ6XvPpG5uvkbMfu', 'Should be expected dispute (3rd)');

        # Called a second time as the response says "has more"
        is($mock_ua->called_count('request'), 2, 'Should have done a second call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=2/sm, 'Should start at 2 now');

        $dispute = $list->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 2, 'No more calls');
    }

    { # 3 tests
        note 'No response from API';

        $mock_ua->clear();
        $mock_response->set_always('decoded_content', q//);

        my $failed = Stancer::Dispute->list(created => random_integer(1_000_000));

        isa_ok($failed, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list(created => $created)');

        my $dispute = $failed->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'One call');
    }

    { # 25 tests
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
            Stancer::Dispute->list(created => time + 100)
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Created must be in the past (with integer)';
        is($EVAL_ERROR->message, 'Created must be in the past.', $message->());

        throws_ok {
            Stancer::Dispute->list(created => $date)
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Created must be in the past (with DateTime)';
        is($EVAL_ERROR->message, 'Created must be in the past.', $message->());

        throws_ok {
            Stancer::Dispute->list(created => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Should only works with integer and DateTime instance';
        is($EVAL_ERROR->message, 'Created must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Dispute->list(created => Stancer::Card->new())
        } 'Stancer::Exceptions::InvalidSearchCreation', 'Should not accept blessed variable other than DataTime';
        is($EVAL_ERROR->message, 'Created must be a position integer or a DateTime object.', $message->());

        isa_ok(
            Stancer::Dispute->list(created => time - 1000),
            'Stancer::Core::Iterator::Dispute',
            'Stancer::Dispute->list(created => $created)',
        );

        note 'Exceptions - created until';
        # 11 tests

        throws_ok {
            Stancer::Dispute->list(created_until => time + 100)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be in the past (with integer)';
        is($EVAL_ERROR->message, 'Created until must be in the past.', $message->());

        throws_ok {
            Stancer::Dispute->list(created_until => $date)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be in the past (with DateTime)';
        is($EVAL_ERROR->message, 'Created until must be in the past.', $message->());

        throws_ok {
            Stancer::Dispute->list(created_until => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Should only works with integer and DateTime instance';
        is($EVAL_ERROR->message, 'Created until must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Dispute->list(created_until => Stancer::Card->new())
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Should not accept blessed variable other than DataTime';
        is($EVAL_ERROR->message, 'Created until must be a position integer or a DateTime object.', $message->());

        throws_ok {
            Stancer::Dispute->list(created => time - 100, created_until => time - 200)
        } 'Stancer::Exceptions::InvalidSearchUntilCreation', 'Created until must be after created';
        is($EVAL_ERROR->message, 'Created until can not be before created.', $message->());

        isa_ok(
            Stancer::Dispute->list(created_until => time - 1000),
            'Stancer::Core::Iterator::Dispute',
            'Stancer::Dispute->list(created_until => $created_until)',
        );

        note 'Exceptions - limit';
        # 7 tests

        throws_ok {
            Stancer::Dispute->list(limit => 0)
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be at least 1';
        is($EVAL_ERROR->message, 'Limit must be between 1 and 100.', $message->());

        throws_ok {
            Stancer::Dispute->list(limit => 101)
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be maximum 100';
        is($EVAL_ERROR->message, 'Limit must be between 1 and 100.', $message->());

        throws_ok {
            Stancer::Dispute->list(limit => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchLimit', 'Limit must be an integer';
        is($EVAL_ERROR->message, 'Limit must be an integer.', $message->());

        isa_ok(
            Stancer::Dispute->list(limit => random_integer(99) + 1),
            'Stancer::Core::Iterator::Dispute',
            'Stancer::Dispute->list(limit => $limit)',
        );

        note 'Exceptions - start';
        # 5 tests

        throws_ok {
            Stancer::Dispute->list(start => -1)
        } 'Stancer::Exceptions::InvalidSearchStart', 'Start must be positive';
        is($EVAL_ERROR->message, 'Start must be a positive integer.', $message->());

        throws_ok {
            Stancer::Dispute->list(start => random_string(10))
        } 'Stancer::Exceptions::InvalidSearchStart', 'Start must be an integer';
        is($EVAL_ERROR->message, 'Start must be a positive integer.', $message->());

        isa_ok(
            Stancer::Dispute->list(start => random_integer(100)),
            'Stancer::Core::Iterator::Dispute',
            'Stancer::Dispute->list(start => $start)',
        );

        note 'Exceptions - empty';
        # 4 tests

        throws_ok {
            Stancer::Dispute->list()
        } 'Stancer::Exceptions::InvalidSearchFilter', 'Search filter are mandatory';
        is($EVAL_ERROR->message, 'Invalid search filters.', $message->());

        throws_ok {
            Stancer::Dispute->list(foo => random_string(5))
        } 'Stancer::Exceptions::InvalidSearchFilter', 'Only known filters works';
        is($EVAL_ERROR->message, 'Invalid search filters.', $message->());
    }

    { # 7 tests
        note 'Everything together';

        my %filters = (
            created => time - 1000,
            created_until => time - 100,
            limit => random_integer(99) + 1,
            start => random_integer(100),
        );

        $mock_ua->clear();

        my $list = Stancer::Dispute->list(%filters);

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list(%filters)');

        $list->next();

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$filters{created}/sm, 'Should created parameter');
        like($mock_request->url, qr/limit=$filters{limit}/sm, 'Should limit parameter');
        like($mock_request->url, qr/start=$filters{start}/sm, 'Should start parameter');

        unlike($mock_request->url, qr/created_until/sm, 'Should not have created_until parameter');
    }

    { # 14 tests
        note 'Basic tests';

        my $content = read_file '/t/fixtures/disputes/list-3.json';
        my $dispute;

        $mock_ua->clear();
        $mock_response->set_always(decoded_content => $content);

        my $created = random_integer(1_000_000);

        my $list = Stancer::Dispute->list({created => $created, created_until => 1_541_372_400});

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list({created => $created})');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (1st)');
        is($dispute->id, 'dspt_ZSnN0wV6Dk0qXe0Q2IXBcxAU', 'Should be expected dispute (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (2nd)');
        is($dispute->id, 'dspt_AkHxiO2T7BSRXeuir4cyolL6', 'Should be expected dispute (2nd)');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (3rd)');
        is($dispute->id, 'dspt_cXDMoCAjR2UoGkaPjAZRXMRU', 'Should be expected dispute (3rd)');

        $dispute = $list->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 14 tests
        note 'Allow DateTime::Span with included dates';

        my $content = read_file '/t/fixtures/disputes/list-3.json';
        my $dispute;

        $mock_ua->clear();
        $mock_response->set_always(decoded_content => $content);

        my $created = random_integer(1_000_000);
        my $date1 = DateTime->from_epoch(epoch => $created);
        my $date2 = DateTime->from_epoch(epoch => 1_541_372_400);
        my $span = DateTime::Span->from_datetimes(start => $date1, end => $date2);

        my $list = Stancer::Dispute->list({created => $span});

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list({created => $span})');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list-->next() (1st)');
        is($dispute->id, 'dspt_ZSnN0wV6Dk0qXe0Q2IXBcxAU', 'Should be expected dispute (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list-->next() (2nd)');
        is($dispute->id, 'dspt_AkHxiO2T7BSRXeuir4cyolL6', 'Should be expected dispute (2nd)');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list-->next() (3rd)');
        is($dispute->id, 'dspt_cXDMoCAjR2UoGkaPjAZRXMRU', 'Should be expected dispute (3rd)');

        $dispute = $list->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 10 tests
        note 'Allow DateTime::Span with excluded dates';

        my $content = read_file '/t/fixtures/disputes/list-3.json';
        my $dispute;

        $mock_ua->clear();
        $mock_response->set_always(decoded_content => $content);

        my $created = random_integer(1_000_000);
        my $date1 = DateTime->from_epoch(epoch => $created - 1);
        my $date2 = DateTime->from_epoch(epoch => 1_541_372_400);
        my $span = DateTime::Span->from_datetimes(after => $date1, before => $date2);

        my $list = Stancer::Dispute->list({created => $span});

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list({created => $span})');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (1st)');
        is($dispute->id, 'dspt_ZSnN0wV6Dk0qXe0Q2IXBcxAU', 'Should be expected dispute (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $dispute = $list->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }

    { # 14 tests
        note 'A DateTime::Span will ignore created_until value';

        my $content = read_file '/t/fixtures/disputes/list-3.json';
        my $dispute;

        $mock_ua->clear();
        $mock_response->set_always(decoded_content => $content);

        my $created = random_integer(1_000_000);
        my $date1 = DateTime->from_epoch(epoch => $created);
        my $date2 = DateTime->from_epoch(epoch => 1_541_372_400);
        my $span = DateTime::Span->from_datetimes(start => $date1, end => $date2);

        my $list = Stancer::Dispute->list({created => $span, created_until => $created + 100});

        isa_ok($list, 'Stancer::Core::Iterator::Dispute', 'Should return a Dispute iterator');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (1st)');
        is($dispute->id, 'dspt_ZSnN0wV6Dk0qXe0Q2IXBcxAU', 'Should be expected dispute (1st)');

        # Only one call for now
        is($mock_ua->called_count('request'), 1, 'Should have done only one call');

        is($mock_request->method, 'GET', 'Should create a new GET request');
        like($mock_request->url, qr/disputes/sm, 'Should use dispute endpoint');
        like($mock_request->url, qr/created=$created/sm, 'Should use parameter');
        like($mock_request->url, qr/start=0/sm, 'Should start at 0');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (2nd)');
        is($dispute->id, 'dspt_AkHxiO2T7BSRXeuir4cyolL6', 'Should be expected dispute (2nd)');

        $dispute = $list->next();

        isa_ok($dispute, 'Stancer::Dispute', '$list->next() (3rd)');
        is($dispute->id, 'dspt_cXDMoCAjR2UoGkaPjAZRXMRU', 'Should be expected dispute (3rd)');

        $dispute = $list->next();

        is($dispute, undef, 'Should not return anything'); # No more results
        is($mock_ua->called_count('request'), 1, 'No more calls');
    }
}

sub order_id : Tests(3) {
    { # 2 tests
        note 'Should alert if order_id is used as a setter';

        my $object = Stancer::Dispute->new();

        is($object->order_id, undef, 'Undefined by default');

        throws_ok { $object->order_id(random_string(10)) } qr/order_id is a read-only accessor/sm, 'Not writable';
    }

    { # 1 test
        note 'Can return a value on call';

        my $content = read_file '/t/fixtures/disputes/get.json';

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content);

        my $dispute = Stancer::Dispute->new(random_string(29));

        is($dispute->order_id, '825030405', 'Should have an order ID');
    }
}

sub payment : Tests(4) {
    { # 2 tests
        note 'Should alert if payment is used as a setter';

        my $object = Stancer::Dispute->new();
        my $payment = Stancer::Payment->new();

        is($object->payment, undef, 'Undefined by default');

        throws_ok { $object->payment($payment) } qr/payment is a read-only accessor/sm, 'Not writable';
    }

    { # 2 test
        note 'Can return a value on call';

        my $content = read_file '/t/fixtures/disputes/get.json';

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content);

        my $dispute = Stancer::Dispute->new(random_string(29));
        my $payment = $dispute->payment;

        isa_ok($payment, 'Stancer::Payment', 'Stancer::Dispute->new($id)->payment');
        is($payment->id, 'paym_oTwazegPIbxPnUWDntboWvyL', 'Should have expected ID');
    }
}

sub response : Tests(3) {
    { # 2 tests
        note 'Should alert if response is used as a setter';

        my $object = Stancer::Dispute->new();

        is($object->response, undef, 'Undefined by default');

        throws_ok { $object->response(random_string(2)) } qr/response is a read-only accessor/sm, 'Not writable';
    }

    { # 1 test
        note 'Can return a value on call';

        my $content = read_file '/t/fixtures/disputes/get.json';

        $mock_ua->clear();
        $mock_response->set_series('decoded_content', $content);

        my $dispute = Stancer::Dispute->new(random_string(29));

        is($dispute->response, '45', 'Should have a response');
    }
}

1;
