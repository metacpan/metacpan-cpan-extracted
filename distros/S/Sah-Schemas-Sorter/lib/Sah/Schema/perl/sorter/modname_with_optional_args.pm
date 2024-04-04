package Sah::Schema::perl::sorter::modname_with_optional_args;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-23'; # DATE
our $DIST = 'Sah-Schemas-Sorter'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => 'Perl Sorter::* module name without the prefix (e.g. Foo::bar) with optional arguments (e.g. Foo::baz,qux,quux)',
    description => <<'_',

Perl Sorter::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the `-MMODULE=ARGS` shortcut that
`perl` provides. Examples:

    Foo::bar
    Foo::baz=qux,quux
    Foo::baz,qux,quux

See also: `perl::sorter::modname`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\z',

    'prefilters' => [
        'Perl::normalize_perl_modname',
    ],

    # XXX also provide completion for arguments
    'x.completion' => ['perl_sorter_modname_with_optional_args'],

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo/Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar=a,1,b,2', valid=>1, validated_value=>'Foo::Bar=a,1,b,2'},
        {value=>'Foo bar', valid=>0},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::sorter::modname_with_optional_args

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::sorter::modname_with_optional_args (from Perl distribution Sah-Schemas-Sorter), released on 2024-01-23.

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
