package Sah::Schema::perl::unqualified_funcname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-15'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.027'; # VERSION

our $schema = [str => {
    summary => 'Perl function name, must not be qualified with a package name',
    description => <<'_',

Currently function name is restricted to this regex:

    \A[A-Za-z_][A-Za-z_0-9]*\z

This schema includes syntax validity check only; it does not check whether the
function actually exists.

This schema includes syntax validity check only; it does not check whether the
function actually exists.

_
    match => '\A[A-Za-z_]([A-Za-z_0-9]+)*\z',

    # TODO: provide convenience by providing list of core function names etc
    #'x.completion' => 'perl_funcname',

}, {}];

1;
# ABSTRACT: Perl function name, must not be qualified with a package name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::unqualified_funcname - Perl function name, must not be qualified with a package name

=head1 VERSION

This document describes version 0.027 of Sah::Schema::perl::unqualified_funcname (from Perl distribution Sah-Schemas-Perl), released on 2020-02-15.

=head1 DESCRIPTION

Currently function name is restricted to this regex:

 \A[A-Za-z_][A-Za-z_0-9]*\z

This schema includes syntax validity check only; it does not check whether the
function actually exists.

This schema includes syntax validity check only; it does not check whether the
function actually exists.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::perl::funcname>

L<Sah::Schema::perl::qualified_funcname>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
