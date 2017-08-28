package Sah::Schema::nonnegint;

our $DATE = '2017-08-19'; # DATE
our $VERSION = '0.070'; # VERSION

our $schema = [int => {
    summary   => 'Non-negative integer (0, 1, 2, ...)',
    min       => 0,
   description => <<'_',

See also `posint` for integers that start from 1.

_
 }, {}];

1;
# ABSTRACT: Non-negative integer (0, 1, 2, ...)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::nonnegint - Non-negative integer (0, 1, 2, ...)

=head1 VERSION

This document describes version 0.070 of Sah::Schema::nonnegint (from Perl distribution Sah-Schemas-Int), released on 2017-08-19.

=head1 DESCRIPTION

See also C<posint> for integers that start from 1.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Int>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Sah-Schema-Int>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Int>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
