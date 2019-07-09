[![Build Status](https://travis-ci.org/kfly8/p5-Sub-Meta.svg?branch=master)](https://travis-ci.org/kfly8/p5-Sub-Meta) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Sub-Meta/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Sub-Meta?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Sub-Meta.svg)](https://metacpan.org/release/Sub-Meta)
# NAME

Sub::Meta - handle subroutine meta information

# SYNOPSIS

```perl
use Sub::Meta;

sub hello($) :mehtod { }
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

# setter
$meta->set_subname('world');
$meta->subname; # world
$meta->fullname; # main::world

# apply to sub
$meta->apply_prototype('$@');
$meta->prototype; # $@
Sub::Util::prototype($meta->sub); # $@
```

And you can hold meta information of parameter type and return type. See also [Sub::Meta::Parameters](https://metacpan.org/pod/Sub::Meta::Parameters) and [Sub::Meta::Returns](https://metacpan.org/pod/Sub::Meta::Returns).

```perl
$meta->set_parameters( Sub::Meta::Parameters->new(args => [ { type => 'Str' }]) );
$meta->parameters->args; # [ Sub::Meta::Param->new({ type => 'Str' }) ]

$meta->set_returns( Sub::Meta::Returns->new('Str') );
$meta->returns->scalar; # 'Str'
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
Sub::Meta->new(
    fullname    => 'Greeting::hello',
    is_constant => 0,
    prototype   => '$',
    attribute   => ['method'],
    is_method   => 1,
    parameters  => Sub::Meta::Parameters->new(args => [{ type => 'Str' }]),
    returns     => Sub::Meta::Returns->new('Str'),
);
```

## sub

A subroutine reference.

## set\_sub

Setter for subroutine reference.

## subname

A subroutine name, e.g. `hello`

## set\_subname($subname)

Setter for subroutine name.

```perl
$meta->subname; # hello
$meta->set_subname('world');
$meta->subname; # world
Sub::Util::subname($meta->sub); # hello (NOT apply to sub)
```

## apply\_subname($subname)

Sets subroutine name and apply to the subroutine reference.

```perl
$meta->subname; # hello
$meta->apply_subname('world');
$meta->subname; # world
Sub::Util::subname($meta->sub); # world
```

## fullname

A subroutine full name, e.g. `main::hello`

## set\_fullname($fullname)

Setter for subroutine full name.

## stashname

A subroutine stash name, e.g. `main`

## set\_stashname($stashname)

Setter for subroutine stash name.

## subinfo

A subroutine information, e.g. `['main', 'hello']`

## set\_subinfo(\[$stashname, $subname\])

Setter for subroutine information.

## file

A filename where subroutine is defined, e.g. `path/to/main.pl`.

## set\_file($filepath)

Setter for `file`.

## line

A line where the definition of subroutine started, e.g. `5`

## set\_line($line)

Setter for `line`.

## is\_constant

A boolean value indicating whether the subroutine is a constant or not.

## set\_is\_constant($bool)

Setter for `is_constant`.

## prototype

A prototype of subroutine reference, e.g. `$@`

## set\_prototype($prototype)

Setter for `prototype`.

## apply\_prototype($prototype)

Sets subroutine prototype and apply to the subroutine reference.

## attribute

A attribute of subroutine reference, e.g. `undef`, `['method']`

## set\_attribute($attribute)

Setter for `attribute`.

## apply\_attribute(@attribute)

Sets subroutine attributes and apply to the subroutine reference.

## is\_method

A boolean value indicating whether the subroutine is a method or not.

## set\_is\_method($bool)

Setter for `is_method`.

## parameters

Parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub::Meta::Parameters).

## set\_parameters($parameters)

Sets the parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub::Meta::Parameters) or any object which has `positional`,`named`,`required` and `optional` methods.

```perl
my $meta = Sub::Meta->new;
$meta->set_parameters({ type => 'Type'});
$meta->parameters; # => Sub::Meta::Parameters->new({type => 'Type'});

# or
$meta->set_parameters(Sub::Meta::Parameters->new(type => 'Foo'));
$meta->set_parameters(MyParamters->new)
```

## returns

Returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub::Meta::Returns).

## set\_returns($returns)

Sets the returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub::Meta::Returns) or any object.

```perl
my $meta = Sub::Meta->new;
$meta->set_returns({ type => 'Type'});
$meta->returns; # => Sub::Meta::Returns->new({type => 'Type'});

# or
$meta->set_returns(Sub::Meta::Returns->new(type => 'Foo'));
$meta->set_returns(MyReturns->new)
```

## is\_same\_interface($other\_meta)

A boolean value indicating whether the subroutine's interface is same or not.
Specifically, check whether `subname`, `parameters` and `returns` are equal.

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

[Sub::Identify](https://metacpan.org/pod/Sub::Identify), [Sub::Util](https://metacpan.org/pod/Sub::Util), [Sub::Info](https://metacpan.org/pod/Sub::Info), [Function::Paramters::Info](https://metacpan.org/pod/Function::Paramters::Info), [Function::Return::Info](https://metacpan.org/pod/Function::Return::Info)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
