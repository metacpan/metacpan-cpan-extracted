package Sah::Schema::net::ipv4;

our $DATE = '2018-01-14'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = [obj => {
    summary => 'IPv4 address',
    isa => 'NetAddr::IP',
    'x.perl.coerce_rules' => [
        'str_net_ipv4',
    ],
}, {}];

1;
# ABSTRACT: IPv4 address

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::ipv4 - IPv4 address

=head1 VERSION

This document describes version 0.002 of Sah::Schema::net::ipv4 (from Perl distribution Sah-Schemas-Net), released on 2018-01-14.

=head1 DESCRIPTION

Currently using L<NetAddr::IP> object.

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
