# NAME

Template::Plugin::Path::Tiny - use Path::Tiny objects from within templates

# VERSION

version v0.1.0

# SYNOPSIS

```
[% USE Path::Tiny %]

The file [% x.basename %] is in [% x.parent %].
```

# DESCRIPTION

This plugin allows you to turn scalars and lists into [Path::Tiny](https://metacpan.org/pod/Path::Tiny)
objects.

# CAVEATS

Besides some simple filename manipulation, this plugin allows you to
perform file operations from within templates. While that may be
useful, it's probably a _bad idea_.  Consider performing file
operations outside of the template and only using this for
manipulating path names instead.

# SEE ALSO

[Template](https://metacpan.org/pod/Template)

[Path::Tiny](https://metacpan.org/pod/Path::Tiny)

# SOURCE

The development version is on github at [https://github.com/robrwo/Template-Plugin-Path-Tiny](https://github.com/robrwo/Template-Plugin-Path-Tiny)
and may be cloned from [git://github.com/robrwo/Template-Plugin-Path-Tiny.git](git://github.com/robrwo/Template-Plugin-Path-Tiny.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Template-Plugin-Path-Tiny/issues](https://github.com/robrwo/Template-Plugin-Path-Tiny/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
