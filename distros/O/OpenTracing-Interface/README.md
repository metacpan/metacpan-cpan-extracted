## COPYRIGHT NOTICE

'OpenTracing API for Perl' is Copyright (C) 2019, Perceptyx Inc, Theo van Hoesel

# OpenTracing API for Perl

This package describes the OpenTracing API for Perl

## Required Reading

In order to understand the Perl platform API, one must first be familiar with
[the OpenTracing project](http://opentracing.io/)
and
[terminology](http://opentracing.io/documentation/pages/spec)
more generally.

## Usage

### Singleton initialization

The simplest starting point is to set the global tracer. As early as possible,
do:

```perl
use OpenTracing;

OpenTracing->set_global_tracer( SomeTracerImplementation->new( ... ) );
```
## About

The interfaces being defined as roles
( using [Role::Tiny](https://metacpan.org/pod/Role::Tiny) )
and use `around` method modifiers, instead of `require`, we do want to wrap the
method in type checking
( using [Type::Tiny](https://metacpan.org/pod/Type::Tiny) and friends ).


## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

