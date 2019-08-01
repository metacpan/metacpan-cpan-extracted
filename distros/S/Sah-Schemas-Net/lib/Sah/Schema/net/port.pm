package Sah::Schema::net::port;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.007'; # VERSION

our $schema = [int => {
    summary => 'Network port number',
    between => [1, 65535],
}, {}];

1;
# ABSTRACT: Network port number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::port - Network port number

=head1 VERSION

This document describes version 0.007 of Sah::Schema::net::port (from Perl distribution Sah-Schemas-Net), released on 2019-07-25.

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
