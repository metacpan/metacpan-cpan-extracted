# `Perl::Version::Bumper`

This module helps "bump" the version of the language used in
a piece of Perl code to a more recent version.

The Perl of 2024 (v5.40) is not the Perl of 2002 (v5.8). It's a much
improved language, with many new and useful features for large code
bases. So, why not start using it now?

# `use VERSION`

Why even bother declaring a language version in your code?

You might have heard that Perl has amazing support for backwards
compatibility. You may think it's because the language is stagnating.
It's actually the opposite! It's just that accessing the new features
is a bit more complicated than just using the latest `perl` binary.

From the [feature](https://perldoc.perl.org/feature) module documentation:

> It is usually impossible to add new syntax to Perl without breaking
> some existing programs. This pragma provides a way to minimize that
> risk. New syntactic constructs can be enabled by use feature 'foo',
> and will be parsed only when the appropriate feature pragma is in scope.

Yes, you read that right. Inside your own files, on a file-by-file basis,
you get to decide which version of Perl you get.

Behind its simple looks, `use VERSION` actually enables
Perl's amazing support for backwards compatibility, and also
fuels Perl's ability to continue to bring in new and sometimes
backwards-incompatible features. It does that by loading
"[version bundles](https://perldoc.perl.org/feature#FEATURE-BUNDLES)",
which enable (and sometimes disable) features that were added to the
language over time.

# Not your parents' Perl

When Perl starts, it reads your code from line 0. At line 0, Perl supports
most of the language features of Perl 5.8 (published in 2002). Except
for some hard deprecations (Perl has sometimes moved forward somewhat
abruptly), any sensibly-written code from twenty or more years ago will
just work.

Over time, as new features were added to Perl, the ones that broke
backwards compatibility, or that were a bit too experimental to be made
part of the language proper were put behind feature guards. You have to
opt-in to them. This is what `use VERSION` does: it signals that the code
you wrote was against the given `VERSION` of the language.

If the first line of your code is a `use VERSION` line, you get a more
useful Perl, starting from line 1. That's a pretty good balance of
backwards compatibility versus new features. And you get to upgrade one
file at a time.

Future versions of Perl promise they will support those version bundles
for as long as technically possible. This is why a module that starts
with `use v5.16;` still works fine when run by `perl5.40.0`.

# Bump the Perl version of your code

Now that you're conviced that `use VERSION` is the way to go, you might
want to start using it everywhere.

Picking which version to use is balancing act, with different choices
for different situations. A CPAN author will prefer to support a wider
range of Perl versions and limit themselves to somewhat older versions,
while someone writing code for their company's e-commerce web site
will want to be on the bleeding edge, and take advantage of the latest
improvements to the language.
