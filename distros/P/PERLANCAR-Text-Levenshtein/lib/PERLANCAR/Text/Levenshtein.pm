package PERLANCAR::Text::Levenshtein;

our $DATE = '2015-09-20'; # DATE
our $VERSION = '0.02'; # VERSION

#use 5.010001;
#use strict;
#use warnings;

#require Exporter;
#our @ISA = qw(Exporter);
#our @EXPORT_OK = qw(editdist);

sub __min(@) {
    my $m = $_[0];
    for (@_) {
        $m = $_ if $_ < $m;
    }
    $m;
}

# straight copy of Wikipedia's "Levenshtein Distance"
sub editdist {
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

1;
# ABSTRACT: Calculate Levenshtein edit distance

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Text::Levenshtein - Calculate Levenshtein edit distance

=head1 VERSION

This document describes version 0.02 of PERLANCAR::Text::Levenshtein (from Perl distribution PERLANCAR-Text-Levenshtein), released on 2015-09-20.

=head1 DESCRIPTION

This module contains the routine C<editdist> copied from L<App::perlbrew>, which
is copied from Wikipedia article "Levenshtein Distance".

=head1 FUNCTIONS

=head2 editdist($str1, $str2) => int

Not exported.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Text-Levenshtein>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Text-Levenshtein>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Text-Levenshtein>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
