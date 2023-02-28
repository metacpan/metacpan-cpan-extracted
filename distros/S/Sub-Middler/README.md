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
    my ($next,$index)=@_;
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
    my ($next, $index)=@_;
    sub {
      my $work= $_[0]*$options{y};
      $next->( $work);
    }
  }
}
```

# DESCRIPTION

A small module, facilitating linking together subroutines, acting as middleware
or filters into chains for flexible usage and low overhead runtime performance.

To achieve these desirable attributes, the  'complexity' is offloaded in the
definition of middleware/filters. They have to be wrapped in subroutines
appropriately to facilitate the lexical binding. 

This differs from other 'sub chaining' modules as it does not use a loop
internally to iterate of over a list of subroutines at runtime. As such there
is no implicit call to the next item in the chain, each stage can run
synchronously or asynchronously or even not at all. Each element in the chain
is responsible for calling the next.

Finally the arguments and signatures used to each stage of middleware are
completely user defined. This allows reuse of the `@_` array in calling
subsequent segments for ultimate performance if you know what you're doing.

# API

## Managing a chain

### new

```perl
my $object=Sub::Middler->new;
```

Creates a empty middler object ready to accept middleware. The object is a
blessed array reference which stores the middlewares directly.

### register

```perl
$object->register(my_middlware());
```

Appends the middleware to the internal list for later linking.

### link

```
$object->link($last);
```

Links together the registered middleware stored internally. Each middleware is
intrinsically linked to the next middlware in the list. The last middleware
being linked to the `$last` argument, which must be a code ref. 

The `$last` code ref does not have to be strictly be middleware.

Calls `die` if `$last` is not a code ref.

## Creating Middleware

To achieve low over head in linking middleware, functional programming
techniques (higher order functions). This also give the greatest flexibility to
the middleware, as signatures are completely user defined.

The trade off is that the middleware must be defined in a certain code
structure. While this isn't difficult, it takes a minute to wrap your head
around.

### Middlware definition

Middleware must be a subroutine (top/name) which returns a anonymous subroutine
(maker), which also returns a anonymous subroutine to perform work (kernel).

This sounds complicated by this is what is looks like in code:

```perl
sub my_middleware {                 (1) Top/name subroutine
  my %options=@_;                       Store any config
 
  sub {                             (2) maker sub is returned
    my ($next, $index)=@_;          (3) Must stor these vars

    sub {                           (4) Returns the kernel sub
      # Code here implements your middleware
      # %options are lexically accessable here
      

      # Execute the next item in the chain
      $next->(...);                 (5) Does work and calls the next entry


                                    (6) Post work if applicable 
    }
  }
}
```

- Top Subroutine

    The top sub routine (1) can take any arguments you desire and can be called what
    you like. The idea is it represents your middleware/filter and stores any setup
    lexically for the **maker** sub to close over. It returns the **maker** sub.

- Maker Subroutine

    This anonymous sub (2) closes over the variables stored in **Top** and is the
    input in to this module (via `register`). When being linked (called) by this
    modules it is provided two arguments, which is the reference to the next item
    in the chain and the current middleware index. These **MUST** be stored to be
    useful, but can be called anything you like (3).

- Kernel subroutine

    This anonymous subroutine (4) actually performs the work of the
    middleware/filter. After work is done, the next item in the chain is called
    explictly (5).  Any extra work can be performed after the chain is completed
    after this call (6).

## LINKING CHAINS

Multiple chains of middleware can be linked together. This needs to be done in
reverse order. The last segment becomes the `$last` item when linking the
preceding chain and so on.

## EXAMPLES

The synopsis example can be found in the examples directory of this
distribution.

# SEE ALSO

[Sub::Chain](https://metacpan.org/pod/Sub%3A%3AChain)  and [Sub::Pipeline](https://metacpan.org/pod/Sub%3A%3APipeline) links together subs. They provide other
features that this module does not. 

These iterate over a list of subroutines, at runtime to achieve named subs etc.
This modules pre links subroutines together, reducing over head

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# REPOSITORTY and BUGS

Please report any bugs via git hub: [http://github.com/drclaw1394/perl-sub-middler](http://github.com/drclaw1394/perl-sub-middler)

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
