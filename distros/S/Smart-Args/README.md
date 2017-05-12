# NAME

Smart::Args - argument validation for you

# SYNOPSIS

    use Smart::Args;

    sub func2 {
      args my $p => 'Int',
           my $q => { isa => 'Int', optional => 1 };
    }
    func2(p => 3, q => 4); # p => 3, q => 4
    func2(p => 3);         # p => 3, q => undef

    sub func3 {
      args my $p => {isa => 'Int', default => 3},
    }
    func3(p => 4); # p => 4
    func3();       # p => 3

    package F;
    use Moose;
    use Smart::Args;

    sub method {
      args my $self,
           my $p => 'Int';
    }
    sub class_method {
      args my $class => 'ClassName',
           my $p => 'Int';
    }

    sub simple_method {
      args_pos my $self, my $p;
    }

    my $f = F->new();
    $f->method(p => 3);

    F->class_method(p => 3);

    F->simple_method(3);

# DESCRIPTION

Smart::Args is yet another argument validation library.

This module makes your module more readable, and writable =)

# FUNCTIONS

## `args my $var [, $rule], ...`

Checks parameters and fills them into lexical variables. All the parameters
are mandatory by default, and unknown parameters (i.e. possibly typos) are
reported as `void` warnings.

The arguments of `args()` consist of lexical &lt;$var>s and optional _$rule_s.

_$vars_ must be a declaration of a lexical variable.

_$rule_ can be a type name (e.g. `Int`), a HASH reference (with
`type`, `default`, and `optional`), or a type constraint object.

Note that if the first variable is named _$class_ or _$self_, it
is dealt as a method call.

See the SYNOPSIS section for examples.

## `args_pos my $var[, $rule, ...`

Check parameters and fills them into lexical variables. All the parameters
are mandatory by default.

The arguments of `args()` consist of lexical &lt;$var>s and optional _$rule_s.
_$vars_ must be a declaration of a lexical variable.

_$rule_ can be a type name (e.g. `Int`), a HASH reference (with
`type`, `default`, and `optional`), or a type constraint object.

Note that if the first variable is named _$class_ or _$self_, it
is dealt as a method call.

See the SYNOPSIS section for examples.

# TYPES

The types that `Smart::Args` uses are type constraints of `Mouse`.
That is, you can define your types in the way Mouse does.

In addition, `Smart::Args` also allows Moose type constraint objects,
so you can use any `MooseX::Types::*` libraries on CPAN.

Type coercions are automatically tried if validations fail.

See [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints) for details.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

[Params::Validate](https://metacpan.org/pod/Params::Validate)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
