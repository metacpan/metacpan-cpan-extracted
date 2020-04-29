package Sort::Sub::prereq_ala_perlancar;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-19'; # DATE
our $DIST = 'Sort-SubBundle-PERLANCAR'; # DIST
our $VERSION = '0.081'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        summary => 'Sort prereqs PERLANCAR-style',
    };
}

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = 0;
        {
            my $a_is_perl = $a eq 'perl' ? 1:0;
            my $b_is_perl = $b eq 'perl' ? 1:0;

            my $a_is_pragma = $a =~ /\A[a-z]/ ? 1:0;
            my $b_is_pragma = $b =~ /\A[a-z]/ ? 1:0;

            $cmp =
                ($b_is_perl <=> $a_is_perl) ||
                ($b_is_pragma <=> $a_is_pragma) ||
                lc($a) cmp lc($b);
        }

        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort prereqs PERLANCAR-style

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::prereq_ala_perlancar - Sort prereqs PERLANCAR-style

=head1 VERSION

This document describes version 0.081 of Sort::Sub::prereq_ala_perlancar (from Perl distribution Sort-SubBundle-PERLANCAR), released on 2020-02-19.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$prereq_ala_perlancar'; # use '$prereq_ala_perlancar<i>' for case-insensitive sorting, '$prereq_ala_perlancar<r>' for reverse sorting
 my @sorted = sort $prereq_ala_perlancar ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'prereq_ala_perlancar<ir>';
 my @sorted = sort {prereq_ala_perlancar} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::prereq_ala_perlancar;
 my $sorter = Sort::Sub::prereq_ala_perlancar::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub prereq_ala_perlancar
 % some-cmd | sortsub prereq_ala_perlancar --ignore-case -r

=head1 DESCRIPTION

I sort my prereqs in F<dist.ini> using this rule: C<perl>, then pragmas (sorted
ascibetically), then other modules (sorted ascibetically and
case-insensitively).

Case-sensitive option is ignored. Sorting is always done using the
abovementioned rule.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Sort-Sub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
