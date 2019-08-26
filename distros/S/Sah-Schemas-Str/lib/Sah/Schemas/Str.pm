package Sah::Schemas::Str;

1;
# ABSTRACT: Various string schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Str - Various string schemas

=head1 VERSION

This document describes version 0.001 of Sah::Schemas::Str (from Perl distribution Sah-Schemas-Str), released on 2019-08-23.

=head1 SAH SCHEMAS

=over

=item * L<hexstr|Sah::Schema::hexstr>

String of bytes in hexadecimal.

=item * L<latin_alpha|Sah::Schema::latin_alpha>

String containing only zero or more Latin letters, i.e. A-Z or a-z.

=item * L<latin_alphanum|Sah::Schema::latin_alphanum>

String containing only zero or more Latin letters/digits, i.e. A-Za-z0-9.

=item * L<latin_letter|Sah::Schema::latin_letter>

Latin letter, i.e. A-Z or a-z.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
