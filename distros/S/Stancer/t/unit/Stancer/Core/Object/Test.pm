package Stancer::Core::Object::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use TestCase qw(:lwp); # Must be called first to initialize logs
use DateTime;
use Stancer::Core::Object;
use Stancer::Core::Object::Stub;

## no critic (Capitalization, RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Test {
    my $object = Stancer::Core::Object->new;

    isa_ok($object, 'Stancer::Core::Object', 'Stancer::Core::Object->new()');
}

sub created : Tests(11) {
    my $object = Stancer::Core::Object->new();

    is($object->created, undef, 'At start it will be undef');

    # We add a random data
    my $date = int(rand(946_771_200) + 946_681_200);
    my $ref = DateTime->from_epoch('epoch' => $date);

    $object->hydrate('created' => $date);

    my $dt = $object->created;

    isa_ok($dt, 'DateTime', '$object->created');

    is($dt->year(), $ref->year(), 'Should have same year');
    is($dt->month(), $ref->month(), 'Should have same month');
    is($dt->day(), $ref->day(), 'Should have same day');
    is($dt->hour(), $ref->hour(), 'Should have same hour');
    is($dt->minute(), $ref->minute(), 'Should have same minute');
    is($dt->second(), $ref->second(), 'Should have same second');

    my $config = Stancer::Config->init();
    my $delta = random_integer(1, 6);
    my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

    $config->default_timezone($tz);

    is($dt->time_zone_long_name, 'UTC', 'Setting TimeZone will not change previously defined values');

    $object->hydrate('created' => $date);

    $dt = $object->created;

    is($dt->time_zone, $tz, 'Should have the same timezone now');
    is($dt->hour(), ($ref->hour() + $delta) % 24, 'Should not have the same hour (not on the same tz)');
}

sub del : Tests(24) {
    { # 10 tests
        note 'Object with ID';

        my $id = random_string(29);
        my $object = Stancer::Core::Object::Stub->new($id);
        my $uri = $object->uri;

        $mock_response->set_always(decoded_content => undef);
        $mock_ua->clear();

        isa_ok($object->del(), 'Stancer::Core::Object::Stub', '$object->del()');

        is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

        is($object->id, undef, 'Object as no ID');

        my $req_args = $mock_request->new_args;

        is($req_args->[1], 'DELETE', 'Should create a new DELETE request');
        is($req_args->[2], $uri, 'Should use object location');

        my $messages = $log->msgs;

        is(scalar @{$messages}, 2, 'Should have logged two message');
        is($messages->[0]->{level}, 'debug', 'Should be a debug message');
        is($messages->[0]->{message}, 'API call: DELETE ' . $uri, 'Should log API call');

        is($messages->[1]->{level}, 'info', 'Should be a info message');
        is($messages->[1]->{message}, 'Stub ' . $id . ' deleted', 'Should indicate a deletion');
    }

    { # 11 tests
        note 'With a payload'; # To make code coverage be happy

        my $id = random_string(29);
        my $object = Stancer::Core::Object::Stub->new($id);
        my $uri = $object->uri;
        my $string = random_string(10);

        $mock_response->set_always(decoded_content => encode_json {string => $string});
        $mock_ua->clear();

        isa_ok($object->del(), 'Stancer::Core::Object::Stub', '$object->del()');

        is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

        is($object->id, undef, 'Object as no ID');
        is($object->string, $string, 'Object as a new property');

        my $req_args = $mock_request->new_args;

        is($req_args->[1], 'DELETE', 'Should create a new DELETE request');
        is($req_args->[2], $uri, 'Should use object location');

        my $messages = $log->msgs;

        is(scalar @{$messages}, 2, 'Should have logged two message');
        is($messages->[0]->{level}, 'debug', 'Should be a debug message');
        is($messages->[0]->{message}, 'API call: DELETE ' . $uri, 'Should log API call');

        is($messages->[1]->{level}, 'info', 'Should be a info message');
        is($messages->[1]->{message}, 'Stub ' . $id . ' deleted', 'Should indicate a deletion');
    }

    { # 3 tests
        note 'Object without ID'; # Basicaly, do nothing

        my $object = Stancer::Core::Object::Stub->new();
        my $uri = $object->uri;

        $mock_response->set_always(decoded_content => undef);
        $mock_ua->clear();

        isa_ok($object->del(), 'Stancer::Core::Object::Stub', '$object->del()');

        is($mock_ua->called('request'), 0, 'LWP::UserAgent was not used');

        my $messages = $log->msgs;

        is(scalar @{$messages}, 0, 'Should not have logged messages');
    }
}

