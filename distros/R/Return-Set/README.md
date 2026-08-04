# NAME

Return::Set - Return a value optionally validated against a strict schema

# VERSION

Version 0.05

# SYNOPSIS

    use Return::Set qw(set_return);

    return set_return($value);
    return set_return($value, { type => 'integer' });
    return set_return({ output => $value, schema => { type => 'integer' } });

# DESCRIPTION

If a validation schema is provided, the value is validated using
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
If validation fails, it croaks.

When used hand-in-hand with [Params::Get](https://metacpan.org/pod/Params%3A%3AGet),
you should be able to formally specify the input and output sets for a method.

Exports a single function, `set_return`, which returns a given value.

# FUNCTIONS

## set\_return

Returns the given value, optionally validating it against a schema.

Three calling forms are accepted:

- set\_return($value)

    Returns `$value` immediately with no validation.

- set\_return($value, $schema)

    Returns `$value` after validating it against `$schema`
    (a [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) schema hashref, e.g. `{ type => 'integer' }`).
    Croaks if validation fails.

- set\_return(\\%args)

    Named-parameter form.
    `%args` may contain `output` (preferred) or `value` (accepted for backwards
    compatibility) for the return value, and `schema` for the optional schema.
    Croaks if validation fails.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
