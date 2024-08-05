package Data::Size::Suffix::Datasize;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-03'; # DATE
our $DIST = 'Sah-SchemaBundle-DataSizeSpeed'; # DIST
our $VERSION = '0.010'; # VERSION

# case-insensitive
our %suffixes = (
    b => 1,

    k => 1024,
    kb => 1024,
    ki => 1000,
    kib => 1000,

    m => 1024**2,
    mb => 1024**2,
    mi => 1e6,
    mib => 1e6,

    g => 1024**3,
    gb => 1024**3,
    gi => 1e9,
    gib => 1e9,

    t => 1024**4,
    tb => 1024**4,
    ti => 1e12,
    tib => 1e12,

    p => 1024**5,
    pb => 1024**5,
    pi => 1e15,
    pib => 1e15,

    #e => 1024**6, # clashes with scientific notation
    eb => 1024**6,
    ei => 1e18,
    eib => 1e18,

    z => 1024**7,
    zb => 1024**7,
    zi => 1e21,
    zb => 1e21,

    y => 1024**8,
    yb => 1024**8,
    yi => 1e24,
    yb => 1e24,
);

1;
# ABSTRACT: Digital data size suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Size::Suffix::Datasize - Digital data size suffixes

=head1 VERSION

This document describes version 0.010 of Data::Size::Suffix::Datasize (from Perl distribution Sah-SchemaBundle-DataSizeSpeed), released on 2024-08-03.

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