sub endpoint : Test {
    my $object = Stancer::Core::Object->new();

    is($object->endpoint, q//, 'Object has no endpoint');
}

sub get : Tests {
    my $id = random_string(29);
    my $cvc = random_integer(100, 999);
    my $card = Stancer::Card->new(cvc => $cvc);
    my $string = random_string(10);
    my $integer = random_integer(1000);
    my $created = int(rand(946_771_200) + 946_681_200);
    my $data = {
        id => $id,
        created => $created,
        string => $string,
        integer1 => $integer,
        integer2 => undef,
        card => $card->TO_JSON(),
    };

    $mock_response->set_always(decoded_content => encode_json $data);
    $mock_ua->clear();

    my $object = Stancer::Core::Object::Stub->new($id);

    note 'Default values';

    is($object->get(), undef, 'Should return "undef" by default');
    is($object->get('id'), undef, 'Should return "undef" by default');
    is($object->get('created'), undef, 'Should return "undef" by default');
    is($object->get('string'), undef, 'Should return "undef" by default');
    is($object->get('integer1'), undef, 'Should return "undef" by default');
    is($object->get('integer2'), undef, 'Should return "undef" by default');
    is($object->get('card'), undef, 'Should return "undef" by default');

    $object->populate();

    note 'API values';

    eq_or_diff($object->get(), $data, 'Should return data sent by the API');
    is($object->get('id'), $id, 'Should return the "id"');
    is($object->get('created'), $created, 'Should return "created" value');
    is($object->get('string'), $string, 'Should return "string" value');
    is($object->get('integer1'), $integer, 'Should return "integer1" value');
    is($object->get('integer2'), undef, 'Should return "integer2" value');
    eq_or_diff($object->get('card'), $card->TO_JSON(), 'Should return "card" value');

    note 'Inner object';

    eq_or_diff($object->card->get(), $card->TO_JSON(), 'Should return data sent by the API for the card');
    is($object->card->get('cvc'), $cvc, 'Should return "cvc" value');

    note 'Return copies';

    isnt($object->get(), $object->get(), 'Should return different ref');
    isnt($object->get('card'), $object->get('card'), 'Should return different ref even for nth data');
    isnt($object->card->get(), $object->card->get(), 'Should return different ref even with inner object');
}

sub hydrate : Tests(13) {
    my $id = random_string(29);
    my $object = Stancer::Core::Object::Stub->new();

    isa_ok($object->hydrate(id => $id, foo => 'bar'), 'Stancer::Core::Object', '$object->hydrate(foo => "bar")');

    is($object->id, $id, 'Hydrate should add a value to ID');

    is($object->can('foo'), undef, 'Foo was not created');

    $id = random_string(29);

    isa_ok($object->hydrate({id => $id}), 'Stancer::Core::Object', '$object->hydrate({foo => "bar"})');

    is($object->id, $id, 'Hydrate should add a value to ID');

    $object->hydrate({id => undef});

    is($object->id, $id, 'Hydrate should not changes values when encounter an undefined value');

    my $number = '4111111111111111';

    $object->hydrate(card => {number => $number});

    isa_ok($object->card, 'Stancer::Card', '$object->card');

    my $card = $object->card;

    is($card->number, $number, 'Card should have correct number');

    my $card_id = random_string(29);

    lives_ok { $object->hydrate(card => $card_id) };

    is($object->card, $card, 'Should be the same card object');
    is($card->id, $card_id, 'Card object should be upadted');

    cmp_deeply_json($object, { card => { number => $number } }, 'Should export attributes');
}

sub id : Tests(2) {
    my $id = random_string(29);
    my $object = Stancer::Core::Object->new($id);

    is($object->id, $id, 'id attribue must return the ID passed to new');
    is($object->id(), $id, 'id() method must return the ID passed to new');
}

sub is_modified : Tests(6) {
    { # 4 tests
        note 'Basic tests';

        my $object = Stancer::Core::Object::Stub->new();

        is($object->is_modified, $false, 'No modification on default');
        is($object->is_not_modified, $true, 'is_not_modified');

        $object->string(random_string(10));

        is($object->is_modified, $true, 'Say true if a modification is done');
        is($object->is_not_modified, $false, 'is_not_modified');
    }

    { # 2 tests
        note 'With inner object';

        my $obj = Stancer::Core::Object::Stub->new();
        my $object1 = Stancer::Core::Object::Stub->new();

        $object1->string(random_string(10));

        $obj->object1($object1);
        $obj->test_only_reset_modified();

        is($obj->is_modified, $true, 'Object is not modified but inner object is');
        is($obj->is_not_modified, $false, 'is_not_modified');
    }
}

sub populate : Tests(11) {
    my $id = random_string(29);
    my $object = Stancer::Core::Object::Stub->new($id);
    my $card = Stancer::Card->new(cvc => random_integer(100, 999));
    my $string = random_string(10);
    my $integer = random_integer(1000);
    my %data = (
        id => $id,
        string => $string,
        integer1 => $integer,
        integer2 => undef,
        card => $card->TO_JSON,
    );

    $mock_response->set_always(decoded_content => encode_json \%data);
    $mock_ua->clear();

    isa_ok(Stancer::Core::Object::Stub->new->populate(), 'Stancer::Core::Object::Stub', 'Stancer::Core::Object::Stub->new->populate()');
    isa_ok(Stancer::Core::Object->new($id)->populate(), 'Stancer::Core::Object', 'Stancer::Core::Object->new($id)->populate()');

    is($mock_ua->called('request'), 0, 'LWP::UserAgent was not used');

    isa_ok($object->populate(), 'Stancer::Core::Object::Stub', '$object->populate()');

    is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

    is($object->string, $string, 'Should have updated property 1');
    is($object->integer1, $integer, 'Should have updated property 2');
    ok($object->is_not_modified, 'Should clear modified list');

    $mock_ua->clear();

    $object->populate();

    is($mock_ua->called('request'), 0, 'Double use of populate will not trigger multiple API call');

    note 'Block send';

    $object->send();

    is($mock_ua->called('request'), 0, 'A freshly populated object will not allow to send it');

    note 'Send block population';

    $object->string(random_string(10));

    $object->send();

    $mock_ua->clear();

    $object->populate();

    is($mock_ua->called('request'), 0, 'A freshly sent object can not be populated');
}

sub save : Tests(17) {
    my $object = Stancer::Core::Object::Stub->new();
    my $id = random_string(29);
    my $string = random_string(10);
    my $integer1 = random_integer(1000);
    my $integer2 = random_integer(1000);
    my $created = int(rand(946_771_200) + 946_681_200);
    my $date = DateTime->from_epoch('epoch' => $created);
    my %data = (
        id => $id,
        created => $created,
        string => $string,
        integer1 => $integer1,
        integer2 => $integer2,
    );
    my $uri = $object->uri;

    my $message = '"save" method is deprecated and will be removed in a later release, use the "send" method instead';

    warning_is {
        $object->string($string);
        $object->integer1($integer1);
        $object->integer2($integer2);

        $mock_response->set_always(decoded_content => encode_json \%data);
        $mock_ua->clear();

        isa_ok($object->save(), 'Stancer::Core::Object::Stub', '$object->save()');

        is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

        is($object->id, $id, 'Object got an id');
        is($object->created, $date, 'Object got a creation date');
        ok($object->is_not_modified, 'Should not have modified properties anymore');

        my $req_args = $mock_request->new_args;

        is($req_args->[1], 'POST', 'Should create a new POST request');
        is($req_args->[2], $uri, 'Should use object location');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 3, 'Should send all setted data');
            is($data->{integer1}, $integer1, 'Should have passed "integer1"');
            is($data->{integer2}, $integer2, 'Should have passed "integer2"');
            is($data->{string}, $string, 'Should have passed "string"');
        }

        my $messages = $log->msgs;

        is(scalar @{$messages}, 2, 'Should have logged two message');
        is($messages->[0]->{level}, 'debug', 'Should be a debug message');
        is($messages->[0]->{message}, 'API call: POST ' . $uri, 'Should log API call');

        is($messages->[1]->{level}, 'info', 'Should be a info message');
        is($messages->[1]->{message}, 'Stub ' . $object->id . ' created', 'Should indicate a creation');
    }  { carped => $message }, 'Should warn about deprecation';
}

