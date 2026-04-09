#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Params::Filter;

# OO Interface Tests

subtest 'new_filter constructor' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted => ['name', 'value'],
        excluded => ['secret'],
    });

    ok $filter, 'Constructor returns object';
    isa_ok $filter, 'Params::Filter';
};

subtest 'new_filter with lowercase debug' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        debug    => 1,
    });

    ok $filter, 'Constructor accepts lowercase debug';
};

subtest 'new_filter with uppercase DEBUG' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        DEBUG    => 1,
    });

    ok $filter, 'Constructor accepts uppercase DEBUG';
};

subtest 'apply method - valid data' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['user_id'],
        accepted => ['username', 'email'],
    });

    my ($result, $msg) = $filter->apply({
        user_id  => 123,
        username => 'testuser',
        email    => 'test@example.com',
    });

    ok $result, 'Validation succeeds';
    is $result->{user_id}, 123, 'Required field present';
    is $result->{username}, 'testuser', 'Accepted field present';
    like $msg, qr/Admitted/, 'Success status';
};

subtest 'apply method - missing required' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id', 'name'],
        accepted => ['value'],
    });

    my ($result, $msg) = $filter->apply({
        id => 1,
        # name missing
    });

    ok !$result, 'Validation fails';
    like $msg, qr/Unable to initialize without (all )?required arguments/, 'Error message';
};

subtest 'apply method - excluded fields' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted  => ['*'],
        excluded  => ['password', 'secret'],
    });

    my ($result, $msg) = $filter->apply({
        id       => 42,
        name     => 'Test',
        password => 'hidden',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 42, 'Required field present';
    is $result->{name}, 'Test', 'Wildcard accepted field';
    ok !exists $result->{password}, 'Excluded field removed';
};

subtest 'apply method - debug mode' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted => ['name'],
        excluded => ['secret'],
        debug    => 1,
    });

    my ($result, $msg) = $filter->apply({
        id     => 1,
        name   => 'Test',
        secret => 'hidden',
        extra  => 'ignored',
    });

    ok $result, 'Validation succeeds';
    like $msg, qr/excluded/, 'Debug mentions excluded fields';
    like $msg, qr/unrecognized/, 'Debug mentions unrecognized fields';
};

subtest 'Reusable filter - multiple validations' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['username'],
        accepted => ['email'],
    });

    my ($result1, $msg1) = $filter->apply({
        username => 'alice',
        email    => 'alice@example.com',
    });

    my ($result2, $msg2) = $filter->apply({
        username => 'bob',
        email    => 'bob@example.com',
    });

    ok $result1 && $result2, 'Both validations succeed';
    is $result1->{username}, 'alice', 'First result correct';
    is $result2->{username}, 'bob', 'Second result correct';
};

subtest 'apply with arrayref input' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted  => ['name', 'flag'],
    });

    my ($result, $msg) = $filter->apply(
        ['id', 1, 'name', 'Test', 'flag']  # Odd!
    );

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Field from array';
    is $result->{name}, 'Test', 'Field from array';
    is $result->{flag}, 1, 'Odd element becomes flag';
};

subtest 'apply with scalar input' => sub {
    my $filter = Params::Filter->new_filter({
        required => [],
        accepted  => ['_'],
        debug     => 1,
    });

    my ($result, $msg) = $filter->apply('scalar input');

    ok $result, 'Validation succeeds';
    is $result->{_}, 'scalar input', 'Scalar with _ key';
    like $msg, qr/Plain text argument/, 'Debug warns about scalar';
};

