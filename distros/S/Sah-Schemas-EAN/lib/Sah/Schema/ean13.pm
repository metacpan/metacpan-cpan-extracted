package Sah::Schema::ean13;

our $DATE = '2019-11-28'; # DATE
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'EAN-13 number',
    description => <<'_',

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

_
    match => '\A[0-9]{13}\z',
    'x.perl.coerce_rules' => ['From_str::to_ean13'],
}, {}];

1;
# ABSTRACT: EAN-13 number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::ean13 - EAN-13 number

=head1 VERSION

This document describes version 0.005 of Sah::Schema::ean13 (from Perl distribution Sah-Schemas-EAN), released on 2019-11-28.

=head1 DESCRIPTION

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

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
