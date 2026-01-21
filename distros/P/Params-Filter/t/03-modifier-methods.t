#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Params::Filter;

# Modifier Methods Tests

subtest 'set_required - with arrayref' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id', 'name']);

    my ($result, $msg) = $filter->apply({
        id   => 1,
        name => 'Test',
    });

    ok $result, 'Validation succeeds with set required fields';
    is $result->{id}, 1, 'First required field present';
    is $result->{name}, 'Test', 'Second required field present';
};

subtest 'set_required - with list' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required('id', 'email');

    my ($result, $msg) = $filter->apply({
        id    => 1,
        email => 'test@example.com',
    });

    ok $result, 'Validation succeeds with list of required fields';
    is $result->{id}, 1, 'First required field from list';
    is $result->{email}, 'test@example.com', 'Second required field from list';
};

subtest 'set_required - empty call sets to empty array' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id', 'name'],
        accepted => ['name', 'email'],
    });

    $filter->set_required();

    my ($result, $msg) = $filter->apply({
        name  => 'Test',
        email => 'test@example.com',
    });

    ok $result, 'Validation succeeds with no required fields';
    is $result->{name}, 'Test', 'Field accepted when required is empty';
    is $result->{email}, 'test@example.com', 'Other accepted fields work';
    ok scalar keys %$result == 2, 'Only accepted fields present';
};

subtest 'set_required - filters undef values' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required('id', undef, 'name', undef);

    my ($result, $msg) = $filter->apply({
        id   => 1,
        name => 'Test',
    });

    ok $result, 'Validation succeeds with undef values filtered';
    is $result->{id}, 1, 'id field required';
    is $result->{name}, 'Test', 'name field required';
    ok !exists $result->{undef}, 'undef values filtered out';
};

subtest 'set_accepted - with arrayref' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->set_accepted(['name', 'email']);

    my ($result, $msg) = $filter->apply({
        id     => 1,
        name   => 'Test',
        email  => 'test@example.com',
        extra  => 'ignored',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    is $result->{name}, 'Test', 'Accepted field present';
    is $result->{email}, 'test@example.com', 'Second accepted field present';
    ok !exists $result->{extra}, 'Unaccepted field not included';
};

subtest 'set_accepted - with list' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->set_accepted('value', 'flag');

    my ($result, $msg) = $filter->apply({
        id    => 1,
        value => 100,
        flag  => 'on',
    });

    ok $result, 'Validation succeeds with list of accepted fields';
    is $result->{value}, 100, 'First accepted field from list';
    is $result->{flag}, 'on', 'Second accepted field from list';
};

subtest 'set_accepted - empty call rejects all fields' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->set_accepted();

    my ($result, $msg) = $filter->apply({
        id    => 1,
        name  => 'Test',
        email => 'test@example.com',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Only required field present';
    ok !exists $result->{name}, 'Accepted empty, name not included';
    ok !exists $result->{email}, 'Accepted empty, email not included';
};

subtest 'set_accepted - filters undef values' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->set_accepted('name', undef, 'email');

    my ($result, $msg) = $filter->apply({
        id    => 1,
        name  => 'Test',
        email => 'test@example.com',
    });

    ok $result, 'Validation succeeds';
    is $result->{name}, 'Test', 'name accepted';
    is $result->{email}, 'test@example.com', 'email accepted';
};

