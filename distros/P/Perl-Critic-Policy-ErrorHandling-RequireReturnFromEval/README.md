# NAME

Perl::Critic::Policy::ErrorHandling::RequireReturnFromEval - Require explicit return in eval blocks

# SYNOPSIS

    # Bad
    my $result = eval { some_function() };

    # Good
    my $result = eval { return some_function() };

# DESCRIPTION

When using `eval` as an expression to capture a return value, the eval block
should use an explicit `return` statement. This makes the intent clear and
avoids confusion about what the eval block returns.

This policy catches eval blocks that lack an explicit `return`.

    # Violation
    my $params = eval { JSON::decode_json($content) };

    # No violation
    my $params = eval { return JSON::decode_json($content) };

This policy only applies to `eval { ... }` blocks, not `eval "string"`.

# CONFIGURATION

This policy is not configurable. It has no options.

# METHODS

## default\_severity

Returns `$SEVERITY_MEDIUM`.

## default\_themes

Returns `style`.

## applies\_to

Returns `PPI::Structure::Block`.

## violates

Checks if an eval block uses an explicit `return` statement.

# AUTHOR

Blaine Motsinger <blaine@renderorange.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Blaine Motsinger

This is free software, licensed under:

    The GNU General Public License, Version 2, June 1991
