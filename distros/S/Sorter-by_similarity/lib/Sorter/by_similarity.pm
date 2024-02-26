package Sorter::by_similarity;

use 5.010001;
use strict;
use warnings;

use Text::Levenshtein::XS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-24'; # DATE
our $DIST = 'Sorter-by_similarity'; # DIST
our $VERSION = '0.004'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            string => {schema=>'str*', req=>1},
            reverse => {schema => 'bool*'},
            ci => {schema => 'bool*'},
        },
    };
}

sub gen_sorter {
    my %args = @_;

    my $reverse = $args{reverse};
    my $ci = $args{ci};

    sub {
        my @items = @_;
        my @distances;
        if ($ci) {
            @distances = map { Text::Levenshtein::XS::distance($args{string}, $_) } @items;
        } else {
            @distances = map { Text::Levenshtein::XS::distance(lc($args{string}), (lc $_)) } @items;
        }

        map { $items[$_] } sort {
            ($reverse ? $distances[$b] <=> $distances[$a] : $distances[$a] <=> $distances[$b]) ||
                ($reverse ? $b <=> $a : $a <=> $b)
            } 0 .. $#items;
    };
}

1;
# ABSTRACT: Sort by most similar to a reference string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sorter::by_similarity - Sort by most similar to a reference string

=head1 VERSION

This document describes version 0.004 of Sorter::by_similarity (from Perl distribution Sorter-by_similarity), released on 2024-01-24.

=head1 SYNOPSIS

 use Sorter::by_similarity;

 my $sorter = Sorter::by_similarity::gen_sorter(string => 'foo');
 my @sorted = $sorter->("food", "foolish", "foo", "bar");
 # => ("foo", "food", "bar", "foolish")

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|gen_sorter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sorter-by_similarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sorter-by_similarity>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sorter-by_similarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
