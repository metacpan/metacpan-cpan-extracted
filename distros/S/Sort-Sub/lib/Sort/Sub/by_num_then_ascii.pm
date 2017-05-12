package Sort::Sub::by_num_then_ascii;

our $DATE = '2016-12-18'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010;
use strict;
use warnings;

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    my $re_is_num = qr/\A
                       [+-]?
                       (?:\d+|\d*(?:\.\d*)?)
                       (?:[Ee][+-]?\d+)?
                       \z/x;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = 0;
        if ($a =~ $re_is_num) {
            if ($b =~ $re_is_num) {
                $cmp = $a <=> $b;
            } else {
                $cmp = -1;
            }
        } else {
            if ($b =~ $re_is_num) {
                $cmp = 1;
            } else {
                $cmp = $is_ci ?
                    lc($a) cmp lc($b) : $a cmp $b;
            }
        }
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort numbers (sorted numerically) before non-numbers (sorted asciibetically)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_num_then_ascii - Sort numbers (sorted numerically) before non-numbers (sorted asciibetically)

=head1 VERSION

This document describes version 0.10 of Sort::Sub::by_num_then_ascii (from Perl distribution Sort-Sub), released on 2016-12-18.

=for Pod::Coverage ^(gen_sorter)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_num_then_ascii'; # use '$by_num_then_ascii<i>' for case-insensitive sorting, '$by_num_then_ascii<r>' for reverse sorting
 my @sorted = sort $by_num_then_ascii ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_num_then_ascii<ir>';
 my @sorted = sort {by_num_then_ascii} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_num_then_ascii;
 my $sorter = Sort::Sub::by_num_then_ascii::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_num_then_ascii
 % some-cmd | sortsub by_num_then_ascii --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