sub send_global : Tests(33) {
    { # 18 tests
        note 'Basic tests';

        my $object = Stancer::Core::Object::Stub->new();
        my $id = random_string(29);
        my $string = random_string(10);
        my $integer1 = random_integer(1000);
        my $integer2 = random_integer(1000);
        my $created = int(rand(946_771_200) + 946_681_200);
        my $date = DateTime->from_epoch('epoch' => $created);
        my %data = (
            id => $id,
            created => $created,
            string => $string,
            integer1 => $integer1,
            integer2 => $integer2,
        );
        my $uri = $object->uri;

        $object->string($string);
        $object->integer1($integer1);
        $object->integer2($integer2);

        $mock_response->set_always(decoded_content => encode_json \%data);
        $mock_ua->clear();

        isa_ok($object->send(), 'Stancer::Core::Object::Stub', '$object->send()');

        is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

        is($object->id, $id, 'Object got an id');
        is($object->created, $date, 'Object got a creation date');
        ok($object->is_not_modified, 'Should not have modified properties anymore');

        my $req_args = $mock_request->new_args;

        is($req_args->[1], 'POST', 'Should create a new POST request');
        is($req_args->[2], $uri, 'Should use object location');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 3, 'Should send all setted data');
            is($data->{integer1}, $integer1, 'Should have passed "integer1"');
            is($data->{integer2}, $integer2, 'Should have passed "integer2"');
            is($data->{string}, $string, 'Should have passed "string"');
        }

        my $messages = $log->msgs;

        is(scalar @{$messages}, 2, 'Should have logged two message');
        is($messages->[0]->{level}, 'debug', 'Should be a debug message');
        is($messages->[0]->{message}, 'API call: POST ' . $uri, 'Should log API call');

        is($messages->[1]->{level}, 'info', 'Should be a info message');
        is($messages->[1]->{message}, 'Stub ' . $object->id . ' created', 'Should indicate a creation');

        $mock_ua->clear();

        $object->send();

        is($mock_ua->called('request'), 0, 'Double send will not trigger multiple API call');

        $object->populate();

        is($mock_ua->called('request'), 0, 'Send block populate call');
    }

    { # 15 tests
        note 'Validate modified list';

        my $object = Stancer::Core::Object::Stub->new();
        my $card = Stancer::Card->new();
        my $number = card_number_provider();

        my $uri = $object->uri;

        $object->card($card);
        $card->number($number);

        $mock_ua->clear();

        isa_ok($object->send(), 'Stancer::Core::Object::Stub', '$object->send()');

        my $messages = $log->msgs;

        is(scalar @{$messages}, 2, 'Should have logged two message');
        is($messages->[0]->{level}, 'debug', 'Should be a debug message');
        is($messages->[0]->{message}, 'API call: POST ' . $uri, 'Should log API call');

        is($messages->[1]->{level}, 'info', 'Should be a info message');
        is($messages->[1]->{message}, 'Stub ' . $object->id . ' created', 'Should indicate a creation');

        is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

        ok($object->is_not_modified, 'Should not have modified properties anymore');
        ok($card->is_not_modified, 'Card should not have modified properties anymore');

        my $req_args = $mock_request->new_args;

        is($req_args->[1], 'POST', 'Should create a new POST request');
        is($req_args->[2], $uri, 'Should use object location');

        while (my ($method, $args) = $mock_request->next_call()) {
            next if $method ne 'content';

            my $data = decode_json $args->[1];

            is(scalar keys %{$data}, 1, 'Should send all setted data');
            is(ref $data->{card}, 'HASH', 'Should have passed "card"');
            is(scalar keys %{$data->{card}}, 1, 'Card should have one item');
            is($data->{card}->{number}, $number, 'And it should be "number"');
        }
    }
}

