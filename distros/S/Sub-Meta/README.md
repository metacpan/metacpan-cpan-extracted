[![Actions Status](https://github.com/kfly8/p5-Sub-Meta/workflows/test/badge.svg)](https://github.com/kfly8/p5-Sub-Meta/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Sub-Meta/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Sub-Meta?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Sub-Meta.svg)](https://metacpan.org/release/Sub-Meta)
# NAME

Sub::Meta - handle subroutine meta information

# SYNOPSIS

```perl
use Sub::Meta;

sub hello($) :method { }
my $meta = Sub::Meta->new(sub => \&hello);
$meta->subname; # => hello

$meta->sub;        # \&hello
$meta->subname;    # hello
$meta->fullname    # main::hello
$meta->stashname   # main
$meta->file        # path/to/file.pl
$meta->line        # 5
$meta->is_constant # !!0
$meta->prototype   # $
$meta->attribute   # ['method']
$meta->is_method   # undef
$meta->parameters  # undef
$meta->returns     # undef
$meta->display     # 'sub hello'

# setter
$meta->set_subname('world');
$meta->subname; # world
$meta->fullname; # main::world

# apply to sub
$meta->apply_prototype('$@');
$meta->prototype; # $@
Sub::Util::prototype($meta->sub); # $@
```

And you can hold meta information of parameter type and return type. See also [Sub::Meta::Parameters](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AParameters) and [Sub::Meta::Returns](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AReturns).

```perl
$meta->set_parameters(args => ['Str']));
$meta->parameters->args; # [ Sub::Meta::Param->new({ type => 'Str' }) ]

$meta->set_args(['Str']);
$meta->args; # [ Sub::Meta::Param->new({ type => 'Str' }) ]

$meta->set_returns('Str');
$meta->returns->scalar; # 'Str'
$meta->returns->list;   # 'Str'
```

And you can compare meta informations:

```perl
my $other = Sub::Meta->new(subname => 'hello');
$meta->is_same_interface($other); # 1
$meta eq $other; # 1
```

# DESCRIPTION

`Sub::Meta` provides methods to handle subroutine meta information. In addition to information that can be obtained from subroutines using module [B](https://metacpan.org/pod/B) etc., subroutines can have meta information such as arguments and return values.

# METHODS

## new

Constructor of `Sub::Meta`.

```perl
use Sub::Meta;
use Types::Standard -types;

# sub Greeting::hello(Str) -> Str
Sub::Meta->new(
    fullname    => 'Greeting::hello',
    is_constant => 0,
    prototype   => '$',
    attribute   => ['method'],
    is_method   => 1,
    parameters  => { args => [{ type => Str }]},
    returns     => Str,
);
```

Others are as follows:

```perl
# sub add(Int, Int) -> Int
Sub::Meta->new(
    subname => 'add',
    args    => [Int, Int],
    returns => Int,
);

# method hello(Str) -> Str 
Sub::Meta->new(
    subname   => 'hello',
    args      => [{ message => Str }],
    is_method => 1,
    returns   => Str,
);

# sub twice(@numbers) -> ArrayRef[Int]
Sub::Meta->new(
    subname   => 'twice',
    args      => [],
    slurpy    => { name => '@numbers' },
    returns   => ArrayRef[Int],
);

# Named parameters:
# sub foo(Str :a) -> Str
Sub::Meta->new(
    subname   => 'foo',
    args      => { a => Str },
    returns   => Str,
);

# is equivalent to
Sub::Meta->new(
    subname   => 'foo',
    args      => [{ name => 'a', isa => Str, named => 1 }],
    returns   => Str,
);
```

Another way to create a Sub::Meta is to use [Sub::Meta::Creator](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3ACreator):

```perl
use Sub::Meta::Creator;
use Sub::Meta::Finder::FunctionParameters;

my $creator = Sub::Meta::Creator->new(
    finders => [ \&Sub::Meta::Finder::FunctionParameters::find_materials ],
);

use Function::Parameters;
use Types::Standard -types;

method hello(Str $msg) { }
my $meta = $creator->create(\&hello);
# =>
# Sub::Meta
#   args [
#       [0] Sub::Meta::Param->new(name => '$msg', type => Str)
#   ],
#   invocant   Sub::Meta::Param->(name => '$self', invocant => 1),
#   nshift     1,
#   slurpy     !!0
```

## ACCESSORS

### sub

Accessor for subroutine.

- `sub`

    ```perl
    method sub() => Maybe[CodeRef]
    ```

    Return a subroutine.

- `has_sub`

    ```perl
    method has_sub() => Bool
    ```

    Whether Sub::Meta has subroutine or not.

- `set_sub($sub)`

    ```perl
    method set_sub(CodeRef $sub) => $self
    ```

    Setter for subroutine.

    ```perl
    sub hello { ... }
    $meta->set_sub(\&hello);
    $meta->sub # => \&hello

    # And set subname, stashname
    $meta->subname; # hello
    $meta->stashname; # main
    ```

### subname

Accessor for subroutine name

- `subname`

    ```perl
    method subname() => Str
    ```

- `has_subname`

    ```perl
    method has_subname() => Bool
    ```

    Whether Sub::Meta has subroutine name or not.

- `set_subname($subname)`

    ```perl
    method set_subname(Str $subname) => $self
    ```

    Setter for subroutine name.

    ```perl
    $meta->subname; # hello
    $meta->set_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # hello (NOT apply to sub)
    ```

- `apply_subname($subname)`

    ```perl
    method apply_subname(Str $subname) => $self
    ```

    Sets subroutine name and apply to the subroutine reference.

    ```perl
    $meta->subname; # hello
    $meta->apply_subname('world');
    $meta->subname; # world
    Sub::Util::subname($meta->sub); # world
    ```

### fullname

Accessor for subroutine full name

- `fullname`

    ```perl
    method fullname() => Str
    ```

    A subroutine full name, e.g. `main::hello`

- `has_fullname`

    ```perl
    method has_fullname() => Bool
    ```

    Whether Sub::Meta has subroutine full name or not.

- `set_fullname($fullname)`

    ```perl
    method set_fullname(Str $fullname) => $self
    ```

    Setter for subroutine full name.

### stashname

Accessor for subroutine stash name

- `stashname`

    ```perl
    method stashname() => Str
    ```

    A subroutine stash name, e.g. `main`

- `has_stashname`

    ```perl
    method has_stashname() => Bool
    ```

    Whether Sub::Meta has subroutine stash name or not.

- `set_stashname($stashname)`

    ```perl
    method set_stashname(Str $stashname) => $self
    ```

    Setter for subroutine stash name.

### subinfo

Accessor for subroutine information

- `subinfo`

    ```perl
    method subinfo() => Tuple[Str,Str]
    ```

    A subroutine information, e.g. `['main', 'hello']`

- `set_subinfo([$stashname, $subname])`

    ```perl
    method set_stashname(Tuple[Str $stashname, Str $subname]) => $self
    ```

    Setter for subroutine information.

### file, line

Accessor for filename and line where subroutine is defined

- `file`

    ```perl
    method file() => Maybe[Str]
    ```

    A filename where subroutine is defined, e.g. `path/to/main.pl`.

- `has_file`

    ```perl
    method has_file() => Bool
    ```

    Whether Sub::Meta has a filename where subroutine is defined.

- `set_file($filepath)`

    ```perl
    method set_file(Str $filepath) => $self
    ```

    Setter for `file`.

- `line`

    ```perl
    method line() => Maybe[Int]
    ```

    A line where the definition of subroutine started, e.g. `5`

- `has_line`

    ```perl
    method has_line() => Bool
    ```

    Whether Sub::Meta has a line where the definition of subroutine started.

- `set_line($line)`

    ```perl
    method set_line(Int $line) => $self
    ```

    Setter for `line`.

### is\_constant

- `is_constant`

    ```perl
    method is_constant() => Maybe[Bool]
    ```

    If the subroutine is set, it returns whether it is a constant or not, if not set, it returns undef.

- `set_is_constant($bool)`

    ```perl
    method set_is_constant(Bool $bool) => $self
    ```

    Setter for `is_constant`.

### prototype

Accessor for prototype of subroutine reference.

- `prototype`

    ```perl
    method prototype() => Maybe[Str]
    ```

    If the subroutine is set, it returns a prototype of subroutine, if not set, it returns undef.
    e.g. `$@`

- `has_prototype`

    ```perl
    method has_prototype() => Bool
    ```

    Whether Sub::Meta has prototype or not.

- `set_prototype($prototype)`

    ```perl
    method set_prototype(Str $prototype) => $self
    ```

    Setter for `prototype`.

- `apply_prototype($prototype)`

    ```perl
    method apply_prototype(Str $prototype) => $self
    ```

    Sets subroutine prototype and apply to the subroutine reference.

### attribute

Accessor for attribute of subroutine reference.

- `attribute`

    ```perl
    method attribute() => Maybe[ArrayRef[Str]]
    ```

    If the subroutine is set, it returns a attribute of subroutine, if not set, it returns undef.
    e.g. `['method']`, `undef` 

- `has_attribute`

    ```perl
    method has_attribute() => Bool
    ```

    Whether Sub::Meta has attribute or not.

- `set_attribute($attribute)`

    ```perl
    method set_attribute(ArrayRef[Str] $attribute) => $self
    ```

    Setter for `attribute`.

- `apply_attribute(@attribute)`

    ```perl
    method apply_attribute(Str @attribute) => $self
    ```

    Sets subroutine attributes and apply to the subroutine reference.

### is\_method

- `is_method`

    ```perl
    method is_method() => Bool
    ```

    Whether the subroutine is a method or not.

- `set_is_method($bool)`

    ```perl
    method set_is_method(Bool $bool) => Bool
    ```

    Setter for `is_method`.

### parameters

Accessor for parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AParameters)

- `parameters`

    ```perl
    method parameters() => Maybe[InstanceOf[Sub::Meta]]
    ```

    If the parameters is set, it returns the parameters object.

- `has_parameters`

    ```perl
    method has_parameters() => Bool
    ```

    Whether Sub::Meta has parameters or not.

- `set_parameters($parameters)`

    ```perl
    method set_parameters(InstanceOf[Sub::Meta::Parameters] $parameters) => $self
    method set_parameters(@sub_meta_parameters_args) => $self
    ```

    Sets the parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AParameters).

    ```perl
    my $meta = Sub::Meta->new;

    my $parameters = Sub::Meta::Parameters->new(args => ['Str']);
    $meta->set_parameters($parameters);

    # or
    $meta->set_parameters(args => ['Str']);
    $meta->parameters; # => Sub::Meta::Parameters->new(args => ['Str']);

    # alias
    $meta->set_args(['Str']);
    ```

- `args`

    The alias of `parameters.args`.

- `set_args($args)`

    The alias of `parameters.set_args`.

- `all_args`

    The alias of `parameters.all_args`.

- `nshift`

    The alias of `parameters.nshift`.

- `set_nshift($nshift)`

    The alias of `parameters.set_nshift`.

- `invocant`

    The alias of `parameters.invocant`.

- `invocants`

    The alias of `parameters.invocants`.

- `set_invocant($invocant)`

    The alias of `parameters.set_invocant`.

- `slurpy`

    The alias of `parameters.slurpy`.

- `set_slurpy($slurpy)`

    The alias of `parameters.set_slurpy`.

### returns

Accessor for returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AReturns)

