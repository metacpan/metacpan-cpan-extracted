# NAME

Software::Policy::CodeOfConduct - generate a Code of Conduct policy

# VERSION

version v0.3.0

# SYNOPSIS

```perl
my $policy = Software::Policy::CodeOfConduct->new(
    name     => 'Foo',
    contact  => 'team-foo@example.com',
    policy   => 'Contributor_Covenant_1.4',
    filename => 'CODE-OF-CONDUCT.md',
);

$policy->save($dir); # create CODE-OF-CONDUCT.md in $dir
```

# DESCRIPTION

This distribution generates code of conduct policies from a template.

# ATTRIBUTES

## name

This is the (optional) name of the project that the code of conduct is for,

## has\_name

True if there is a name.

## contact

The is the contact for the project team about the code of conduct. It should be an email address or a URL.

It is required.

## entity

A generating name for the project. It defaults to "project" but the original templates used "community".

## Entity

A sentence-case (ucfirst) form of ["entity"](#entity).

## policy

This is the policy filename. It defaults to "Contributor\_Covenant\_1.4" which is based on
[https://www.contributor-covenant.org/version/1/4/code-of-conduct.html](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html).

Available policies include

- "Contributor\_Covenant\_1.4"
- "Contributor\_Covenant\_2.0"
- "Contributor\_Covenant\_2.1"

## template\_path

This is the path to the template file. If omitted, it will assume it is an included file from ["policy"](#policy).

This should be a [Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate) file.

## text\_columns

This is the number of text columns for word-wrapping the ["text"](#text).

The default is `78`.

## text

This is the text generated from the template.

## filename

This is the file to be generated.

This defaults to `CODE_OF_CONDUCT.md`.

# METHODS

## save

```perl
my $path = $policy->save( $dir );
```

This saves a file named ["filename"](#filename) in directory `$dir`.

If `$dir` is omitted, then it will save the file in the current directory.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Software-Policy-CodeOfConduct](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct)
and may be cloned from [git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git](git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git)

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
