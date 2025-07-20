# NAME

Software::Policy::CodeOfConduct - generate a Code of Conduct policy

# VERSION

version v0.1.0

# SYNOPSIS

```perl
my $policy = Software::Policy::CodeOfConduct->new(
    name    => 'Foo',
    contact => 'team-foo@example.com',
    policy  => 'Contributor_Covenant_1.4',
);

open my $fh, '>', "CODE-OF-CONDUCT.md" or die $!;
print {$fh} $policy->text;
close $fh;
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

## policy

This is the policy filename. It defaults to `Contributor_Covenant_1.4` which is based on
[https://www.contributor-covenant.org/version/1/4/code-of-conduct.html](https://www.contributor-covenant.org/version/1/4/code-of-conduct.html).

## template\_path

This is the path to the template file. If omitted, it will assume it is an included file from ["policy"](#policy).

This should be a [Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate) file.

## text\_columns

This is the number of text columns for word-wrapping the ["text"](#text).

The default is `78`.

## text

This is the text generated from the template.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Software-Policy-CodeOfConduct](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct)
and may be cloned from [git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git](git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues](https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