- `returns`

    ```perl
    method returns() => Maybe[InstanceOf[Sub::Meta]]
    ```

    If the returns is set, it returns the returns object.

- `has_returns`

    ```perl
    method has_returns() => Bool
    ```

    Whether Sub::Meta has returns or not.

- `set_returns($returns)`

    ```perl
    method set_returns(InstanceOf[Sub::Meta::Returns] $returns) => $self
    method set_returns(@sub_meta_returns_args) => $self
    ```

    Sets the returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AReturns) or any object.

    ```perl
    my $meta = Sub::Meta->new;
    $meta->set_returns({ type => 'Type'});
    $meta->returns; # => Sub::Meta::Returns->new({type => 'Type'});

    # or
    $meta->set_returns(Sub::Meta::Returns->new(type => 'Foo'));
    $meta->set_returns(MyReturns->new)
    ```

## METHODS

### apply\_meta($other\_meta)

```perl
method apply_meta(InstanceOf[Sub::Meta] $other_meta) => $self
```

Apply subroutine subname, prototype and attributes of `$other_meta`.

### is\_same\_interface($other\_meta)

```perl
method is_same_interface(InstanceOf[Sub::Meta] $other_meta) => Bool
```

A boolean value indicating whether the subroutine's interface is same or not.
Specifically, check whether `subname`, `is_method`, `parameters` and `returns` are equal.

