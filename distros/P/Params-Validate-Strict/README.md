# NAME

Params::Validate::Strict - Validates a set of parameters against a schema

# VERSION

Version 0.10

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

- `schema`

    A reference to a hash that defines the validation rules for each parameter.
    The keys of the hash are the parameter names, and the values are either a string representing the parameter type or a reference to a hash containing more detailed rules.

- `args`

    A reference to a hash containing the parameters to be validated.  The keys of the hash are the parameter names, and the values are the parameter values.

It takes one optional argument:

- `unknown_parameter_handler`

    This parameter describes what to do when a parameter is given that is not in the schema of valid parameters.
    It must be one of `die` (the default), `warn`, or `ignore`.

The schema can define the following rules for each parameter:

- `type`

    The data type of the parameter.
    Valid types are `string`, `integer`, `number`, `hashref`, `arrayref`, `object` and `coderef`.

- `can`

    The parameter must be an object which understands the method `can`.

- `isa`

    The parameter must be an object of type `isa`.

- `memberof`

    The parameter must be a member of the given arrayref.

- `min`

    The minimum length (for strings), value (for numbers) or number of keys (for hashrefs).

- `max`

    The maximum length (for strings), value (for numbers) or number of keys (for hashrefs).

- `matches`

    A regular expression that the parameter value must match.

- `nomatch`

    A regular expression that the parameter value must not match.

- `callback`

    A code reference to a subroutine that performs custom validation logic.
    The subroutine should accept the parameter value as an argument and return true if the value is valid, false otherwise.

- `optional`

    A boolean value indicating whether the parameter is optional.
    If true, the parameter is not required.
    If false or omitted, the parameter is required.

If a parameter is optional and its value is `undef`,
validation will be skipped for that parameter.

If the validation fails, the function will `croak` with an error message describing the validation failure.

If the validation is successful, the function will return a reference to a new hash containing the validated and (where applicable) coerced parameters.  Integer and number parameters will be coerced to their respective types.

# MIGRATION FROM LEGACY VALIDATORS

## From [Params::Validate](https://metacpan.org/pod/Params%3A%3AValidate)

    # Old style
    validate(@_, {
        name => { type => SCALAR },
        age  => { type => SCALAR, regex => qr/^\d+$/ }
    });

    # New style
    validate_strict(
        schema => {
            name => 'string',
            age  => { type => 'integer', min => 0 }
        },
        args => { @_ }
    );

## From [Type::Params](https://metacpan.org/pod/Type%3A%3AParams)

    # Old style
    my ($name, $age) = validate_positional \@_, Str, Int;

    # New style - requires converting to named parameters first
    my %args = (name => $_[0], age => $_[1]);
    my $validated = validate_strict(
        schema => { name => 'string', age => 'integer' },
        args => \%args
    );

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# FORMAL SPECIFICATION

    [PARAM_NAME, VALUE, TYPE_NAME, CONSTRAINT_VALUE]

    ValidationRule ::= SimpleType | ComplexRule

    SimpleType ::= string | integer | number | arrayref | hashref | coderef | object

    ComplexRule == [
        type: TYPE_NAME;
        min: ℕ₁;
        max: ℕ₁;
        optional: 𝔹;
        matches: REGEX;
        nomatch: REGEX;
        memberof: seq VALUE;
        callback: FUNCTION;
        isa: TYPE_NAME;
        can: METHOD_NAME
    ]

    Schema == PARAM_NAME ⇸ ValidationRule

    Arguments == PARAM_NAME ⇸ VALUE

    ValidatedResult == PARAM_NAME ⇸ VALUE

    │ ∀ rule: ComplexRule • rule.min ≤ rule.max
    │ ∀ schema: Schema; args: Arguments •
    │   dom(validate_strict(schema, args)) ⊆ dom(schema) ∪ dom(args)

    validate_strict: Schema × Arguments → ValidatedResult

    ∀ schema: Schema; args: Arguments •
      let result == validate_strict(schema, args) •
        (∀ name: dom(schema) ∩ dom(args) •
          name ∈ dom(result) ⇒
          type_matches(result(name), schema(name))) ∧
        (∀ name: dom(schema) •
          ¬optional(schema(name)) ⇒ name ∈ dom(args))

    type_matches: VALUE × ValidationRule → 𝔹

# BUGS

# SEE ALSO

- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)
- [Params::Validate](https://metacpan.org/pod/Params%3A%3AValidate)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

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
