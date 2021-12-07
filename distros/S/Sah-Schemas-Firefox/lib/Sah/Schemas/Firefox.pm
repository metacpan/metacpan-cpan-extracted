package Sah::Schemas::Firefox;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-19'; # DATE
our $DIST = 'Sah-Schemas-Firefox'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Firefox - Various Sah schemas related to Firefox

=head1 VERSION

This document describes version 0.003 of Sah::Schemas::Firefox (from Perl distribution Sah-Schemas-Firefox), released on 2021-07-19.

=head1 CONTRIBUTOR

=for stopwords perlancar (on pc-home)

perlancar (on pc-home) <perlancar@gmail.com>

=head1 SAH SCHEMAS

=over

=item * L<firefox::local_profile_name|Sah::Schema::firefox::local_profile_name>

Firefox profile name, must exist in local Firefox installation.

=item * L<firefox::profile_name|Sah::Schema::firefox::profile_name>

Firefox profile name.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Firefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
