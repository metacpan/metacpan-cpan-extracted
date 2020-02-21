package Sort::Sub::by_dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'Sort-Sub-by_dmp'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

sub meta {
    return {
        v => 1,
        summary => 'Sort data structures by comparing their dump (using Data::Dmp)',
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

        # XXX cache

        my $dmp_a = dmp($a);
        my $dmp_b = dmp($b);

        $cmp = $is_ci ? lc($dmp_a) cmp lc($dmp_b) : $dmp_a cmp $dmp_b;
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort data structures by comparing their dump (using Data::Dmp)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_dmp - Sort data structures by comparing their dump (using Data::Dmp)

=head1 VERSION

This document describes version 0.002 of Sort::Sub::by_dmp (from Perl distribution Sort-Sub-by_dmp), released on 2019-12-15.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_dmp'; # use '$by_dmp<i>' for case-insensitive sorting, '$by_dmp<r>' for reverse sorting
 my @sorted = sort $by_dmp ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_dmp<ir>';
 my @sorted = sort {by_dmp} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_dmp;
 my $sorter = Sort::Sub::by_dmp::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_dmp
 % some-cmd | sortsub by_dmp --ignore-case -r

=head1 DESCRIPTION

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-by_dmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-by_dmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-by_dmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub::data_struct_by_data_cmp>. Most of the time, you'd probably want
this instead.

L<Sort::Sub::by_perl_function>

L<Sort::Sub::by_perl_op>

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
