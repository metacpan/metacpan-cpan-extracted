# NAME

Return::Set - Return a value optionally validated against a strict schema

# VERSION

Version 0.01

# SYNOPSIS

    use Return::Set qw(set_return);

    my $value = set_return($value);  # Just returns $value

    my $value = set_return($value, { type => 'integer' });  # Validates $value is an integer

# DESCRIPTION

Exports a single function, `set_return`, which returns a given value.
If a validation schema is provided, the value is validated using
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
If validation fails, it croaks.

When used hand-in-hand with [Params::Get](https://metacpan.org/pod/Params%3A%3AGet) you should be able to formally specify the input and output sets for a method.

# METHODS

## set\_return($value, $schema)

Returns `$value`.
If `$schema` is provided, validates the value against it.
Croaks if validation fails.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