subtest 'apply - empty accepted list (required only)' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted  => [],
    });

    my ($result, $msg) = $filter->apply({
        id    => 1,
        extra => 'ignored',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field present';
    ok !exists $result->{extra}, 'Extra field not included';
};

subtest 'apply - wildcard in accepted' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
        accepted  => ['*'],
        excluded  => [],
    });

    my ($result, $msg) = $filter->apply({
        id      => 1,
        field1  => 'a',
        field2  => 'b',
        field3  => 'c',
    });

    ok $result, 'Validation succeeds';
    is $result->{id}, 1, 'Required field';
    is $result->{field1}, 'a', 'Wildcard accepts field1';
    is $result->{field2}, 'b', 'Wildcard accepts field2';
    is $result->{field3}, 'c', 'Wildcard accepts field3';
};

subtest 'apply - return in scalar context' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
    });

    my $result = $filter->apply({ id => 1 });

    ok $result, 'Returns hashref in scalar context';
    is $result->{id}, 1, 'Result contains data';
};

subtest 'apply - return in list context' => sub {
    my $filter = Params::Filter->new_filter({
        required => ['id'],
    });

    my ($result, $msg) = $filter->apply({ id => 1 });

    ok $result, 'First element is hashref';
    like $msg, qr/Admitted/, 'Second element is status';
};

subtest 'Multiple filters with different rules' => sub {
    my $user_filter = Params::Filter->new_filter({
        required => ['username'],
        accepted => ['email'],
    });

    my $post_filter = Params::Filter->new_filter({
        required => ['title'],
        accepted => ['content'],
    });

    my ($user, $user_msg) = $user_filter->apply({
        username => 'alice',
    });

    my ($post, $post_msg) = $post_filter->apply({
        title => 'Test Post',
    });

    ok $user && $post, 'Both filters work independently';
    is $user->{username}, 'alice', 'User filter works';
    is $post->{title}, 'Test Post', 'Post filter works';
};

subtest 'new_filter with non-hashref argument defaults to empty config' => sub {
    # $args is truthy but ref() does not match /hash/ - the fallback to {} must fire.
    my $f_str   = Params::Filter->new_filter('a string');
    my $f_aref  = Params::Filter->new_filter([1, 2, 3]);
    my $f_int   = Params::Filter->new_filter(42);

    ok $f_str,  'String arg: object constructed';
    ok $f_aref, 'Arrayref arg: object constructed';
    ok $f_int,  'Integer arg: object constructed';

    # All should behave like new_filter({}) - no required or accepted fields
    my ($r1) = $f_str->apply({ anything => 1 });
    my ($r2) = $f_aref->apply({ anything => 1 });
    my ($r3) = $f_int->apply({ anything => 1 });

    ok $r1, 'String arg: apply succeeds with no config';
    ok $r2, 'Arrayref arg: apply succeeds with no config';
    ok $r3, 'Integer arg: apply succeeds with no config';
};

subtest 'new_filter with empty hashref fires OR defaults for all keys' => sub {
    # All four keys absent: required/accepted/excluded default to [],
    # and the debug chain evaluates all the way to 0.
    my $f = Params::Filter->new_filter({});

    ok $f, 'Object constructed from empty hashref';
    is ref($f->{required}), 'ARRAY', 'required defaults to arrayref';
    is ref($f->{accepted}), 'ARRAY', 'accepted defaults to arrayref';
    is ref($f->{excluded}), 'ARRAY', 'excluded defaults to arrayref';
    ok !$f->{debug}, 'debug defaults to 0';

    my ($result) = $f->apply({ any => 'value' });
    ok $result, 'apply succeeds with all-default config';
};

subtest 'apply with manually stripped object fields exercises || defaults' => sub {
    # The || [] / || 0 guards in apply() are defensive - they only fire if
    # someone manipulates the object after construction.
    my $f = Params::Filter->new_filter({ required => ['id'], accepted => ['name'] });
    delete $f->{accepted};
    delete $f->{excluded};
    delete $f->{debug};

    my ($result, $msg) = $f->apply({ id => 1, name => 'Oscar' });

    ok $result,          'apply survives missing accepted/excluded/debug keys';
    is $result->{id}, 1, 'Required field present';
};

done_testing();
