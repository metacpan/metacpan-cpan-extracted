# NAME

Params::Validate::Strict - Validates a set of parameters against a schema

# VERSION

Version 0.02

# SYNOPSIS

    my $schema = {
        username => { type => 'string', min => 3, max => 50 },
        age => { type => 'integer', min => 0, max => 150 },
    };

    my $args = {
         username => 'john_doe',
         age => '30',   # Will be coerced to integer
    };

    my $validated_args = validate_strict(schema => $schema, args => $args);

    if (defined $validated_args) {
        print "Example 1: Validation successful!\n";
        print 'Username: ', $validated_args->{username}, "\n";
        print 'Age: ', $validated_args->{age}, "\n";    # It's an integer now
    } else {
        print "Example 1: Validation failed: $@\n";
    }

# METHODS

## validate\_strict

Validates a set of parameters against a schema.

This function takes two mandatory arguments:

- `$schema`

    A reference to a hash that defines the validation rules for each parameter.  The keys of the hash are the parameter names, and the values are either a string representing the parameter type or a reference to a hash containing more detailed rules.

- `$args`

    A reference to a hash containing the parameters to be validated.  The keys of the hash are the parameter names, and the values are the parameter values.

It takes one optional argument:

- `$unknown_parameter_handler`

    This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
    It must be one of `die` (the default), `warn`, or `ignore`.

The schema can define the following rules for each parameter:

- `type`

    The data type of the parameter.  Valid types are `string`, `integer`, and `number`.

- `min`

    The minimum length (for strings) or value (for numbers).

- `max`

    The maximum length (for strings) or value (for numbers).

- `matches`

    A regular expression that the parameter value must match.

- `callback`

    A code reference to a subroutine that performs custom validation logic. The subroutine should accept the parameter value as an argument and return true if the value is valid, false otherwise.

- `optional`

    A boolean value indicating whether the parameter is optional. If true, the parameter is not required.  If false or omitted, the parameter is required.

If a parameter is optional and its value is `undef`,
validation will be skipped for that parameter.

If the validation fails, the function will `croak` with an error message describing the validation failure.

If the validation is successful, the function will return a reference to a new hash containing the validated and (where applicable) coerced parameters.  Integer and number parameters will be coerced to their respective types.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

- [Params::Validate](https://metacpan.org/pod/Params%3A%3AValidate)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-params-validate-strict at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Strict](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Strict).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Params::Validate::Strict

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Params-Validate-Strict](https://metacpan.org/dist/Params-Validate-Strict)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Validate-Strict](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Validate-Strict)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Params-Validate-Strict](http://matrix.cpantesters.org/?dist=Params-Validate-Strict)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Params::Validate::Strict](http://deps.cpantesters.org/?module=Params::Validate::Strict)

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2
