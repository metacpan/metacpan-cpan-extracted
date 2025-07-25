# NAME

Software::Policy::CodeOfConduct - generate a Code of Conduct policy

# VERSION

version v0.5.0

# SYNOPSIS

```perl
my $policy = Software::Policy::CodeOfConduct->new(
    policy   => 'Contributor_Covenant_1.4',
    name     => 'Foo',
    contact  => 'team-foo@example.com',
    filename => 'CODE_OF_CONDUCT.md',
);

$policy->save($dir); # create CODE-OF-CONDUCT.md in $dir
```

# DESCRIPTION

This distribution generates code of conduct policies from a template.

# ATTRIBUTES

## policy

This is the policy filename without the extension. It defaults to "Contributor\_Covenant\_1.4"
.

Available policies include

- [Contributor\_Covenant\_1.4](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html)
- [Contributor\_Covenant\_2.0](https://www.contributor-covenant.org/version/2/0/code-of-conduct.html)
- [Contributor\_Covenant\_2.1](https://www.contributor-covenant.org/version/2/1/code-of-conduct.html)

If you want to use a custom policy, specify the ["template\_path"](#template_path).

## name

This is the (optional) name of the project that the code of conduct is for,

## contact

The is the contact for the project team about the code of conduct. It should be an email address or a URL.

It is required.

## entity

A generating name for the project. It defaults to "project" but the original templates used "community".

## Entity

A sentence-case (ucfirst) form of ["entity"](#entity).

## template\_path

This is the path to the template file. If omitted, it will assume it is an included file from ["policy"](#policy).

This should be a [Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate) template file.

## text\_columns

This is the number of text columns for word-wrapping the ["text"](#text).

A value of `0` disables word wrapping.

The default is `78`.

## filename

This is the file to be generated.

This defaults to `CODE_OF_CONDUCT.md`.

# METHODS

## fulltext

This is the text generated from the template.

## text

This is a deprecated alias for ["fulltext"](#fulltext).

## save

```perl
my $path = $policy->save( $dir );
```

This saves a file named ["filename"](#filename) in directory `$dir`.

If `$dir` is omitted, then it will save the file in the current directory.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Software-Policy-CodeOfConduct](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct)
and may be cloned from [git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git](git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Leon Timmermans <leont@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
