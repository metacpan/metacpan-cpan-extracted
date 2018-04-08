package Sah::Schema::uint;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.071'; # VERSION

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

Sah::Schema::uint - Non-negative integer (0, 1, 2, ...)

=head1 VERSION

This document describes version 0.071 of Sah::Schema::uint (from Perl distribution Sah-Schemas-Int), released on 2018-04-03.

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

This software is copyright (c) 2018, 2017, 2016, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
