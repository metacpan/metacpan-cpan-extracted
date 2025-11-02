package SortExample::Letter::ByFrequency::ID;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-12'; # DATE
our $DIST = 'SortExample-Letter-ByFrequency-ID'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    +{
        v => 1,
        args => {},
    };
}

sub get_example {
    my %args = @_;

    [
        qw/Q X/,                 # 10
        qw/V Z/,                 #  8
        qw/C F J W Y/,           #  5
        qw/D H/,                 #  4
        qw/B G P/,               #  3
        qw/L M O S T/,           #  2
        qw/A E I K N R U/,       #  1
    ];
}

1;
# ABSTRACT: Ordered list of letters by usage frequency in Indonesian words

__END__

=pod

=encoding UTF-8

=head1 NAME

SortExample::Letter::ByFrequency::ID - Ordered list of letters by usage frequency in Indonesian words

=head1 VERSION

This document describes version 0.001 of SortExample::Letter::ByFrequency::ID (from Perl distribution SortExample-Letter-ByFrequency-ID), released on 2025-01-12.

=head1 DESCRIPTION

Usage is not only in first letter of words, but also in other positions. Using
rank from scores of letters in Defend Cards [1] game, which uses scores from
Scrabble but with different scores of letters.

[1] https://www.instagram.com/defendfitandfun/

=for Pod::Coverage ^(meta|get_example)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortExample-Letter-ByFrequency-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortExample-Letter-ByFrequency-ID>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortExample-Letter-ByFrequency-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
