package Data::Size::Suffix::Filesize;

our $DATE = '2019-01-16'; # DATE
our $VERSION = '0.001'; # VERSION

our %suffixes = (
    b => 1,

    k => 1024,
    kb => 1024,
    ki => 1000,
    kib => 1000,

    m => 1024*1024,
    mb => 1024*1024,
    mi => 1e6,
    mib => 1e6,

    g => 1024^3,
    gb => 1024^3,
    gi => 1e9,
    gib => 1e9,

    t => 1024^4,
    tb => 1024^4,
    ti => 1e12,
    tib => 1e12,

    p => 1024^5,
    pb => 1024^5,
    pi => 1e15,
    pib => 1e15,

    #e => 1024^6, # clashes with scientific notation
    eb => 1024^6,
    ei => 1e18,
    eib => 1e18,
);

1;
# ABSTRACT: Filesize suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Size::Suffix::Filesize - Filesize suffixes

=head1 VERSION

This document describes version 0.001 of Data::Size::Suffix::Filesize (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2019-01-16.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
