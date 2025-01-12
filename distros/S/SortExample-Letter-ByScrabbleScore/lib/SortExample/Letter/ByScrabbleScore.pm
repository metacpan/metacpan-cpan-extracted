package SortExample::Letter::ByScrabbleScore;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-12'; # DATE
our $DIST = 'SortExample-Letter-ByScrabbleScore'; # DIST
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
        qw/Q Z/,                 # 10
        qw/J X/,                 #  8
        qw/K/,                   #  5
        qw/F H V W Y/,           #  4
        qw/B C M P/,             #  3
        qw/D G/,                 #  2
        qw/A E I L N O R S T U/, #  1
    ];
}

1;
# ABSTRACT: Ordered list of letters by highest score in Scrabble

__END__

=pod

=encoding UTF-8

=head1 NAME

SortExample::Letter::ByScrabbleScore - Ordered list of letters by highest score in Scrabble

=head1 VERSION

This document describes version 0.001 of SortExample::Letter::ByScrabbleScore (from Perl distribution SortExample-Letter-ByScrabbleScore), released on 2025-01-12.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|get_example)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortExample-Letter-ByScrabbleScore>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortExample-Letter-ByScrabbleScore>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortExample-Letter-ByScrabbleScore>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
