package Sort::Sub::data_struct_by_data_cmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'Sort-Sub-data_struct_by_data_cmp'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Cmp qw(cmp_data);

sub meta {
    return {
        v => 1,
        summary => 'Sort data structures by Data::Cmp',
    };
}

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = cmp_data($a, $b);

        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort data structures by Data::Cmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::data_struct_by_data_cmp - Sort data structures by Data::Cmp

=head1 VERSION

This document describes version 0.002 of Sort::Sub::data_struct_by_data_cmp (from Perl distribution Sort-Sub-data_struct_by_data_cmp), released on 2019-12-15.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$data_struct_by_data_cmp'; # use '$data_struct_by_data_cmp<i>' for case-insensitive sorting, '$data_struct_by_data_cmp<r>' for reverse sorting
 my @sorted = sort $data_struct_by_data_cmp ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'data_struct_by_data_cmp<ir>';
 my @sorted = sort {data_struct_by_data_cmp} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::data_struct_by_data_cmp;
 my $sorter = Sort::Sub::data_struct_by_data_cmp::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub data_struct_by_data_cmp
 % some-cmd | sortsub data_struct_by_data_cmp --ignore-case -r

=head1 DESCRIPTION

Always case-sensitive; the C<i> flag does not have effect.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-data_struct_by_data_cmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-data_struct_by_data_cmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-data_struct_by_data_cmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub::data_struct_by_data_cmp_numeric>

L<Sort::Sub::data_struct_by_data_cmp_strornumeric>

L<Data::Cmp>

L<Sort::Sub::by_perl_function>. The more generic solution.

L<Sort::Sub::by_perl_op>

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
