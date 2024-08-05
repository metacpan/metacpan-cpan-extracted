package Data::Size::Suffix::Dataspeed;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-03'; # DATE
our $DIST = 'Sah-SchemaBundle-DataSizeSpeed'; # DIST
our $VERSION = '0.010'; # VERSION

# case-sensitive
our %suffixes = (

    # bits per second

    bps => 1/8,
    bit => 1/8,

    k    => 1024/8,
    kbit => 1024/8,
    Kbit => 1024/8,
    kbps => 1024/8,
    Kbps => 1024/8,

    m    => 1024**2/8,
    mbit => 1024**2/8,
    Mbit => 1024**2/8,
    mbps => 1024**2/8,
    Mbps => 1024**2/8,

    gbit => 1024**3/8,
    Gbit => 1024**3/8,
    gbps => 1024**3/8,
    Gbps => 1024**3/8,

    tbit => 1024**4/8,
    Tbit => 1024**4/8,
    Tbps => 1024**4/8,
    Tbps => 1024**4/8,

    pbit => 1024**5/8,
    Pbit => 1024**5/8,
    Pbps => 1024**5/8,
    Pbps => 1024**5/8,

    # XXX 1000-based? e.g. Mibit?

    # bytes per second
    'b/s' => 1,
    'B/s' => 1,

    'K'    => 1024,
    'K/s'  => 1024,
    'kb/s' => 1024,
    'Kb/s' => 1024,
    'KB/s' => 1024,

    'M'    => 1024**2,
    'M/s'  => 1024**2,
    'mb/s' => 1024**2,
    'Mb/s' => 1024**2,
    'MB/s' => 1024**2,

    'gb/s' => 1024**3,
    'Gb/s' => 1024**3,
    'GB/s' => 1024**3,

    'tb/s' => 1024**4,
    'Tb/s' => 1024**4,
    'TB/s' => 1024**4,

    'Pb/s' => 1024**5,
    'Pb/s' => 1024**5,
    'PB/s' => 1024**5,

);

1;
# ABSTRACT: Digital data transfer speed suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Size::Suffix::Dataspeed - Digital data transfer speed suffixes

=head1 VERSION

This document describes version 0.010 of Data::Size::Suffix::Dataspeed (from Perl distribution Sah-SchemaBundle-DataSizeSpeed), released on 2024-08-03.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-DataSizeSpeed>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
