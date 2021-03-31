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

A subroutine reference.

### set\_sub

Setter for subroutine reference.

```perl
sub hello { ... }
$meta->set_sub(\&hello);
$meta->sub # => \&hello
```

### subname

A subroutine name, e.g. `hello`

### set\_subname($subname)

Setter for subroutine name.

```perl
$meta->subname; # hello
$meta->set_subname('world');
$meta->subname; # world
Sub::Util::subname($meta->sub); # hello (NOT apply to sub)
```

### apply\_subname($subname)

Sets subroutine name and apply to the subroutine reference.

```perl
$meta->subname; # hello
$meta->apply_subname('world');
$meta->subname; # world
Sub::Util::subname($meta->sub); # world
```

### fullname

A subroutine full name, e.g. `main::hello`

### set\_fullname($fullname)

Setter for subroutine full name.

### stashname

A subroutine stash name, e.g. `main`

### set\_stashname($stashname)

Setter for subroutine stash name.

### subinfo

A subroutine information, e.g. `['main', 'hello']`

### set\_subinfo(\[$stashname, $subname\])

Setter for subroutine information.

### file

A filename where subroutine is defined, e.g. `path/to/main.pl`.

### set\_file($filepath)

Setter for `file`.

### line

A line where the definition of subroutine started, e.g. `5`

### set\_line($line)

Setter for `line`.

### is\_constant

A boolean value indicating whether the subroutine is a constant or not.

### set\_is\_constant($bool)

Setter for `is_constant`.

### prototype

A prototype of subroutine reference, e.g. `$@`

### set\_prototype($prototype)

Setter for `prototype`.

### apply\_prototype($prototype)

Sets subroutine prototype and apply to the subroutine reference.

### attribute

A attribute of subroutine reference, e.g. `undef`, `['method']`

### set\_attribute($attribute)

Setter for `attribute`.

### apply\_attribute(@attribute)

Sets subroutine attributes and apply to the subroutine reference.

### apply\_meta($other\_meta)

Apply subroutine subname, prototype and attributes of `$other_meta`.

### is\_method

A boolean value indicating whether the subroutine is a method or not.

### set\_is\_method($bool)

Setter for `is_method`.

### parameters

Parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AParameters).

### set\_parameters($parameters)

Sets the parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AParameters).

```perl
my $meta = Sub::Meta->new;
$meta->set_parameters(args => ['Str']);
$meta->parameters; # => Sub::Meta::Parameters->new(args => ['Str']);

# or
$meta->set_parameters(Sub::Meta::Parameters->new(args => ['Str']));

# alias
$meta->set_args(['Str']);
```

### args

The alias of `parameters.args`.

### set\_args($args)

The alias of `parameters.set_args`.

### all\_args

The alias of `parameters.all_args`.

### nshift

The alias of `parameters.nshift`.

### set\_nshift($nshift)

The alias of `parameters.set_nshift`.

### invocant

The alias of `parameters.invocant`.

### invocants

The alias of `parameters.invocants`.

### set\_invocant($invocant)

The alias of `parameters.set_invocant`.

### slurpy

The alias of `parameters.slurpy`.

### set\_slurpy($slurpy)

The alias of `parameters.set_slurpy`.

### returns

Returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub%3A%3AMeta%3A%3AReturns).

### set\_returns($returns)

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

### is\_same\_interface($other\_meta)

A boolean value indicating whether the subroutine's interface is same or not.
Specifically, check whether `subname`, `is_method`, `parameters` and `returns` are equal.

### is\_same\_interface\_inlined($other\_meta\_inlined)

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

### display

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

Returns class name of parameters. default: Sub::Meta::Parameters
Please override for customization.

### returns\_class

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

[Sub::Identify](https://metacpan.org/pod/Sub%3A%3AIdentify), [Sub::Util](https://metacpan.org/pod/Sub%3A%3AUtil), [Sub::Info](https://metacpan.org/pod/Sub%3A%3AInfo), [Function::Parameters::Info](https://metacpan.org/pod/Function%3A%3AParameters%3A%3AInfo), [Function::Return::Info](https://metacpan.org/pod/Function%3A%3AReturn%3A%3AInfo)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
