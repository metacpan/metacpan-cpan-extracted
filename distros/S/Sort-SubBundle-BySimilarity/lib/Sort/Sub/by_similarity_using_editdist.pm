package Sort::Sub::by_similarity_using_editdist;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-12'; # DATE
our $DIST = 'Sort-SubBundle-BySimilarity'; # DIST
our $VERSION = '0.001'; # VERSION

sub __min(@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $m = $_[0];
    for (@_) {
        $m = $_ if $_ < $m;
    }
    $m;
}

sub __editdist {
    my @a = split //, shift;
    my @b = split //, shift;

    # There is an extra row and column in the matrix. This is the distance from
    # the empty string to a substring of the target.
    my @d;
    $d[$_][0] = $_ for 0 .. @a;
    $d[0][$_] = $_ for 0 .. @b;

    for my $i (1 .. @a) {
        for my $j (1 .. @b) {
            $d[$i][$j] = (
                $a[$i-1] eq $b[$j-1]
                    ? $d[$i-1][$j-1]
                    : 1 + __min(
                        $d[$i-1][$j],
                        $d[$i][$j-1],
                        $d[$i-1][$j-1]
                    )
                );
        }
    }

    $d[@a][@b];
}

sub meta {
    return {
        v => 1,
        summary => 'Sort strings by similarity to target string (most similar first)',
        description => <<'MARKDOWN',

MARKDOWN
        args => {
            string => {
                schema => 'str*',
                req => 1,
            },
        },
    };
}

sub gen_sorter {
    my ($is_reverse, $is_ci, $args) = @_;

    sub {
        my $dist_a = __editdist(($is_ci ? lc($_[0]) : $_[0]), ($is_ci ? lc($args->{string}) : $args->{string}));
        my $dist_b = __editdist(($is_ci ? lc($_[1]) : $_[1]), ($is_ci ? lc($args->{string}) : $args->{string}));
        my $cmp = ($is_reverse ? -1:1) * ($dist_a <=> $dist_b);
    };
}

1;
# ABSTRACT: Sort strings by similarity to target string (most similar first)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_similarity_using_editdist - Sort strings by similarity to target string (most similar first)

=head1 VERSION

This document describes version 0.001 of Sort::Sub::by_similarity_using_editdist (from Perl distribution Sort-SubBundle-BySimilarity), released on 2024-01-12.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_similarity_using_editdist'; # use '$by_similarity_using_editdist<i>' for case-insensitive sorting, '$by_similarity_using_editdist<r>' for reverse sorting
 my @sorted = sort $by_similarity_using_editdist ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_similarity_using_editdist<ir>';
 my @sorted = sort {by_similarity_using_editdist} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_similarity_using_editdist;
 my $sorter = Sort::Sub::by_similarity_using_editdist::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_similarity_using_editdist
 % some-cmd | sortsub by_similarity_using_editdist --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 string*

str.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-BySimilarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-SubBundle-BySimilarity>.

=head1 SEE ALSO

L<Sort::Sub>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-BySimilarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
