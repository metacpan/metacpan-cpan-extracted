#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 30;

use Params::Validate::Strict qw(validate_strict);

# Basic string blacklist
{
    my $schema = {
        username => {
            type => 'string',
            notmemberof => ['admin', 'root', 'system']
        }
    };

    # Valid username (not in blacklist)
    my $result = validate_strict(
        schema => $schema,
        input => { username => 'johndoe' }
    );
    ok(defined($result), 'Username not in blacklist passes');
    is($result->{username}, 'johndoe', 'Username preserved');

    # Invalid username (in blacklist)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'admin' }
        );
    } qr/must not be one of admin, root, system/, 'Blacklisted username fails';

    # Another blacklisted value
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'root' }
        );
    } qr/must not be one of/, 'Another blacklisted username fails';
}

# Numeric blacklist
{
    my $schema = {
        port => {
            type => 'integer',
            notmemberof => [22, 23, 25, 80, 443],  # Reserved ports
            min => 1,
            max => 65535
        }
    };

    # Valid port (not reserved)
    my $result = validate_strict(
        schema => $schema,
        input => { port => 8080 }
    );
    ok(defined($result), 'Non-reserved port passes');
    is($result->{port}, 8080, 'Port value preserved');

    # Blacklisted port
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { port => 22 }
        );
    } qr/must not be one of/, 'Reserved port 22 fails';

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { port => 443 }
        );
    } qr/must not be one of/, 'Reserved port 443 fails';
}

# Float/number blacklist
{
    my $schema = {
        rating => {
            type => 'number',
            notmemberof => [0, 2.5, 7.5],  # Disallowed ratings
            min => 0,
            max => 10
        }
    };

    # Valid rating
    my $result = validate_strict(
        schema => $schema,
        input => { rating => 8.5 }
    );
    ok(defined($result), 'Allowed rating passes');
    is($result->{rating}, 8.5, 'Rating preserved');

    # Blacklisted rating (integer)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { rating => 0 }
        );
    } qr/must not be one of/, 'Blacklisted rating 0 fails';

    # Blacklisted rating (float)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { rating => 2.5 }
        );
    } qr/must not be one of/, 'Blacklisted rating 2.5 fails';
}

# Combining notmemberof with other constraints
{
    my $schema = {
        username => {
            type => 'string',
            notmemberof => ['admin', 'root', 'system'],
            min => 3,
            max => 20,
            matches => qr/^[a-z0-9_]+$/
        }
    };

    # Valid username
    my $result = validate_strict(
        schema => $schema,
        input => { username => 'john_doe' }
    );
    ok(defined($result), 'Valid username with multiple constraints passes');

    # Fails blacklist
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'admin' }
        );
    } qr/must not be one of/, 'Blacklist check happens';

    # Fails other constraint (too short)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'ab' }
        );
    } qr/too short/, 'Other constraints still checked';
}

# Optional field with notmemberof
{
    my $schema = {
        nickname => {
            type => 'string',
            optional => 1,
            notmemberof => ['admin', 'root']
        }
    };

    # Optional field not provided
    my $result = validate_strict(
        schema => $schema,
        input => {}
    );
    ok(defined($result), 'Optional field can be omitted');

    # Optional field provided and valid
    $result = validate_strict(
        schema => $schema,
        input => { nickname => 'johnny' }
    );
    ok(defined($result), 'Optional field with valid value passes');

    # Optional field provided but blacklisted
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { nickname => 'admin' }
        );
    } qr/must not be one of/, 'Optional field still checked against blacklist';
}

# Custom error message with notmemberof
{
    my $schema = {
        username => {
            type => 'string',
            notmemberof => ['admin', 'root', 'system', 'guest'],
            error_msg => 'This username is reserved and cannot be used'
        }
    };

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'guest' }
        );
    } qr/This username is reserved and cannot be used/, 'Custom error message shown';
}

# Empty blacklist array
{
    my $schema = {
        value => {
            type => 'string',
            notmemberof => []  # Empty blacklist - everything allowed
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { value => 'anything' }
    );
    ok(defined($result), 'Empty blacklist allows any value');
}

# Single item blacklist
{
    my $schema = {
        status => {
            type => 'string',
            notmemberof => ['deleted']  # Only one blacklisted value
        }
    };

    # Valid status
    my $result = validate_strict(
        schema => $schema,
        input => { status => 'active' }
    );
    ok(defined($result), 'Non-blacklisted value passes');

    # Blacklisted status
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'deleted' }
        );
    } qr/must not be one of deleted/, 'Single blacklisted value fails';
}

# Both memberof and notmemberof (contradictory - should catch in validation)
{
    my $schema = {
        status => {
            type => 'string',
            memberof => ['active', 'inactive', 'pending'],
            notmemberof => ['pending']  # Contradiction
        }
    };

    # This should ideally be caught as a schema error, but if not:
    # A value can pass memberof but still fail notmemberof
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'pending' }
        );
    } qr/must not be one of pending/, 'notmemberof overrides memberof when both present';

    # Non-contradictory value
    my $result = validate_strict(
        schema => $schema,
        input => { status => 'active' }
    );
    ok(defined($result), 'Non-contradictory value passes both checks');
}

# notmemberof with transformed values
{
    my $schema = {
        username => {
            type => 'string',
            transform => sub { lc($_[0]) },
            notmemberof => ['admin', 'root', 'system']
        }
    };

    # Uppercase input gets transformed and then checked
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'ADMIN' }
        );
    } qr/must not be one of/, 'Transformed value checked against blacklist';

    # Valid after transform
    my $result = validate_strict(
        schema => $schema,
        input => { username => 'JohnDoe' }
    );
    ok(defined($result), 'Transformed non-blacklisted value passes');
    is($result->{username}, 'johndoe', 'Transform applied before blacklist check');
}

# notmemberof with custom types
{
    my $custom_types = {
        safe_username => {
            type => 'string',
            notmemberof => ['admin', 'root', 'system', 'administrator'],
            min => 3,
            max => 20,
            matches => qr/^[a-z0-9_]+$/
        }
    };

    my $schema = {
        username => { type => 'safe_username' }
    };

    # Valid username
    my $result = validate_strict(
        schema => $schema,
        input => { username => 'john_doe' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Custom type with notmemberof passes');

    # Blacklisted in custom type
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'administrator' },
            custom_types => $custom_types
        );
    } qr/must not be one of/, 'Custom type blacklist enforced';
}

# Invalid notmemberof value (not an array)
{
    my $schema = {
        username => {
            type => 'string',
            notmemberof => 'admin'  # Should be arrayref
        }
    };

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { username => 'johndoe' }
        );
    } qr/must be an array reference/, 'notmemberof requires array reference';
}

done_testing();
