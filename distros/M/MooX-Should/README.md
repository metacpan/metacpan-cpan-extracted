# NAME

MooX::Should - optional type restrictions for Moo attributes

# VERSION

version v0.1.2

# SYNOPSIS

```perl
use Moo;

use MooX::Should;
use Types::Standard -types;

has thing => (
  is     => 'ro',
  should => Int,
);
```

# DESCRIPTION

This module is basically a shortcut for

```perl
use Devel::StrictMode;
use PerlX::Maybe;

has thing => (
        is  => 'ro',
  maybe isa => STRICT ? Int : undef,
);
```

It allows you to completely ignore any type restrictions on [Moo](https://metacpan.org/pod/Moo)
attributes at runtime, or to selectively enable them.

Note that you can specify a (weaker) type restriction for an attribute:

```perl
use Types::Common::Numeric qw/ PositiveInt /;
use Types::Standard qw/ Int /;

has thing => (
  is     => 'ro',
  isa    => Int,
  should => PositiveInt,
);
```

but this is equivalent to

```perl
use Devel::StrictMode;

has thing => (
  is     => 'ro',
  isa    => STRICT ? PositiveInt : Int,
);
```

# SEE ALSO

- [Devel::StrictMode](https://metacpan.org/pod/Devel::StrictMode)
- [PerlX::Maybe](https://metacpan.org/pod/PerlX::Maybe)

# SOURCE

The development version is on github at [https://github.com/robrwo/MooX-Should](https://github.com/robrwo/MooX-Should)
and may be cloned from [git://github.com/robrwo/MooX-Should.git](git://github.com/robrwo/MooX-Should.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/MooX-Should/issues](https://github.com/robrwo/MooX-Should/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