sub send_for_an_update : Tests(15) {
    my $id = random_string(29);
    my $object = Stancer::Core::Object::Stub->new($id);
    my $string = random_string(10);
    my $integer1 = random_integer(1000);
    my $integer2 = random_integer(1000);

    $object->string($string);
    $object->integer1($integer1);
    $object->integer2($integer2);

    $mock_response->set_always(decoded_content => undef);
    $mock_ua->clear();

    isa_ok($object->send(), 'Stancer::Core::Object::Stub', '$object->send()');

    my $messages = $log->msgs;

    is(scalar @{$messages}, 2, 'Should have logged two message');
    is($messages->[0]->{level}, 'debug', 'Should be a debug message');
    is($messages->[0]->{message}, 'API call: PATCH ' . $object->uri, 'Should log API call');

    is($messages->[1]->{level}, 'info', 'Should be a info message');
    is($messages->[1]->{message}, 'Stub ' . $object->id . ' updated', 'Should indicate an update');

    is($mock_ua->called('request'), 1, 'LWP::UserAgent was used');

    my $req_args = $mock_request->new_args;

    is($req_args->[1], 'PATCH', 'Should create a new PATCH request');
    is($req_args->[2], $object->uri, 'Should use object location');

    while (my ($method, $args) = $mock_request->next_call()) {
        next if $method ne 'content';

        my $data = decode_json $args->[1];

        is(scalar keys %{$data}, 3, 'Should send all setted data');
        is($data->{integer1}, $integer1, 'Should have passed "integer1"');
        is($data->{integer2}, $integer2, 'Should have passed "integer2"');
        is($data->{string}, $string, 'Should have passed "string"');
    }

    $mock_ua->clear();

    $object->send();

    is($mock_ua->called('request'), 0, 'Double send will not trigger multiple API call');

    $object->populate();

    is($mock_ua->called('request'), 0, 'Send block populate call');
}

