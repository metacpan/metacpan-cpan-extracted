package Sort::BySimilarity;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
use Text::Levenshtein::XS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-19'; # DATE
our $DIST = 'Sort-BySimilarity'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       gen_sorter_by_similarity
                       sort_by_similarity
               );
#gen_cmp_by_similarity

sub gen_sorter_by_similarity {
    my ($is_reverse, $is_ci, $args) = @_;
    $args //= {};

    sub {
        my @items = @_;
        my @distances;
        if ($is_ci) {
            @distances = map { Text::Levenshtein::XS::distance($args->{string}, $_) } @items;
        } else {
            @distances = map { Text::Levenshtein::XS::distance(lc($args->{string}), (lc $_)) } @items;
        }

        map { $items[$_] } sort {
            ($is_reverse ? $distances[$b] <=> $distances[$a] : $distances[$a] <=> $distances[$b]) ||
                ($is_reverse ? $b <=> $a : $a <=> $b)
            } 0 .. $#items;
    };
}

sub sort_by_similarity {
    my $is_reverse = shift;
    my $is_ci = shift;
    my $args = shift;
    gen_sorter_by_similarity($is_reverse, $is_ci, $args)->(@_);
}

1;
# ABSTRACT: Sort by most similar to a reference string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::BySimilarity - Sort by most similar to a reference string

=head1 VERSION

This document describes version 0.002 of Sort::BySimilarity (from Perl distribution Sort-BySimilarity), released on 2024-01-19.

=head1 SYNOPSIS

 use Sort::BySimilarity qw(
     gen_sorter_by_similarity
     gen_cmp_by_similarity
     sort_by_similarity
 );

 #                               reverse?  case insensitive?  args
 my $sorter = gen_sorter_by_similarity(0,        0,                 {string=>"foo"});
 my @sorted = $sorter->("food", "foolish", "foo", "bar"); #

 # or, in one go
 my @sorted = sort_by_similarity(0, 0, {string=>"foo"}, "food", "foolish", "foo", "bar");

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 gen_sorter_by_similarity

Usage:

 my $sorter = gen_sorter_by_similarity($is_reverse, $is_ci, \%args);

Will generate a sorter subroutine C<$sorter> which accepts list and will sort
them and return the sorted items. C<$is_reverse> is a bool, can be set to true
to generate a reverse sorter (least similar items will be put first). C<$is_ci>
is a bool, can be set to true to sort case-insensitively.

Arguments:

=over

=item * string

Str. Required. Reference string to be compared against each item.

=back

=head2 sort_by_similarity

Usage:

 my @sorted = sort_by_similarity($is_reverse, $is_ci, \%args, @items);

A shortcut to generate sorter and sort items with sorter in one go.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-BySimilarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-BySimilarity>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-BySimilarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
