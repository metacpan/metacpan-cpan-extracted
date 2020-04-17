package Sah::Schemas::Collection;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Collection'; # DIST
our $VERSION = '0.004'; # VERSION

1;
# ABSTRACT: Various Sah collection (array/hash) schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Collection - Various Sah collection (array/hash) schemas

=head1 VERSION

This document describes version 0.004 of Sah::Schemas::Collection (from Perl distribution Sah-Schemas-Collection), released on 2020-03-02.

=head1 SAH SCHEMAS

=over

=item * L<aoaoms|Sah::Schema::aoaoms>

Array of (defined-)array-of-maybe-strings.




=item * L<aoaos|Sah::Schema::aoaos>

Array of (defined-)array-of-(defined-)strings.




=item * L<aohoms|Sah::Schema::aohoms>

Array of (defined-)hash-of-maybe-strings.




=item * L<aohos|Sah::Schema::aohos>

Array of (defined-)hash-of-(defined-)strings.




=item * L<aoms|Sah::Schema::aoms>

Array of maybe-strings.




=item * L<aos|Sah::Schema::aos>

Array of (defined) strings.

The elements (strings) of the array must be defined.


=item * L<hoaoms|Sah::Schema::hoaoms>

Hash of (defined-)array-of-(maybe-)strings.




=item * L<hoaos|Sah::Schema::hoaos>

Hash of (defined-)array-of-(defined-)strings.




=item * L<hohoms|Sah::Schema::hohoms>

Hash of (defined-)hash-of-maybe-strings.




=item * L<hohos|Sah::Schema::hohos>

Hash of (defined-)hash-of-(defined-)strings.




=item * L<homs|Sah::Schema::homs>

Hash of maybe-strings.




=item * L<hos|Sah::Schema::hos>

Hash of (defined) strings.




=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
