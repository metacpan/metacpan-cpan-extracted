package Sah::Schema::perl::modprefixes;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.023'; # VERSION

our $schema = [array => {
    summary => 'Perl module prefixes',
    description => <<'_',

Array of Perl module prefixes, where each element is of `perl::modprefix`
schema, e.g. `Foo::`, `Foo::Bar::`.

Contains coercion rule that expands wildcard, so you can specify:

    Module::C*

and it will be expanded to e.g.:

    ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

The wildcard syntax supports jokers (`?`, '*`) and brackets (`[abc]`). See the
`unix` type of wildcard in <pm:Regexp::Wildcards>, which this coercion rule
uses.

_
    of => ["perl::modprefix", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        'str_or_array_expand_perl_modprefix_wildcard',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => 'perl_modprefix',

}, {}];

1;
# ABSTRACT: Perl module prefixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modprefixes - Perl module prefixes

=head1 VERSION

This document describes version 0.023 of Sah::Schema::perl::modprefixes (from Perl distribution Sah-Schemas-Perl), released on 2019-07-26.

=head1 DESCRIPTION

Array of Perl module prefixes, where each element is of C<perl::modprefix>
schema, e.g. C<Foo::>, C<Foo::Bar::>.

Contains coercion rule that expands wildcard, so you can specify:

 Module::C*

and it will be expanded to e.g.:

 ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

The wildcard syntax supports jokers (C<?>, '*C<) and brackets (>[abc]C<). See the
>unix` type of wildcard in L<Regexp::Wildcards>, which this coercion rule
uses.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