### is\_relaxed\_same\_interface($other\_meta)

```perl
method is_relaxed_same_interface(InstanceOf[Sub::Meta] $other_meta) => Bool
```

A boolean value indicating whether the subroutine's interface is relaxed same or not.
Specifically, check whether `subname`, `is_method`, `parameters` and `returns` satisfy
the condition of `$self` side:

```perl
my $meta = Sub::Meta->new;
my $other = Sub::Meta->new(subname => 'foo');
$meta->is_same_interface($other); # NG
$meta->is_relaxed_same_interface($other); # OK. The reason is that $meta does not specify the subname.
```

### is\_same\_interface\_inlined($other\_meta\_inlined)

```perl
method is_same_interface_inlined(InstanceOf[Sub::Meta] $other_meta) => Str
```

Returns inlined `is_same_interface` string:

```perl
use Sub::Meta;
my $meta = Sub::Meta->new(subname => 'hello');
my $inline = $meta->is_same_interface_inlined('$_[0]');
# $inline looks like this:
#    Scalar::Util::blessed($_[0]) && $_[0]->isa('Sub::Meta')
#    && defined $_[0]->subname && 'hello' eq $_[0]->subname
#    && !$_[0]->is_method
#    && !$_[0]->parameters
#    && !$_[0]->returns
my $check = eval "sub { $inline }";
$check->(Sub::Meta->new(subname => 'hello')); # => OK
$check->(Sub::Meta->new(subname => 'world')); # => NG
```

