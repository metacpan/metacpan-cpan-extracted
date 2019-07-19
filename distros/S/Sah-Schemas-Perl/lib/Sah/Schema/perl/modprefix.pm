package Sah::Schema::perl::modprefix;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.020'; # VERSION

our $schema = [str => {
    summary => 'Perl module prefix',
    description => <<'_',

Perl module prefix, e.g. `Foo::Bar::`. An empty prefix ('') is also allowed.

Contains coercion rule so you can also input:

    Foo-Bar
    Foo-Bar-
    Foo-Bar
    Foo/Bar
    Foo/Bar/
    Foo::Bar

and it will be normalized into `Foo::Bar::`.

See also: `perl::modprefix`.

_
    match => '\A(?:[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*::)?\z',

    'x.perl.coerce_rules' => [
        'str_normalize_perl_modprefix',
    ],

    # provide a default completion which is from list of installed perl prefixes
    'x.completion' => 'perl_modprefix',

}, {}];

1;
# ABSTRACT: Perl module prefix

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modprefix - Perl module prefix

=head1 VERSION

This document describes version 0.020 of Sah::Schema::perl::modprefix (from Perl distribution Sah-Schemas-Perl), released on 2019-07-05.

=head1 DESCRIPTION

Perl module prefix, e.g. C<Foo::Bar::>. An empty prefix ('') is also allowed.

Contains coercion rule so you can also input:

 Foo-Bar
 Foo-Bar-
 Foo-Bar
 Foo/Bar
 Foo/Bar/
 Foo::Bar

and it will be normalized into C<Foo::Bar::>.

See also: C<perl::modprefix>.

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