sub toJSON : Tests(5) {
    my $object = Stancer::Core::Object::Stub->new();

    eq_or_diff($object->toJSON(), '{}', 'Empty object return empty JSON');

    my $id = random_string(29);
    my $date = int(rand(946_771_200) + 946_681_200);
    my $string = random_string(10);
    my $integer = random_integer(1000);

    $object->hydrate({
        created => $date,
        boolean1 => 1,
        string => $string,
        integer1 => $integer,
        integer2 => 1,
    });

    my $expected = to_json {
        boolean1 => \1,
        integer1 => $integer,
        integer2 => 1,
        string => $string,
    }, {canonical => 1}; # mandatory for testing otherwise key order can vary

    eq_or_diff($object->toJSON(), $expected, 'Should return everything except created');

    $object->hydrate({
        id => $id,
    });
    $object->test_only_reset_modified();

    eq_or_diff($object->toJSON(), q/"/ . $id . q/"/, 'If an ID is present, everything else is skipped');

    $object->test_only_add_modified('string');

    cmp_deeply($object->toJSON(), to_json({ string => $string }), 'Should only return modified properties');

    # Force populate call to test undef value
    my %data = (
        string => $string,
        integer1 => $integer,
        integer2 => undef,
    );

    $object = Stancer::Core::Object::Stub->new($id);

    $mock_ua->clear();
    $mock_response->set_always(decoded_content => encode_json \%data);

    $object->integer2;
    $object->string($string);

    cmp_deeply($object->toJSON(), to_json({ string => $string }), 'Should not return undef value');
}

