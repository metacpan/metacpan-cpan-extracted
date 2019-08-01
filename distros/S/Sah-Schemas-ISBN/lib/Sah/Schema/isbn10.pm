package Sah::Schema::isbn10;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.006'; # VERSION

our $schema = [str => {
    summary => 'ISBN 10 number',
    description => <<'_',

Nondigits [^0-9Xx] will be removed during coercion.

"x" will be converted to uppercase.

Checksum digit must be valid.

_
    match => '\A[0-9]{9}[0-9Xx]\z',
    'x.perl.coerce_rules' => ['str_to_isbn10'],
}, {}];

1;
# ABSTRACT: ISBN 10 number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::isbn10 - ISBN 10 number

=head1 VERSION

This document describes version 0.006 of Sah::Schema::isbn10 (from Perl distribution Sah-Schemas-ISBN), released on 2019-07-25.

=head1 DESCRIPTION

Nondigits [^0-9Xx] will be removed during coercion.

"x" will be converted to uppercase.

Checksum digit must be valid.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-ISBN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-ISBN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-ISBN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
