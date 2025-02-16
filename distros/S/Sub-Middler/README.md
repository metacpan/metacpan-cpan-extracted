# NAME

Sub::Middler - Middleware subroutine chaining

# SYNOPSIS

```perl
use strict;
use warnings;
use Sub::Middler;

my $middler=Sub::Middler->new;

$middler->register(mw1(x=>1));
$middler->register(mw2(y=>10));

my $head=$middler->link(
  sub {
    print "Result: $_[0]\n";
  }
);

$head->(0); # Call the Chain

# Middleware 1
sub mw1 {
  my %options=@_;
  sub {
    my ($next, $index, @optional)=@_;
    sub {
      my $work=$_[0]+$options{x};
      $next->($work);
    }
  }
}

# Middleware 2
sub mw2 {
  my %options=@_;
  sub {
    my ($next, $index, @optional)=@_;
    sub {
      my $work= $_[0]*$options{y};
      $next->( $work);
    }
  }
}
```

# DESCRIPTION

A small module, facilitating linking subroutines together, acting as middleware
,filters or chains with low runtime overhead.

To achieve this, the  'complexity' is offloaded to the definition of
middleware/filters subroutines. They must be wrapped in subroutines
appropriately to facilitate the lexical binding of linking variables.

This differs from other 'sub chaining' modules as it does not use a loop
internally to iterate over a list of subroutines at runtime. As such there is
no implicit synchronous call to the 'next' item in the chain. Each stage can run
the following stage synchronously or asynchronously or not at all. Each element
in the chain is responsible for how and when it calls the 'next'.

Finally the arguments and signatures of each stage of middleware are completely
user defined and are not interfered with by this module. This allows reuse of
the `@_` array in calling subsequent stages for ultimate performance if you
know what you're doing.

As a general guide it's suggested the last argument to a stage be a subroutine
reference to allow callbacks and asynchronous usage. Instead of a flat list of
multiple inputs into a stage, it is suggested to also contain these in a array

# API

## Inline linking

```
linker mw1, ..., dispatch
```

From v0.3.0, the `linker` subroutine is exported and will do an inline build
and link for a given middlewares and dispatch routine

The return value is the head of the linked chain, and is equivalent to created
a `Sub::Middler` object, adding middleware, and the calling the link method.

## Managing a chain

### new

```perl
my $object=Sub::Middler->new;
```

Creates a empty middler object ready to accept middleware. The object is a
blessed array reference which stores the middleware directly.

### register

```perl
$object->register(my_middlware());
```

Appends the middleware to the internal list for later linking.

### append, add

Alias for register

### link

```
$object->link($last,[@args]);
```

Links together the registered middleware in the sequence of addition. Each
middleware is intrinsically linked to the next middleware in the list. The last
middleware being linked to the `$last` argument, which must be a code ref. 

The `$last` ref MUST be  a regular subroutine reference, acting as the
'kernel' as described in following sections.

Calls `die` if `$last` is not a code ref.

Any optional additional arguments `@args` are passed to this function are
passed on to each 'maker' sub after the `$next` and `$index`, parameters.
This gives an alternative approach to distributing configuration data to each
item in the chain prior to runtime. It is up to each item's maker sub to store
relevant passed values as they see fit.

## Creating Middleware

To achieve low over head in linking middleware, functional programming
techniques (higher order functions) are utilised. This also give the greatest
flexibility to the middleware, as signatures are completely user defined.

The trade off is that the middleware must be defined in a certain code
structure. While this isn't difficult, it takes a minute to wrap your head
around.

### Middlware Definition

Middleware must be a subroutine (top/name) which returns a anonymous subroutine
(maker), which also returns a anonymous subroutine to perform work (kernel).

This sounds complicated by this is what is looks like in code:

```perl
sub my_middleware {                 (1) Top/name subroutine
  my %options=@_;                       Store any config
 
  sub {                             (2) maker sub is returned
    my ($next, $index, @optional)=@_;   (3) Must store at least $next

    sub {                           (4) Returns the kernel sub
      # Code here implements your middleware
      # %options are lexically accessable here
      # as are the @optional parameters
      

      # Execute the next item in the chain
      $next->(...);                 (5) Does work and calls the next entry


                                    (6) Post work if applicable 
    }
  }
}
```

- Top Subroutine

    The top sub routine (1) can take any arguments you desire and can be called
    what you like. The idea is it represents your middleware/filter and stores any
    setup lexically for the **maker** sub to close over. It returns the **maker**
    sub.

- Maker Subroutine

    This anonymous sub (2) closes over the variables stored in **Top** and is the
    input to this module (via `register`). When being linked (called) by this
    module it is provided at least two arguments: the reference to the next item in
    the chain and the current middleware index. These **MUST** be stored to be
    useful, but can be called anything you like (3).

    Any optional/additional arguments supplied during a call to `link` are also
    used as arguments 'as is' to all maker subroutines in the chain.

- Kernel subroutine

    This anonymous subroutine (4) actually performs the work of the
    middleware/filter. After work is done, the next item in the chain must be
    called explicitly (5).  This supports synchronous or asynchronous middleware.
    Any extra work can be performed after the chain is completed after this call
    (6).

## LINKING CHAINS

Multiple chains of middleware can be linked together. This needs to be done in
reverse order. The last chain after being linked, becomes the `$last` item
when linking the preceding chain and so on.

## EXAMPLES

The synopsis example can be found in the examples directory of this
distribution.

# SEE ALSO

[Sub::Chain](https://metacpan.org/pod/Sub%3A%3AChain)  and [Sub::Pipeline](https://metacpan.org/pod/Sub%3A%3APipeline) links together subs. They provide other
features that this module does not. 

These iterate over a list of subroutines at runtime to achieve named subs etc.
where as this module pre links subroutines together, reducing overhead.

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# REPOSITORTY and BUGS

Please report any bugs via git hub: [https://github.com/drclaw1394/perl-sub-middler](https://github.com/drclaw1394/perl-sub-middler)

# COPYRIGHT AND LICENSE

Copyright (C) 2025 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