sub to_hash : Tests(6) {
    { # 5 tests
        note 'Basic test';

        my $object = Stancer::Core::Object::Stub->new();
        my $config = Stancer::Config->init();

        eq_or_diff(ref $object->to_hash(), 'HASH', '$object->to_hash should return an HASH');
        eq_or_diff($object->to_hash(), {}, 'Should return an empty hash for empty object');

        my $id = random_string(29);
        my $date = int(rand(946_771_200) + 946_681_200);
        my $string = random_string(10);
        my $integer = random_integer(1000);
        my $object1 = Stancer::Core::Object::Stub->new();

        $mock_response->set_always(decoded_content => q//);

        $object->hydrate({
            created => $date,
            boolean1 => 1,
            boolean2 => 0,
            integer1 => $integer,
            integer2 => 1,
            object1 => $object1,
            string => $string,
        });

        my $expected = {
            created => DateTime->from_epoch(epoch => $date, time_zone => $config->default_timezone),
            boolean1 => \1,
            boolean2 => \0,
            integer1 => $integer,
            integer2 => 1,
            object1 => {},
            string => $string,
        };

        cmp_deeply($object->to_hash(), $expected, 'Should return everything');

        $object->hydrate({
            id => $id,
        });
        $object->test_only_reset_modified();

        $expected->{id} = $id;

        eq_or_diff($object->to_hash(), $expected, 'Even if an ID is present');

        $object->test_only_add_modified('string');

        eq_or_diff($object->to_hash(), $expected, 'Should not use modified properties');
    }

    { # 1 test
        note 'Auto populate';

        my $id = random_string(29);
        my $object = Stancer::Core::Object::Stub->new($id);

        my $string = random_string(10);
        my $integer = random_integer(1000);

        my $expected = {
            id => $id,
            boolean1 => \1,
            boolean2 => \0,
            integer1 => $integer,
            integer2 => 1,
            string => $string,
        };

        $mock_response->set_always(decoded_content => encode_json $expected);

        cmp_deeply($object->to_hash(), $expected, 'Should return everything');
    }
}

sub TO_JSON : Tests(5) {
    my $object = Stancer::Core::Object::Stub->new();

    eq_or_diff(ref $object->TO_JSON(), 'HASH', 'TO_JSON should return an HASH');
    eq_or_diff($object->TO_JSON(), {}, 'Should return an empty hash for empty object');

    my $id = random_string(29);
    my $date = int(rand(946_771_200) + 946_681_200);
    my $string = random_string(10);
    my $integer = random_integer(1000);

    $object->hydrate({
        created => $date,
        boolean1 => 1,
        boolean2 => 0,
        date => $date,
        string => $string,
        integer1 => $integer,
        integer2 => 1,
    });

    my $expected = {
        boolean1 => \1,
        boolean2 => \0,
        date => $date,
        string => $string,
        integer1 => $integer,
        integer2 => 1,
    };

    cmp_deeply($object->TO_JSON(), $expected, 'Should return everything except created');

    $object->hydrate({
        id => $id,
    });
    $object->test_only_reset_modified();

    eq_or_diff($object->TO_JSON(), $id, 'If an ID is present, everything else is skipped');

    $object->test_only_add_modified('string');
    $object->test_only_add_modified('id'); # Should not be in modified list

    cmp_deeply($object->TO_JSON(), { string => $string }, 'Should only return modified properties');
}

sub uri : Tests(3) {
    my $without_id = Stancer::Core::Object->new();
    my $config = Stancer::Config::init();

    is($without_id->uri, 'https://api.stancer.com/v1', 'Should return default API uri');

    my $id = random_string(29);
    my $with_id = Stancer::Core::Object->new($id);

    is($with_id->uri, 'https://api.stancer.com/v1/' . $id, 'Should use object ID in URI');

    my $host = random_string(30);

    $config->host($host);

    is($with_id->uri, 'https://' . $host . q!/v1/! . $id, 'Should use configured host');
}

1;
