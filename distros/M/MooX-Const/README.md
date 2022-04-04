# NAME

MooX::Const - Syntactic sugar for constant and write-once Moo attributes

# VERSION

version v0.5.3

# SYNOPSIS

```perl
use Moo;
use MooX::Const;

use Types::Standard -types;

has thing => (
  is  => 'const',
  isa => ArrayRef[HashRef],
);
```

# DESCRIPTION

This is syntactic sugar for using [Types::Const](https://metacpan.org/pod/Types%3A%3AConst) with [Moo](https://metacpan.org/pod/Moo). The
SYNOPSIS above is equivalent to:

```perl
use Types::Const -types;

has thing => (
  is     => 'ro',
  isa    => Const[ArrayRef[HashRef]],
  coerce => 1,
);
```

It modifies the `has` function to support "const" attributes.  These
are read-only ("ro") attributes for references, where the underlying
data structure has been set as read-only.

This will return an error if there is no "isa", the "isa" is not a
[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) type, if it is not a reference, or if it is blessed
object.

Simple value types such as `Int` or `Str` are silently converted to
read-only attributes.

As of v0.5.0, it also supports write-once ("once") attributes for
references:

```perl
has setting => (
  is  => 'once',
  isa => HashRef,
);
```

This allows you to set the attribute _once_. The value is coerced
into a constant, and cannot be changed again.

Note that "wo" is a deprecated synonym for "once". It will be removed
in the future, since "wo" is used for "write-only" in some Moose-like
extensions.

As of v0.4.0, this now supports the `strict` setting:

```perl
has thing => (
  is     => 'const',
  isa    => ArrayRef[HashRef],
  strict => 0,
);
```

When this is set to a false value, then the read-only constraint will
only be applied when running in strict mode, see [Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode).

If omitted, `strict` is assumed to be true.

# KNOWN ISSUES

Accessing non-existent keys for hash references will throw an
error. This is a feature, not a bug, of read-only hash references, and
it can be used to catch mistakes in code that refer to non-existent
keys.

Unfortunately, this behaviour is not replicated with array references.

See [Types::Const](https://metacpan.org/pod/Types%3A%3AConst) for other known issues related to the `Const`
type.

## Using with Moose and Mouse

This module appears to work with [Moose](https://metacpan.org/pod/Moose), and there is now a small
test suite.

It does not work with [Mouse](https://metacpan.org/pod/Mouse). Pull requests are welcome.

## Write-Once Attributes

[Class::Accessor](https://metacpan.org/pod/Class%3A%3AAccessor) antlers/moose-like mode uses "wo" for write-only
attributes, not write-once attributes.

As of v0.5.0, you should be using "once" instead of "wo".

# SEE ALSO

[Const::Fast](https://metacpan.org/pod/Const%3A%3AFast)

[Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode)

[Moo](https://metacpan.org/pod/Moo)

[MooseX::SetOnce](https://metacpan.org/pod/MooseX%3A%3ASetOnce)

[Types::Const](https://metacpan.org/pod/Types%3A%3AConst)

[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)

# SOURCE

The development version is on github at [https://github.com/robrwo/MooX-Const](https://github.com/robrwo/MooX-Const)
and may be cloned from [git://github.com/robrwo/MooX-Const.git](git://github.com/robrwo/MooX-Const.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/MooX-Const/issues](https://github.com/robrwo/MooX-Const/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module was inspired by suggestions from Kang-min Liu 劉康民
<gugod@gugod.org> in a [blog post](http://blogs.perl.org/users/robert_rothenberg/2018/11/typeconst-released.html).

# CONTRIBUTOR

Kang-min Liu 劉康民 <gugod@gugod.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
