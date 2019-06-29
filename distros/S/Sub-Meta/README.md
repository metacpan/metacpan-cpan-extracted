[![Build Status](https://travis-ci.org/kfly8/p5-Sub-Meta.svg?branch=master)](https://travis-ci.org/kfly8/p5-Sub-Meta) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Sub-Meta/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Sub-Meta?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Sub-Meta.svg)](https://metacpan.org/release/Sub-Meta)
# NAME

Sub::Meta - handle subroutine meta information

# SYNOPSIS

```perl
use Sub::Meta;

sub hello { }
my $meta = Sub::Meta->new(\&hello);
$meta->subname; # => hello
$meta->apply_subname('world'); # rename subroutine name

# specify parameters types ( without validation )
$meta->set_parameters( Sub::Meta::Parameters->new(args => [ { type => 'Str' }]) );
$meta->parameters->args; # => Sub::Meta::Param->new({ type => 'Str' })

# specify returns types ( without validation )
$meta->set_returns( Sub::Meta::Returns->new('Str') );
$meta->returns->scalar; # => 'Str'
```

# DESCRIPTION

`Sub::Meta` provides methods to handle subroutine meta information. In addition to information that can be obtained from subroutines using module [B](https://metacpan.org/pod/B) etc., subroutines can have meta information such as arguments and return values.

# METHODS

## Constructor

### new

Constructor of `Sub::Meta`.

## Getter

### sub

A subroutine reference

### subname

A subroutine name, e.g. `hello`

### fullname

A subroutine full name, e.g. `main::hello`

### stashname

A subroutine stash name, e.g. `main`

### file

A filename where subroutine is defined, e.g. `path/to/main.pl`.

### line

A line where the definition of subroutine started.

### is\_constant

A boolean value indicating whether the subroutine is a constant or not.

### prototype

A prototype of subroutine reference.

### attribute

A attribute of subroutine reference.

### is\_method

A boolean value indicating whether the subroutine is a method or not.

### parameters

Parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub::Meta::Parameters).

### returns

Returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub::Meta::Returns).

## Setter

You can set meta information of subroutine. `set_xxx` sets `xxx` and does not affect subroutine reference. On the other hands, `apply_xxx` sets `xxx` and apply `xxx` to subroutine reference.

Setter methods of `Sub::Meta` returns meta object. So you can chain setting: 

```perl
$meta->set_subname('foo')
     ->set_stashname('Some')
```

### set\_xxx

#### set\_sub($)

#### set\_subname($)

#### set\_fullname($)

#### set\_stashname($)

#### set\_file($)

#### set\_line($)

#### set\_is\_constant($)

#### set\_prototype($)

#### set\_attribute($)

#### set\_is\_method($)

#### set\_parameters($)

Sets the parameters object of [Sub::Meta::Parameters](https://metacpan.org/pod/Sub::Meta::Parameters) or any object:

```perl
my $meta = Sub::Meta->new;
$meta->set_parameters({ type => 'Type'});
$meta->parameters; # => Sub::Meta::Parameters->new({type => 'Type'});

# or
$meta->set_parameters(Sub::Meta::Parameters->new(type => 'Foo'));
$meta->set_parameters(MyParamters->new)
```

#### set\_returns($)

Sets the returns object of [Sub::Meta::Returns](https://metacpan.org/pod/Sub::Meta::Returns) or any object.

```perl
my $meta = Sub::Meta->new;
$meta->set_returns({ type => 'Type'});
$meta->returns; # => Sub::Meta::Returns->new({type => 'Type'});

# or
$meta->set_returns(Sub::Meta::Returns->new(type => 'Foo'));
$meta->set_returns(MyReturns->new)
```

### apply\_xxx

#### apply\_subname($)

#### apply\_prototype($)

#### apply\_attribute(@)

# NOTE

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
