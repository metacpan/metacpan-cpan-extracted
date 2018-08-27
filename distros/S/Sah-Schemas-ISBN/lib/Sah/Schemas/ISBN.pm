package Sah::Schemas::ISBN;

our $DATE = '2018-08-23'; # DATE
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to ISBN (International Standard Book Number)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::ISBN - Various Sah schemas related to ISBN (International Standard Book Number)

=head1 VERSION

This document describes version 0.003 of Sah::Schemas::ISBN (from Perl distribution Sah-Schemas-ISBN), released on 2018-08-23.

=head1 SAH SCHEMAS

=over

=item * L<isbn|Sah::Schema::isbn>

ISBN 10 or ISBN 13 number.

Nondigits [^0-9Xx] will be removed during coercion.

Checksum digit must be valid.


=item * L<isbn10|Sah::Schema::isbn10>

ISBN 10 number.

Nondigits [^0-9Xx] will be removed during coercion.

"x" will be converted to uppercase.

Checksum digit must be valid.


=item * L<isbn13|Sah::Schema::isbn13>

ISBN 13 number.

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

Basically EAN-13, except with additional coercion rule to coerce it from
ISBN 10.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-ISBN>.

=head1 SOURCE

Source repository is at L<https://github.com///u1@198.58.100.202:/home/u1/repos/perl-Sah-Schemas-ISBN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-ISBN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

L<https://en.wikipedia.org/wiki/International_Standard_Book_Number>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
