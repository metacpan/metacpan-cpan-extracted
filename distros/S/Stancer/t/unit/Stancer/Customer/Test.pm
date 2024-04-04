package Stancer::Customer::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Customer;
use TestCase qw(:lwp);

## no critic (Capitalization, RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(12) {
    {
        my $object = Stancer::Customer->new();

        isa_ok($object, 'Stancer::Customer', 'Stancer::Customer->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Customer->new()');

        ok($object->does('Stancer::Role::Name'), 'Should use Stancer::Role::Name');
    }

    {
        my $id = random_string(29);
        my $email = random_string(64);
        my $mobile = random_string(10);
        my $name = random_string(64);

        my $object = Stancer::Customer->new(
            id => $id,
            email => $email,
            mobile => $mobile,
            name => $name,
        );

        isa_ok($object, 'Stancer::Customer', 'Stancer::Customer->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->email, $email, 'Should have a value for `email` property');
        is($object->mobile, $mobile, 'Should have a value for `mobile` property');
        is($object->name, $name, 'Should have a value for `name` property');

        my $exported = {
            email => $email,
            mobile => $mobile,
            name => $name,
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }

    {
        my $id = random_string(29);
        my $object = Stancer::Customer->new($id);

        isa_ok($object, 'Stancer::Customer', 'Stancer::Customer->new($id)');

        is($object->id, $id, 'Should add a value for `id` property');

        ok($object->is_not_modified, 'Modified list should be empty');
    }
}

sub endpoint : Test {
    my $object = Stancer::Customer->new();

    is($object->endpoint, 'customers');
}

sub email : Tests(3) {
    my $object = Stancer::Customer->new();
    my $email = random_string(64);

    is($object->email, undef, 'Undefined by default');

    $object->email($email);

    is($object->email, $email, 'Should be updated');
    cmp_deeply_json($object, { email => $email }, 'Should be exported');
}

sub external_id : Tests(5) {
    my $object = Stancer::Customer->new();
    my $external_id = random_string(36);
    my $too_long = random_string(37);

    is($object->external_id, undef, 'Undefined by default');

    $object->external_id($external_id);

    is($object->external_id, $external_id, 'Should be updated');
    is($object->toJSON(), '{"external_id":"' . $external_id . '"}', 'Should be exported');

    throws_ok {
        $object->external_id($too_long)
    } 'Stancer::Exceptions::InvalidExternalId', 'Should complain when oversized';
    is(
        $EVAL_ERROR->message,
        'Must be at maximum 36 characters, tried with "' . $too_long . q/"./,
        'Should indicate the error',
    );
}

sub mobile : Tests(3) {
    my $object = Stancer::Customer->new();
    my $mobile = random_string(10);

    is($object->mobile, undef, 'Undefined by default');

    $object->mobile($mobile);

    is($object->mobile, $mobile, 'Should be updated');
    cmp_deeply_json($object, { mobile => $mobile }, 'Should be exported');
}

sub name : Tests(3) {
    my $object = Stancer::Customer->new();
    my $name = random_string(64);

    is($object->name, undef, 'Undefined by default');

    $object->name($name);

    is($object->name, $name, 'Should be updated');
    cmp_deeply_json($object, { name => $name }, 'Should be exported');
}

sub populate : Tests(8) {
    my $id = random_string(29);
    my $object = Stancer::Customer->new($id);
    my $name = random_string(10);
    my $email = random_string(10);
    my %data = (
        id => $id,
        name => $name,
        email => $email,
    );

    $mock_response->set_always(decoded_content => encode_json \%data);

    isa_ok(Stancer::Customer->new->populate(), 'Stancer::Customer', 'Stancer::Customer->new()->populate()');

    is($mock_ua->called('request'), 0, 'LWP::UserAgent was not used');

    isa_ok($object->populate(), 'Stancer::Customer', '$object->populate()');

    is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

    is($object->name, $name, 'Should have updated the name');
    is($object->email, $email, 'Should have updated the email');
    is($object->mobile, undef, 'Should not have updated the mobile (not given in faked data)');

    $mock_ua->clear();

    $object->populate();

    is($mock_ua->called('request'), 0, 'Double use of populate will not trigger multiple API call');
}

sub send_global : Tests(12) {
    my $id = 'cust_nwSpP6LKE828Inhiu1CXyp7l'; # From fixture
    my $object = Stancer::Customer->new();
    my $content = read_file '/t/fixtures/customers/create.json';

    $mock_response->set_always(decoded_content => $content);

    $mock_ua->clear(); # To be sure

    throws_ok(
        sub { $object->send() },
        'Stancer::Exceptions::BadMethodCall',
        'Customer should have an email or a phone number to be sent',
    );
    is(
        $EVAL_ERROR->message,
        'You must provide an email or a phone number to create a customer.',
        'Should indicate the error',
    );

    is($mock_ua->called('request'), 0, 'Errors will not trigger an API call');

    $object->hydrate(id => $id);

    isa_ok($object->send(), 'Stancer::Customer', '$object->send()');

    is($object->email, 'david@coaster.net', 'Should have an email');
    is($object->mobile, '+33684858687', 'Should have a mobile phoone number');
    is($object->name, 'David Coaster', 'Should have a name');

    my $date = DateTime->from_epoch(epoch => 1_538_565_198);

    is($object->created, $date, 'Should have a creation date');

    $mock_ua->clear();

    $object->send();

    is($mock_ua->called('request'), 0, 'Multiple call will not trigger multiple API call');

    my @attrs = qw(name email mobile);

    foreach my $attr (@attrs) {
        $object->_reset_modified(); # Do not do this at home, this will reset modified

        $mock_ua->clear();
        $object->$attr(random_string(10));

        $object->send();

        is($mock_ua->called('request'), 1, 'Modify attribute will allow to send again (' . $attr . ')');
    }
}

sub toJSON : Tests(3) {
    my $object = Stancer::Customer->new();

    my $id = random_string(29);
    my $name = random_string(10);
    my $email = random_string(10);
    my $mobile = random_string(10);

    $object->hydrate({
        name => $name,
        email => $email,
        mobile => $mobile,
    });

    my $expected = to_json {
        name => $name,
        email => $email,
        mobile => $mobile,
    }, {canonical => 1}; # mandatory for testing otherwise key order can vary

    eq_or_diff($object->toJSON(), $expected, 'Should return everything except created');

    $object->hydrate({
        id => $id,
    });

    $object->_reset_modified(); # Do not do this at home

    eq_or_diff($object->toJSON(), q/"/ . $id . q/"/, 'If an ID is present, everything else is skipped');

    $object->name($name);

    my $modified = to_json {
        name => $name,
    };

    eq_or_diff($object->toJSON(), $modified, 'Should return modified values');
}

sub uri : Tests(2) {
    my $without_id = Stancer::Customer->new();

    is($without_id->uri, 'https://api.stancer.com/v1/customers', 'Default location');

    my $id = random_string(29);
    my $with_id = Stancer::Customer->new($id);

    is($with_id->uri, 'https://api.stancer.com/v1/customers/' . $id, 'Precise customer location');
}

1;
