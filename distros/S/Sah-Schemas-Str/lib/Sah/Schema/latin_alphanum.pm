package Sah::Schema::latin_alphanum;

our $DATE = '2019-08-23'; # DATE
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => 'String containing only zero or more Latin letters/digits, i.e. A-Za-z0-9',
    match => qr/\A[A-Za-z0-9]*\z/,
}, {}];

1;
# ABSTRACT: String containing only zero or more Latin letters/digits, i.e. A-Za-z0-9

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::latin_alphanum - String containing only zero or more Latin letters/digits, i.e. A-Za-z0-9

=head1 VERSION

This document describes version 0.001 of Sah::Schema::latin_alphanum (from Perl distribution Sah-Schemas-Str), released on 2019-08-23.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