### is\_relaxed\_same\_interface\_inlined($other\_meta\_inlined)

```perl
method is_relaxed_same_interface_inlined(InstanceOf[Sub::Meta] $other_meta) => Str
```

Returns inlined `is_relaxed_same_interface` string.

### error\_message($other\_meta)

```perl
method error_message(InstanceOf[Sub::Meta] $other_meta) => Str
```

Return the error message when the interface is not same. If same, then return empty string

### relaxed\_error\_message($other\_meta)

```perl
method relaxed_error_message(InstanceOf[Sub::Meta] $other_meta) => Str
```

Return the error message when the interface does not satisfy the `$self` meta. If match, then return empty string.

### display

```perl
method display() => Str
```

Returns the display of Sub::Meta:

```perl
use Sub::Meta;
use Types::Standard qw(Str);
my $meta = Sub::Meta->new(
    subname => 'hello',
    is_method => 1,
    args => [Str],
    returns => Str,
);
$meta->display;  # 'method hello(Str) => Str'
```

## OTHERS

### parameters\_class

```perl
method parameters_class() => Str
```

Returns class name of parameters. default: Sub::Meta::Parameters
Please override for customization.

### returns\_class

```perl
method returns_class() => Str
```

Returns class name of returns. default: Sub::Meta::Returns
Please override for customization.

# NOTE

## setter

You can set meta information of subroutine. `set_xxx` sets `xxx` and does not affect subroutine reference. On the other hands, `apply_xxx` sets `xxx` and apply `xxx` to subroutine reference.

Setter methods of `Sub::Meta` returns meta object. So you can chain setting:

```perl
$meta->set_subname('foo')
     ->set_stashname('Some')
```

## Pure-Perl version

By default `Sub::Meta` tries to load an XS implementation for speed.
If that fails, or if the environment variable `PERL_SUB_META_PP` is defined to a true value, it will fall back to a pure perl implementation.

# SEE ALSO

[Sub::Identify](https://metacpan.org/pod/Sub%3A%3AIdentify), [Sub::Util](https://metacpan.org/pod/Sub%3A%3AUtil), [Sub::Info](https://metacpan.org/pod/Sub%3A%3AInfo)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
