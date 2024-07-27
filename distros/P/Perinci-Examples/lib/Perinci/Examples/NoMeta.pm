package Perinci::Examples::NoMeta;

# This is a sample of a "traditional" Perl module, with no metadata or enveloped
# result.

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.825'; # VERSION

our $Var1 = 1;

sub pyth($$) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my ($a, $b) = @_;
    ($a*$a + $b*$b)**0.5;
}

sub gen_array {
    my ($len) = @_;
    $len //= 10;
    my @res;
    for (1..$len) { push @res, int(rand $len)+1 }
    \@res;
}

1;
# ABSTRACT: Example of module without any metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::NoMeta - Example of module without any metadata

=head1 VERSION

This document describes version 0.825 of Perinci::Examples::NoMeta (from Perl distribution Perinci-Examples), released on 2024-07-17.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

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

This software is copyright (c) 2024, 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
