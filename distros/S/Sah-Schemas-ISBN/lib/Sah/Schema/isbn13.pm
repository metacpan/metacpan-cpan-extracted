package Sah::Schema::isbn13;

# AUTHOR
our $DATE = '2019-11-29'; # DATE
our $DIST = 'Sah-Schemas-ISBN'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = [str => {
    summary => 'ISBN 13 number',
    description => <<'_',

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

Basically EAN-13, except with additional coercion rule to coerce it from
ISBN 10.

_
    match => '\A[0-9]{13}\z',
    'x.perl.coerce_rules' => ['From_str::to_isbn13'],
}, {}];

1;
# ABSTRACT: ISBN 13 number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::isbn13 - ISBN 13 number

=head1 VERSION

This document describes version 0.007 of Sah::Schema::isbn13 (from Perl distribution Sah-Schemas-ISBN), released on 2019-11-29.

=head1 DESCRIPTION

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

Basically EAN-13, except with additional coercion rule to coerce it from
ISBN 10.

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
