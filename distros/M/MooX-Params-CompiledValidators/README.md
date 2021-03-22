# NAME

MooX::Params::CompiledValidators - Moo::Role for using [Params::ValidationCompiler](https://metacpan.org/pod/Params::ValidationCompiler)

# DESCRIPTION

Within the realm of `Params::ValidationCompiler`, validation of a parameter is
based on a template for validation.

## Validation templates

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

## The *required* `ValidationTemplates` method

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

## The `validate_parameters` method

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

## The `validate_positional_parameters` method

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

## The `parameter` method

This method creates a pair of the param-name and a basic validation-template.

```perl
    use Moo;
    with qw(
        MyTemplates
        MooX::Params::CompiledValidators
    );

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required),
                $self->parameter(username    => $self->Required),
            },
            { @_ }
        );
        return {
            customer => $args->{customer_id},
            username => $args->{username},
        };
    }
```

### The extra **`store`** attribute

Both `validate_parameters` and `validate_positional_parameters` support the
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
                    type     => StrMatch[ qr{^ [.\w]+ @ [.\w]+ $}x ],
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

### NOTE on "Unknown" parameters

Whenever `$self->parameter()` is called with a parameter-name that doesn't
resolve to a template in the `ValidationTemplates` hash, a default "empty"
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
                    { type     => StrMatch[ qr{^ [.\w]+ @ [.\w]+ $}x ] },
                ),
            },
            { @_ }
        );
        return {
            customer => $args->{customer_id},
            email    => $args->{email},
        };
    }
```

# STUFF

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

* http://www.perl.com/perl/misc/Artistic.html
* http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

