[![Build Status](https://travis-ci.org/akiym/Smart-Args-TypeTiny.svg?branch=master)](https://travis-ci.org/akiym/Smart-Args-TypeTiny)
# NAME

Smart::Args::TypeTiny - We are smart, smart for you

# SYNOPSIS

    use Smart::Args::TypeTiny;

    sub func2 {
        args my $p => 'Int',
             my $q => {isa => 'Int', optional => 1},
             ;
    }
    func2(p => 3, q => 4); # p => 3, q => 4
    func2(p => 3);         # p => 3, q => undef

    sub func3 {
        args my $p => {isa => 'Int', default => 3};
    }
    func3(p => 4); # p => 4
    func3();       # p => 3

    package F;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub method {
        args my $self,
             my $p => Int,
             ;
    }
    sub class_method {
        args my $class => ClassName,
             my $p     => Int,
             ;
    }

    sub simple_method {
        args_pos my $self, my $p;
    }

    my $f = F->new();
    $f->method(p => 3);

    F->class_method(p => 3);

    F->simple_method(3);

# DESCRIPTION

Smart::Args::TypeTiny provides [Smart::Args](https://metacpan.org/pod/Smart%3A%3AArgs)-like argument validator using [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny).

## IMCOMPATIBLE CHANGES WITH Smart::Args

- Unexpected parameters will be a fatal error

        sub foo {
            args my $x => 'Str';
        }

        sub bar {
            args_pos my $x => 'Str';
        }

        foo(x => 'a', y => 'b'); # fatal: Unexpected parameter 'y' passed
        bar('a', 'b');           # fatal: Too many parameters passed

- Optional allows to pass undef to parameter

        sub foo {
            args my $p => {isa => 'Int', optional => 1};
        }

        foo();           # $p = undef
        foo(p => 1);     # $p = 1
        foo(p => undef); # $p = undef

- Default parameter can take coderef as lazy value

        sub foo {
            args my $p => {isa => 'Foo', default => create_foo},         # calls every time even if $p is passed
                 my $q => {isa => 'Foo', default => sub { create_foo }}, # calls only when $p is not passed
                 ;
        }

# FUNCTIONS

- my $args = args my $var\[, $rule\], ...;

        sub foo {
            args my $int   => 'Int',
                 my $foo   => 'Foo',
                 my $bar   => {isa => 'Bar',  default  => sub { Bar->new }},
                 my $baz   => {isa => 'Baz',  optional => 1},
                 my $bool  => {isa => 'Bool', default  => 0},
                 ;

            ...
        }

        foo(int => 1, foo => Foo->new, bool => 1);

    Check parameters and fills them into lexical variables. All the parameters are mandatory by default.
    The hashref of all parameters is returned.

    `$rule` can be any one of type name, [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)'s type constraint object, or hashref have these parameters:

    - isa `Str|Object`

        Type name or [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)'s type constraint.

        - Types::Standard

                args my $int => {isa => 'Int'};

        - Mouse::Util::TypeConstraints

            Enable if Mouse.pm is loaded.

                use Mouse::Util::TypeConstraints;

                subtype 'PositiveInt',
                    as 'Int',
                    where { $_ > 0 },
                    message { 'Must be greater than zero' };

                args my $positive_int => {isa => 'PositiveInt'};

        - class name

                {
                    package Foo;
                    ...
                }

                args my $foo => {isa => 'Foo'};

    - does `Str|Object`

        Role name or [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)'s type constraint object.

    - optional `Bool`

        The parameter doesn't need to be passed when [optional](https://metacpan.org/pod/optional) is true.

    - default `Any|CodeRef`

        Default value for the parameter.

- my $args = args\_pos my $var\[, $rule\], ...;

        sub bar {
            args_pos my $x => 'Str',
                     my $p => 'Int',
                     ;

            ...
        }

        bar('abc', 123);

    Same as `args` except take arguments instead of parameters.

# TIPS

## SKIP TYPE CHECK

For optimization calling subroutine in runtime type check, you can overwrite `check_rule` like following code:

    {
        no warnings 'redefine';
        *Smart::Args::TypeTiny::check_rule = \&Smart::Args::TypeTiny::Check::no_check_rule;
    }

`Smart::Args::TypeTiny::Check::no_check_rule` is a function without type checking and type coerce, but settings such as default and optional work the same as `check_rule`.

# SEE ALSO

[Smart::Args](https://metacpan.org/pod/Smart%3A%3AArgs), [Data::Validator](https://metacpan.org/pod/Data%3A%3AValidator), [Params::Validate](https://metacpan.org/pod/Params%3A%3AValidate), [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler)

[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard), [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse%3A%3AUtil%3A%3ATypeConstraints)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
