package PERLANCAR::warnings::all;

our $BITS1 = "UUUUUUUUUUUUUUUUUUU\25"; # PRECOMPUTED FROM: do { require warnings; warnings->import("all"); ${^WARNING_BITS} }
our $BITS2 = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"; # PRECOMPUTED FROM: do { require warnings; warnings->unimport;      ${^WARNING_BITS} }

sub import {
    ${^WARNING_BITS} = $BITS1;
}

sub unimport {
    ${^WARNING_BITS} = $BITS2;
}

1;
# ABSTRACT: Turn on warnings (all) with less code

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::warnings::all - Turn on warnings (all) with less code

=head1 VERSION

This document describes version 0.01 of PERLANCAR::warnings::all (from Perl distribution PERLANCAR-warnings-all), released on 2016-03-23.

=head1 SYNOPSIS

 use PERLANCAR::warnings::all;

is equivalent to:

 use warnings 'all';

but with less code and startup overhead.

=head1 DESCRIPTION

Just an experimental module (probably silly).

Some notes: the bits depend on the perl used when building the dist.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-warnings-all>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-warnings-all>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-warnings-all>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
