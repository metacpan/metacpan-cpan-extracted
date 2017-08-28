package Sah::Schema::int32;

our $DATE = '2017-08-19'; # DATE
our $VERSION = '0.070'; # VERSION

our $schema = [int => {
    summary => '32-bit signed integer',
    min     => -2**31,
    max     => +2**31-1,
}, {}];

1;
# ABSTRACT: 32-bit signed integer

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::int32 - 32-bit signed integer

=head1 VERSION

This document describes version 0.070 of Sah::Schema::int32 (from Perl distribution Sah-Schemas-Int), released on 2017-08-19.

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
