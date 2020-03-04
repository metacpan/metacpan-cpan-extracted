package Sort::Sub::record_by_order;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-28'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.118'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        compares_record => 1,
    };
}

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = $a->[1] <=> $b->[1];
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::record_by_order

=head1 VERSION

This document describes version 0.118 of Sort::Sub::record_by_order (from Perl distribution Sort-Sub), released on 2020-02-28.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$record_by_order'; # use '$record_by_order<i>' for case-insensitive sorting, '$record_by_order<r>' for reverse sorting
 my @sorted = sort $record_by_order ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'record_by_order<ir>';
 my @sorted = sort {record_by_order} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::record_by_order;
 my $sorter = Sort::Sub::record_by_order::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub record_by_order
 % some-cmd | sortsub record_by_order --ignore-case -r

=head1 DESCRIPTION

Sort by the order of records. This sorter expects C<$a> and C<$b> to be records
of:

 [$data, $order]

instead of just:

 $data

It then performs:

 $a->[1] <=> $b->[1]

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

L<Sort::Sub::record_by_reverse_order>

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
