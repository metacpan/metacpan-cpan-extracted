#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Params::Filter qw/filter/;

# Functional Interface Tests

subtest 'Basic functional interface - hashref input' => sub {
    my ($result, $msg) = filter(
        { name => 'Alice', email => 'alice@example.com', phone => '555-1234' },
        ['name', 'email'],
        ['phone'],
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Alice', 'Required field: name';
    is $result->{email}, 'alice@example.com', 'Required field: email';
    is $result->{phone}, '555-1234', 'Accepted field: phone';
    like $msg, qr/Admitted/, 'Status message indicates success';
};

subtest 'Missing required field' => sub {
    my ($result, $msg) = filter(
        { name => 'Bob' },  # email missing
        ['name', 'email'],
        ['phone'],
    );

    ok !$result, 'Validation fails when required field missing';
    like $msg, qr/Unable to initialize without (all )?required arguments/, 'Error message mentions missing required';
    like $msg, qr/'email'/, 'Error message lists missing field';
};

subtest 'Only required fields, no accepted' => sub {
    my ($result, $msg) = filter(
        { name => 'Charlie', email => 'charlie@example.com', extra => 'ignored' },
        ['name', 'email'],
        [],  # No accepted fields
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Charlie', 'Required field present';
    is $result->{email}, 'charlie@example.com', 'Required field present';
    ok !exists $result->{extra}, 'Extra field not included';
};

subtest 'Wildcard acceptance' => sub {
    my ($result, $msg) = filter(
        { id => 1, name => 'Test', value => 42, active => 1 },
        ['id'],
        ['*'],  # Wildcard
    );

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field';
    is $result->{name}, 'Test', 'Wildcard accepted name';
    is $result->{value}, 42, 'Wildcard accepted value';
    is $result->{active}, 1, 'Wildcard accepted active';
};

subtest 'Excluded fields' => sub {
    my ($result, $msg) = filter(
        {
            name     => 'Diana',
            email    => 'diana@example.com',
            password => 'secret123',
            ssn      => '123-45-6789',
        },
        ['name'],
        ['email'],
        ['password', 'ssn'],
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Diana', 'Required field present';
    is $result->{email}, 'diana@example.com', 'Accepted field present';
    ok !exists $result->{password}, 'Excluded field removed: password';
    ok !exists $result->{ssn}, 'Excluded field removed: ssn';
};

subtest 'Arrayref input - even elements' => sub {
    my ($result, $msg) = filter(
        ['name', 'Eve', 'email', 'eve@example.com', 'age', 30],
        ['name', 'email'],
        ['age'],
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Eve', 'Field from array: name';
    is $result->{email}, 'eve@example.com', 'Field from array: email';
    is $result->{age}, 30, 'Field from array: age';
};

subtest 'Arrayref input - odd elements (becomes flag)' => sub {
    my ($result, $msg) = filter(
        ['name', 'Frank', 'verbose'],
        ['name'],
        ['verbose'],
        [],  # No excluded
        1,  # Debug on
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Frank', 'Required field';
    is $result->{verbose}, 1, 'Odd element becomes flag with value 1';
    like $msg, qr/Odd number of arguments/, 'Debug warns about odd elements';
};

subtest 'Arrayref input - single element' => sub {
    my ($result, $msg) = filter(
        ['single_value'],
        [],
        ['_'],  # Accept special key
    );

    ok $result, 'Validation succeeds';
    is $result->{_}, 'single_value', 'Single element stored with _ key';
};

subtest 'Arrayref input - single hashref' => sub {
    my ($result, $msg) = filter(
        [{ name => 'Grace', age => 25 }],
        ['name'],
        ['age'],
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Grace', 'Field from embedded hashref';
    is $result->{age}, 25, 'Field from embedded hashref';
};

subtest 'Scalar input' => sub {
    my ($result, $msg) = filter(
        'plain string',
        [],
        ['_'],
        [],  # No excluded
        1,  # Debug on
    );

    ok $result, 'Validation succeeds';
    is $result->{_}, 'plain string', 'Scalar stored with _ key';
    like $msg, qr/Plain text argument accepted with key '_'/, 'Debug warns about scalar';
};

subtest 'Debug mode - excluded fields warning' => sub {
    my ($result, $msg) = filter(
        { name => 'Henry', password => 'secret' },
        ['name'],
        ['email', 'phone'],  # Has accepted fields, so doesn't early-return
        ['password'],
        1,  # Debug on
    );

    ok $result, 'Validation succeeds';
    like $msg, qr/excluded/, 'Debug mentions excluded fields';
    like $msg, qr/'password'/, 'Debug lists excluded field';
    unlike $msg, qr/Admitted/, 'Does not say "Admitted" when there are warnings';
};

subtest 'Debug mode - unrecognized fields warning' => sub {
    my ($result, $msg) = filter(
        { name => 'Iris', extra1 => 'a', extra2 => 'b' },
        ['name'],
        ['email', 'phone'],  # Has accepted fields
        [],
        1,  # Debug on
    );

    ok $result, 'Validation succeeds';
    like $msg, qr/unrecognized/, 'Debug mentions unrecognized fields';
    unlike $msg, qr/Admitted/, 'Does not say "Admitted" when there are warnings';
};

subtest 'Debug mode - combined warnings' => sub {
    my ($result, $msg) = filter(
        { name => 'Jack', password => 'secret', spam => 'yes' },
        ['name'],
        ['email'],
        ['password'],
        1,  # Debug on
    );

    ok $result, 'Validation succeeds';
    like $msg, qr/excluded/, 'Mentions excluded fields';
    like $msg, qr/unrecognized/, 'Mentions unrecognized fields';
    unlike $msg, qr/Admitted/, 'Does not say "Admitted" when there are warnings';
};

subtest 'Empty hashref with required fields' => sub {
    my ($result, $msg) = filter(
        {},
        ['required_field'],
    );

    ok !$result, 'Validation fails';
    like $msg, qr/Unable to initialize without required arguments/, 'Error message';
};

subtest 'Return in scalar context' => sub {
    my $result = filter(
        { name => 'Kate', email => 'kate@example.com' },
        ['name', 'email'],
        [],
    );

    ok $result, 'Returns hashref in scalar context';
    is $result->{name}, 'Kate', 'Result contains data';
};

subtest 'Return in list context' => sub {
    my ($result, $msg) = filter(
        { name => 'Liam', email => 'liam@example.com' },
        ['name', 'email'],
        [],
    );

    ok $result, 'First element is hashref';
    like $msg, qr/Admitted/, 'Second element is status message';
};

subtest 'Undefined values in input' => sub {
    my ($result, $msg) = filter(
        { name => 'Mia', email => undef, phone => '555-9999' },
        ['name'],
        ['email', 'phone'],
    );

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Mia', 'Defined value';
    ok !defined $result->{email}, 'Undefined value preserved';
    is $result->{phone}, '555-9999', 'Other field present';
};

done_testing();