subtest 'accept_all - sets wildcard' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all();

    my ($result, $msg) = $filter->apply({
        id     => 1,
        name   => 'Test',
        email  => 'test@example.com',
        value  => 42,
        flag   => 'on',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    is $result->{name}, 'Test', 'Wildcard accepts name';
    is $result->{email}, 'test@example.com', 'Wildcard accepts email';
    is $result->{value}, 42, 'Wildcard accepts value';
    is $result->{flag}, 'on', 'Wildcard accepts flag';
};

subtest 'accept_all - with exclusions' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all()
            ->set_excluded(['password', 'secret']);

    my ($result, $msg) = $filter->apply({
        id       => 1,
        name     => 'Test',
        password => 'hidden',
        secret   => 'classified',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    is $result->{name}, 'Test', 'Wildcard accepts name';
    ok !exists $result->{password}, 'Excluded field removed';
    ok !exists $result->{secret}, 'Excluded field removed';
};

subtest 'accept_none - sets empty array' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_none();

    my ($result, $msg) = $filter->apply({
        id    => 1,
        name  => 'Test',
        email => 'test@example.com',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Only required field present';
    ok !exists $result->{name}, 'accept_none prevents extra fields';
    ok !exists $result->{email}, 'accept_none prevents extra fields';
};

subtest 'accept_none then accept_all' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_none()
            ->accept_all();

    my ($result, $msg) = $filter->apply({
        id   => 1,
        name => 'Test',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    is $result->{name}, 'Test', 'accept_all overrides accept_none';
};

subtest 'set_excluded - with arrayref' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all()
            ->set_excluded(['password', 'ssn']);

    my ($result, $msg) = $filter->apply({
        id       => 1,
        name     => 'Test',
        password => 'secret123',
        ssn      => '123-45-6789',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    is $result->{name}, 'Test', 'Non-excluded field present';
    ok !exists $result->{password}, 'Excluded field removed';
    ok !exists $result->{ssn}, 'Excluded field removed';
};

subtest 'set_excluded - with list' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all()
            ->set_excluded('token', 'api_key');

    my ($result, $msg) = $filter->apply({
        id      => 1,
        name    => 'Test',
        token   => 'abc123',
        api_key => 'xyz789',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    ok !exists $result->{token}, 'Excluded from list';
    ok !exists $result->{api_key}, 'Excluded from list';
};

subtest 'set_excluded - empty call removes exclusions' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all()
            ->set_excluded(['password']);

    # First call with exclusion
    my ($result1, $msg1) = $filter->apply({
        id       => 1,
        password => 'secret',
    });

    ok !exists $result1->{password}, 'Password excluded initially';

    # Remove exclusion
    $filter->set_excluded();

    my ($result2, $msg2) = $filter->apply({
        id       => 2,
        password => 'now_included',
    });

    ok $result2, 'Validation succeeds';
    is $result2->{password}, 'now_included', 'Password included after exclusion cleared';
};

subtest 'set_excluded - filters undef values' => sub {
    my $filter = Params::Filter->new_filter();

    $filter->set_required(['id'])
            ->accept_all()
            ->set_excluded('password', undef, 'secret');

    my ($result, $msg) = $filter->apply({
        id       => 1,
        password => 'hidden',
        secret   => 'classified',
    });

    ok $result, 'Validation succeeds';
    ok !exists $result->{password}, 'password excluded';
    ok !exists $result->{secret}, 'secret excluded';
};

subtest 'Method chaining - multiple modifiers' => sub {
    my $filter = Params::Filter->new_filter();

    my ($result, $msg) = $filter->set_required(['id'])
                          ->set_accepted(['name', 'email'])
                          ->set_excluded(['temp'])
                          ->apply({
                              id    => 1,
                              name  => 'Test',
                              email => 'test@example.com',
                              temp  => 'should_be_removed',
                              extra => 'not_accepted',
                          });

    ok $result, 'Validation succeeds with chained modifiers';
    is $result->{id}, 1, 'Required field from chain';
    is $result->{name}, 'Test', 'Accepted field from chain';
    is $result->{email}, 'test@example.com', 'Accepted field from chain';
    ok !exists $result->{temp}, 'Excluded field removed';
    ok !exists $result->{extra}, 'Unaccepted field not included';
};

subtest 'Method chaining - all modifiers' => sub {
    my $filter = Params::Filter->new_filter();

    my ($result, $msg) = $filter->set_required(['user_id'])
                          ->accept_none()
                          ->set_excluded(['nothing'])
                          ->set_accepted(['name'])
                          ->accept_all()
                          ->apply({
                              user_id => 1,
                              name    => 'Test User',
                              email   => 'user@example.com',
                              extra   => 'data',
                          });

    ok $result, 'Validation succeeds with complex chain';
    is $result->{user_id}, 1, 'Required field';
    is $result->{name}, 'Test User', 'Accepted field';
    is $result->{email}, 'user@example.com', 'Wildcard accepts email';
    is $result->{extra}, 'data', 'Wildcard accepts extra';
};

subtest 'Modifier after initial configuration' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted => ['name'],
    });

    # Modify initial configuration
    $filter->set_accepted(['name', 'email', 'phone']);

    my ($result, $msg) = $filter->apply({
        id    => 1,
        name  => 'Test',
        email => 'test@example.com',
        phone => '555-1234',
    });

    ok $result, 'Validation succeeds after modification';
    is $result->{name}, 'Test', 'Original accepted field still works';
    is $result->{email}, 'test@example.com', 'New accepted field works';
    is $result->{phone}, '555-1234', 'Another new accepted field works';
};

subtest 'Conditional configuration - production mode' => sub {
    my $is_production = 1;
    my $filter = Params::Filter->new_filter();

    if ($is_production) {
        $filter->set_required(['api_key', 'endpoint'])
                ->accept_none();
    }
    else {
        $filter->set_required(['debug_mode'])
                ->accept_all();
    }

    my ($result, $msg) = $filter->apply({
        api_key   => 'prod_key',
        endpoint  => 'https://api.example.com',
        debug     => 'should_be_ignored',
    });

    ok $result, 'Production configuration works';
    is $result->{api_key}, 'prod_key', 'Production required field';
    is $result->{endpoint}, 'https://api.example.com', 'Production required field';
    ok !exists $result->{debug}, 'Non-accepted field ignored';
};

subtest 'Conditional configuration - debug mode' => sub {
    my $is_production = 0;
    my $filter = Params::Filter->new_filter();

    if ($is_production) {
        $filter->set_required(['api_key', 'endpoint'])
                ->accept_none();
    }
    else {
        $filter->set_required(['debug_mode'])
                ->accept_all();
    }

    my ($result, $msg) = $filter->apply({
        debug_mode => 1,
        verbose    => 1,
        trace      => 1,
        extra      => 'data',
    });

    ok $result, 'Debug configuration works';
    is $result->{debug_mode}, 1, 'Debug required field';
    is $result->{verbose}, 1, 'Wildcard accepts verbose';
    is $result->{trace}, 1, 'Wildcard accepts trace';
    is $result->{extra}, 'data', 'Wildcard accepts extra';
};

subtest 'Meta-programming - dynamic field lists' => sub {
    my $config = {
        required_fields => ['id', 'timestamp'],
        optional_fields => ['value', 'label'],
        excluded_fields => ['temp_id'],
    };

    my $filter = Params::Filter->new_filter();

    $filter->set_required($config->{required_fields})
            ->set_accepted($config->{optional_fields})
            ->set_excluded($config->{excluded_fields});

    my ($result, $msg) = $filter->apply({
        id       => 1,
        timestamp => time,
        value    => 100,
        label    => 'Test',
        temp_id  => 'should_be_excluded',
    });

    ok $result, 'Dynamic configuration works';
    is $result->{id}, 1, 'Dynamic required field';
    is $result->{value}, 100, 'Dynamic accepted field';
    ok !exists $result->{temp_id}, 'Dynamic excluded field';
};

subtest 'Progressive configuration - building validator' => sub {
    my $filter = Params::Filter->new_filter();

    # Start with basic config
    $filter->set_required(['id']);

    my ($result1, $msg1) = $filter->apply({ id => 1 });
    ok $result1, 'Basic config works';

    # Add accepted fields
    $filter->set_accepted(['name', 'email']);

    my ($result2, $msg2) = $filter->apply({
        id    => 2,
        name  => 'Test',
        email => 'test@example.com',
    });
    ok $result2, 'Enhanced config works';
    is $result2->{name}, 'Test', 'New accepted field works';

    # Add exclusions
    $filter->set_excluded(['temp']);

    my ($result3, $msg3) = $filter->apply({
        id    => 3,
        name  => 'Another',
        temp  => 'removed',
    });
    ok $result3, 'Config with exclusions works';
    ok !exists $result3->{temp}, 'Exclusion works';
};

done_testing();
