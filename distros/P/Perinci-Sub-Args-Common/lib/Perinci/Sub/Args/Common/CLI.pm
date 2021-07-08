package Perinci::Sub::Args::Common::CLI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-22'; # DATE
our $DIST = 'Perinci-Sub-Args-Common'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       %argspec_detail
               );

our %argspec_detail = (
    detail => {
        summary => 'Return detailed record for each result item',
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

1;
# ABSTRACT: A collection of common argument specifications for CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Args::Common::CLI - A collection of common argument specifications for CLI

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::Args::Common::CLI (from Perl distribution Perinci-Sub-Args-Common), released on 2021-02-22.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Args-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Args-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Sub-Args-Common/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
