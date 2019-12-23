package Sort::Sub::by_num_in_text;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.116'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        summary => 'Sort by first number found in text or (if no number is found) ascibetically',
    };
}
sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp;

        my $num_a; $num_a = $1 if $a =~ /(\d+)/;
        my $num_b; $num_b = $1 if $b =~ /(\d+)/;

        {
            if (defined $num_a && defined $num_b) {
                $cmp = $num_a <=> $num_b;
                last if $cmp;
            } elsif (defined $num_a && !defined $num_b) {
                $cmp = -1;
                last;
            } elsif (!defined $num_a && defined $num_b) {
                $cmp = 1;
                last;
            }

            if ($is_ci) {
                $cmp = lc($a) cmp lc($b);
            } else {
                $cmp = $a cmp $b;
            }
        }

        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort by first number found in text or (if no number is found) ascibetically

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_num_in_text - Sort by first number found in text or (if no number is found) ascibetically

=head1 VERSION

This document describes version 0.116 of Sort::Sub::by_num_in_text (from Perl distribution Sort-Sub), released on 2019-12-15.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_num_in_text'; # use '$by_num_in_text<i>' for case-insensitive sorting, '$by_num_in_text<r>' for reverse sorting
 my @sorted = sort $by_num_in_text ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_num_in_text<ir>';
 my @sorted = sort {by_num_in_text} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_num_in_text;
 my $sorter = Sort::Sub::by_num_in_text::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_num_in_text
 % some-cmd | sortsub by_num_in_text --ignore-case -r

=head1 DESCRIPTION

The generated sort routine will sort by first number (sequence of [0-9]) found
in text or (f no number is found in text) ascibetically. Items that have a
number will sort before items that do not.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

L<Sort::Sub::by_last_num_in_text>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
