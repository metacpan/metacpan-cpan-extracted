package Sah::Schema::perl::sorter::modname;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-23'; # DATE
our $DIST = 'Sah-Schemas-Sorter'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = ['str' => {
    summary => 'Perl Sorter::* module name without the prefix, e.g. foo',
    description => <<'_',

Contains coercion rule so you can also input `Foo-Bar`, `Foo/Bar`, `Foo/Bar.pm`
or even 'Foo.Bar' and it will be normalized into `Foo::Bar`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z',

    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_modname',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.completion' => ['perl_modname', {ns_prefix=>'Sorter'}],

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo/bar', valid=>1, validated_value=>'Foo::bar'},
        {value=>'baz qux', valid=>0},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::sorter::modname

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::sorter::modname (from Perl distribution Sah-Schemas-Sorter), released on 2024-01-23.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Sorter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Sorter>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Sorter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
