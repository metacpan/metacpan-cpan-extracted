package Sah::Schemas::Net;

our $DATE = '2021-07-19'; # DATE
our $VERSION = '0.010'; # VERSION

1;
# ABSTRACT: Schemas related to network (IP address, hostnames, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Net - Schemas related to network (IP address, hostnames, etc)

=head1 VERSION

This document describes version 0.010 of Sah::Schemas::Net (from Perl distribution Sah-Schemas-Net), released on 2021-07-19.

=head1 DESCRIPTION

Todo:

 net::ipv6
 net::ip
 net::ip_range
 net::ipv4_range
 net::ipv6_range

=head1 SAH SCHEMAS

=over

=item * L<net::hostname|Sah::Schema::net::hostname>

Hostname.

=item * L<net::ipv4|Sah::Schema::net::ipv4>

IPv4 address.

=item * L<net::port|Sah::Schema::net::port>

Network port number.

=back

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-zenbook-ux305)

perlancar (on netbook-zenbook-ux305) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
