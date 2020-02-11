package Sah::Schema::pathname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.013'; # VERSION

our $schema = [str => {
    summary => 'Filesystem path name',
    'x.completion' => ['filename'],
    'prefilters' => [
        'Path::expand_tilde_when_on_unix',
        'Path::strip_slashes_when_on_unix',
    ],
}, {}];

1;
# ABSTRACT: Filesystem path name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::pathname - Filesystem path name

=head1 VERSION

This document describes version 0.013 of Sah::Schema::pathname (from Perl distribution Sah-Schemas-Path), released on 2020-02-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
