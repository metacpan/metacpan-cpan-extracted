package Sah::Schema::net::hostname;

our $DATE = '2018-01-17'; # DATE
our $VERSION = '0.003'; # VERSION

our $schema = [str => {
    summary => 'Hostname',
    match => '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$', # as per RFC 1123
}, {}];

1;
# ABSTRACT: Hostname

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::hostname - Hostname

=head1 VERSION

This document describes version 0.003 of Sah::Schema::net::hostname (from Perl distribution Sah-Schemas-Net), released on 2018-01-17.

=head1 DESCRIPTION

Hostname is checked using a regex as per RFC 1123.

Ref: L<https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address>

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

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
