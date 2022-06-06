# NAME

MooX::Params::CompiledValidators - A [Moo::Role](https://metacpan.org/pod/Moo%3A%3ARole) for using [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler).

# SYNOPSIS
```perl
    use Moo;
    use Types::Standard qw( Str );
    with 'MooX::Params::CompiledValidators';

    sub any_sub {
        my $self = shift;
        my $arguments = $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required),
            },
            { @_ }
        );
        ...
    }

    # Implement a local version of the ValidationTemplates
    sub ValidationTemplates {
        return {
            customer_id => { type => Str },
        };
    }
```

# DESCRIPTION

This role uses [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler) to create parameter validators on a
per method basis that can be used in the methods of your [Moo](https://metacpan.org/pod/Moo) or [Moose](https://metacpan.org/pod/Moose)
projects.

The objective is to create a single set of validation criteria - ideally in a
seperate role that can be used along side of this role - that can be used to
consistently validate parameters throughout your application.

The validators created by [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler) are cached after they
are created the first time, so they will only be created once.

## Validation-Templates

A validation-template is a structure (HashRef) that
`Params::ValidationCompiler::validation_for()` uses to validate the parameter
and basically contains three keys:

- **type**

    `Params::ValidationCompiler` supports a number of type systems, see their documentation.

- **default**

    Define a default value for this parameter, either a simple scalar or a code-ref
    that returns a more complex value.

- **optional**

    By default false, required parameters are preferred by `Params::ValidationCompiler`

## The _required_ `ValidationTemplates()` method

The objective of this module (Role) is to standardise parameter validation by
defining a single set of Validation Templates for all the parameters in a project.
This is why the `MooX::Params::CompiledValidators` role **`requires`** a
`ValidationTemplates` method in its consuming class. The `ValidationTemplates`
method is needed for the `parameter()` method that is also supplied by this
role.

This could be as simple as:
```perl
    package MyTemplates;
    use Moo::Role;

    use Types::Standard qw(Str);
    sub ValidationTemplates {
        return {
            customer_id => { type => Str },
            username    => { type => Str },
        };
    }
```

## The `Required` method

`validation_for()` uses the attribute `optional` so this returns `0`

## The `Optional` method

`validation_for()` uses the attribute `optional` so this returns `1`

## The `validate_parameters()` method

Returns a (locked) hashref with validated parameters or `die()`s trying...

Given:
```perl
    use Moo;
    with 'MooX::Params::CompiledValidators';

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_parameters(
            {
                customer_id => { type => Str, optional => 0 },
                username    => { type => Str, optional => 0 },
            },
            { @_ }
        );
        return {
            customer => $args->{customer_id},
            username => $args->{username},
        };
    }
```

One would call this as:
```perl
    my $user_info = $instance->show_user_info(
        customer_id => 'Blah42',
        username    => 'blah42',
    );
```

### Parameters

Positional:

1. `$validation_templates`

    A hashref with the parameter-names as keys and the ["Validation-Templates"](#validation-templates) as values.

2. `$values`

    A hashref with the actual parameter-name/value pairs that need to be validated.

### Responses

- **Success** (scalar context, recommended)

    A locked hashref.

- **Success** (list context, only if you need to manipulate the result)

    A list that can be coerced into a hash.

- **Error**

    Anything [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler) will throw for invalid values.

## The `validate_positional_parameters()` method

Like `$instance->validate_parameters()`, but now the pairs of _name_,
_validation-template_ are passed in an arrayref, that is split into lists of
the names and templates. The parameters passed -as an array- will be validated
against the templates-list, and the validated results are combined back into
a hash with name/value pairs. This makes the programming interface almost the
same for both named-parameters and positional-parameters.

Returns a (locked) hashref with validated parameters or `die()`s trying...

Given:
```perl
    use Moo;
    with 'MooX::Params::CompiledValidators';

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_positional_parameters(
            [
                customer_id => { type => Str, optional => 0 },
                username    => { type => Str, optional => 0 },
            ],
            \@_
        );
        return {
            customer => $args->{customer_id},
            username => $args->{username},
        };
    }
```

One would call this as:
```perl
    my $user_info = $instance->show_user_info('Blah42', 'blah42');
```

### Parameters

Positional:

1. `$validation_templates`

    A arrayref with pairs of parameter-names and ["validation templates"](#validation-templates).

2. `$values`

    A arrayref with the actual values that need to be validated.

### Responses

- **Success** (list context)

    A list that can be coerced into a hash.

- **Success** (scalar context)

    A locked hashref.

- **Error**

    Anything [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler) will throw for invalid values.

## The `parameter()` method

Returns a `parameter_name`, `validation_template` pair that can be used in the
`parameters` argument hashref for
`Params::ValidationCompiler::validadion_for()`

### Parameters

Positional:

1. `$name` (_Required_)

    The name of this parameter (it must be a kind of identifier: `m{^\w+$}`)

2. `$required` (_Optional_)

    One of `$class->Required` or `$class->Optional` but will default to
    `$class->Required`.

3. `$extra` (_Optional_)

    This optional HashRef can contain the fields supported by the `params`
    parameter of `validation_for()`, even overriding the ones set by the `$class->ValidationTemplates()` for this `$name` - although `optional` is set
    by the previous parameter in this sub.

    This parameter is mostly used for the extra feature to pass a lexically scoped
    variable via [store](#the-extra-store-attribute).

### Responses

- **Success**

    A list of `$parameter_name` and `$validation_template`.
```perl
    (this_parm => { optional => 0, type => Str, store => \my $this_param })
```

### NOTE on "Unknown" parameters

Whenever `$self->parameter()` is called with a parameter-name that doesn't
resolve to a template in the `ValidationTemplates()` hash, a default "empty"
template is produced. This will mean that there will be no validation on that
value, although one could pass one as the third parameter:

```perl
    use Moo;
    use Types::Standard qw( StrMatch );
    with qw(
        MyTemplates
        MooX::Params::CompiledValidators
    );

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required),
                $self->parameter(
                    email => $self->Required,
                    { type => StrMatch[ qr{^ [-.\w]+ @ [-.\w]+ $}x ] },
                ),
            },
            {@_}
        );
        return {
            customer => $args->{customer_id},
            email    => $args->{email},
        };
    }
```

## The extra `store` attribute

Both `validate_parameters()` and `validate_positional_parameters` support the
extra `store` attribute in a validation template that should be a
scalar-reference where we store the value after successful validation.

One can pick and mix with validation templates:
```perl
    use Moo;
    use Types::Standard qw( StrMatch );
    with qw(
        MyTemplates
        MooX::Params::CompiledValidators
    );

    sub show_user_info {
        my $self = shift;
        $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required, {store => \my $customer_id),
                email => {
                    type     => StrMatch[ qr{^ [-.\w]+ @ [-.\w]+ $}x ],
                    optional => 0,
                    store    => \my $email
                },
            },
            { @_ }
        );
        return {
            customer => $customer_id,
            email    => $email,
        };
    }
```

One would call this as:
```perl
    my $user_info = $instance->show_user_info(
        customer_id => 'Blah42',
        email       => 'blah42@some.tld',
    );
```

One could argue that using (lexical) variables -instead of addressing keys of a
locked hash- triggers the error caused by a typo at _compile-time_ rather than
at _run-time_.

**NOTE**: In order to keep the scope of the variable, where the value is stored,
limited, the `store` attribute should only be used from the per method override
option `extra` for `$self->parameter()`.

# AUTHOR

© MMXXI - Abe Timmerman <abeltje@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
