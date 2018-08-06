# NAME

Params::ValidationCompiler - Build an optimized subroutine parameter validator once, use it forever

# VERSION

version 0.30

# SYNOPSIS

    use Types::Standard qw( Int Str );
    use Params::ValidationCompiler qw( validation_for );

    {
        my $validator = validation_for(
            params => {
                foo => { type => Int },
                bar => {
                    type     => Str,
                    optional => 1,
                },
                baz => {
                    type    => Int,
                    default => 42,
                },
            },
        );

        sub foo {
            my %args = $validator->(@_);
        }
    }

    {
        my $validator = validation_for(
            params => [
                { type => Int },
                {
                    type     => Str,
                    optional => 1,
                },
            ],
        );

        sub bar {
            my ( $int, $str ) = $validator->(@_);
        }
    }

    {
        my $validator = validation_for(
            params => [
                foo => { type => Int },
                bar => {
                    type     => Str,
                    optional => 1,
                },
            ],
            named_to_list => 1,
        );

        sub baz {
            my ( $foo, $bar ) = $validator->(@_);
        }
    }

# DESCRIPTION

This module creates a customized, highly efficient parameter checking
subroutine. It can handle named or positional parameters, and can return the
parameters as key/value pairs or a list of values.

In addition to type checks, it also supports parameter defaults, optional
parameters, and extra "slurpy" parameters.

# PARAMETERS

This module has two options exports, `validation_for` and `source_for`. Both
of these subs accept the same options:

## params

An arrayref or hashref containing a parameter specification.

If you pass a hashref then the generated validator sub will expect named
parameters. The `params` value should be a hashref where the parameter names
are keys and the specs are the values.

If you pass an arrayref and `named_to_list` is false, the validator will
expect positional params. Each element of the `params` arrayref should be a
parameter spec.

If you pass an arrayref and `named_to_list` is true, the validator will
expect named params, but will return a list of values. In this case the
arrayref should contain a _list_ of key/value pairs, where parameter names
are the keys and the specs are the values.

Each spec can contain either a boolean or hashref. If the spec is a boolean,
this indicates required (true) or optional (false).

The spec hashref accepts the following keys:

- type

    A type object. This can be a [Moose](https://metacpan.org/pod/Moose) type (from [Moose](https://metacpan.org/pod/Moose) or
    [MooseX::Types](https://metacpan.org/pod/MooseX::Types)), a [Type::Tiny](https://metacpan.org/pod/Type::Tiny) type, or a [Specio](https://metacpan.org/pod/Specio) type.

    If the type has coercions, those will always be used.

- default

    This can either be a simple (non-reference) scalar or a subroutine
    reference. The sub ref will be called without any arguments (for now).

- optional

    A boolean indicating whether or not the parameter is optional. By default,
    parameters are required unless you provide a default.

## slurpy

If this is a simple true value, then the generated subroutine accepts
additional arguments not specified in `params`. By default, extra arguments
cause an exception.

You can also pass a type constraint here, in which case all extra arguments
must be values of the specified type.

## named\_to\_list

If this is true, the generated subroutine will expect a list of key-value
pairs or a hashref and it will return a list containing only values. The
`params` you pass must be a arrayref of key-value pairs. The order of these
pairs determines the order in which values are returned.

You cannot combine `slurpy` with `named_to_list` as there is no way to know
how to order the extra return values.

## return\_object

If this is true, the generated subroutine will return an object instead of a
hashref. You cannot set this option to true if you set either or `slurpy` or
`named_to_list`.

The object's methods correspond to the parameter names passed to the
subroutine. While calling methods on an object is slower than accessing a
hashref, the advantage is that if you typo a parameter name you'll get a
helpful error.

If you have [Class::XSAccessor](https://metacpan.org/pod/Class::XSAccessor) installed then this will be used to create
the class's methods, which makes it fairly fast.

The returned object is in a generated class. Do not rely on this class name
being anything in specific, and don't check this object using `isa`, `DOES`,
or anything similar.

When `return_object` is true, the parameter spec hashref also accepts to the
following additional keys:

- getter

    Use this to set an explicit getter method name for the parameter. By default
    the method name will be the same as the parameter name. Note that if the
    parameter name is not a valid sub name, then you will get an error compiling
    the validation sub unless you specify a getter for the parameter.

- predicate

    Use this to ask for a predicate method to be created for this parameter. The
    predicate method returns true if the parameter was passed and false if it
    wasn't. Note that this is only useful for optional parameters, but you can ask
    for a predicate for any parameter.

# EXPORTS

The exported subs are:

## validation\_for(...)

This returns a subroutine that implements the specific parameter
checking. This subroutine expects to be given the parameters to validate in
`@_`. If all the parameters are valid, it will return the validated
parameters (with defaults as appropriate), either as a list of key-value pairs
or as a list of just values. If any of the parameters are invalid it will
throw an exception.

For validators expected named params, the generated subroutine accepts either
a list of key-value pairs or a single hashref. Otherwise the validator expects
a list of values.

For now, you must shift off the invocant yourself.

This subroutine accepts the following additional parameters:

- name

    If this is given, then the generated subroutine will be named using
    [Sub::Util](https://metacpan.org/pod/Sub::Util). This is strongly recommended as it makes it possible to
    distinguish different check subroutines when profiling or in stack traces.

    This name will also be used in some exception messages, even if [Sub::Util](https://metacpan.org/pod/Sub::Util)
    is not available.

    Note that you must install [Sub::Util](https://metacpan.org/pod/Sub::Util) yourself separately, as it is not
    required by this distribution, in order to avoid requiring a compiler.

- name\_is\_optional

    If this is true, then the name is ignored when `Sub::Util` is not
    installed. If this is false, then passing a name when [Sub::Util](https://metacpan.org/pod/Sub::Util) cannot be
    loaded causes an exception.

    This is useful for CPAN modules where you want to set a name if you can, but
    you do not want to add a prerequisite on [Sub::Util](https://metacpan.org/pod/Sub::Util).

- debug

    Sets the `EVAL_CLOSURE_PRINT_SOURCE` environment variable to true before
    calling `Eval::Closure::eval_closure()`. This causes the source of the
    subroutine to be printed before it's `eval`'d.

## source\_for(...)

This returns a two element list. The first is a string containing the source
code for the generated sub. The second is a hashref of "environment" variables
to be used when generating the subroutine. These are the arguments that are
passed to [Eval::Closure](https://metacpan.org/pod/Eval::Closure).

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Params-ValidationCompiler/issues](https://github.com/houseabsolute/Params-ValidationCompiler/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Params-ValidationCompiler can be found at [https://github.com/houseabsolute/Params-ValidationCompiler](https://github.com/houseabsolute/Params-ValidationCompiler).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Gregory Oschwald <goschwald@maxmind.com>
- Gregory Oschwald <oschwald@gmail.com>
- Tomasz Konojacki <me@xenu.pl>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2018 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
