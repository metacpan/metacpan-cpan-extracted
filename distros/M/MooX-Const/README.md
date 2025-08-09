# NAME

MooX::Const - Syntactic sugar for constant and write-once Moo(se) attributes

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

This will return an error if there is no "isa", the "isa" is not a code reference (v0.7.0) or a [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) type that
is is not a reference, or a blessed object.

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

Note that "wo" is a removed synonym for "once". It no longer works in
v0.6.0, since "wo" is used for "write-only" in some Moose-like
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

# RECENT CHANGES

Changes for version v0.7.0 (2025-08-09)

- Incompatible Changes
    - Minimum Perl version is v5.20.
- Enhancements
    - The isa option of attributes can be a code reference.
    - Internal code improvements.
- Documentation
    - Clarified the documentation on the isa option of attributes.
    - Fixed cut-and-paste error in CONTRIBUTING.md.
    - Fixed errors in the README.
    - Removed the INSTALL file.
    - Removed redundant section.
- Tests
    - Moved author tests into the xt directory.
    - Added more author tests.
    - Added tests with MooseX::MungeHas.
- Toolchain
    - Improved Dist::Zilla configuration.
    - Stop regenerating MANIFEST.SKIP.
    - Add GitHub workflow to run tests.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode)
- [Moo](https://metacpan.org/pod/Moo) version 1.006000 or later
- [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)
- [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)
- [Types::Const](https://metacpan.org/pod/Types%3A%3AConst) version v0.3.3 or later
- [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [utf8](https://metacpan.org/pod/utf8)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan MooX::Const
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/MooX-Const/issues](https://github.com/robrwo/MooX-Const/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/MooX-Const](https://github.com/robrwo/MooX-Const)
and may be cloned from [git://github.com/robrwo/MooX-Const.git](git://github.com/robrwo/MooX-Const.git)

See `CONTRIBUTING.md` for more information.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module was inspired by suggestions from Kang-min Liu 劉康民
<gugod@gugod.org> in a [blog post](http://blogs.perl.org/users/robert_rothenberg/2018/11/typeconst-released.html).

# CONTRIBUTOR

Kang-min Liu 劉康民 <gugod@gugod.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

<MooX::Readonly::Attribute>, which has similar functionality to this module.

[Const::Fast](https://metacpan.org/pod/Const%3A%3AFast)

[Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode)

[Moo](https://metacpan.org/pod/Moo)

[MooseX::SetOnce](https://metacpan.org/pod/MooseX%3A%3ASetOnce)

[Sub::Trigger::Lock](https://metacpan.org/pod/Sub%3A%3ATrigger%3A%3ALock)

[Types::Const](https://metacpan.org/pod/Types%3A%3AConst)

[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny)
