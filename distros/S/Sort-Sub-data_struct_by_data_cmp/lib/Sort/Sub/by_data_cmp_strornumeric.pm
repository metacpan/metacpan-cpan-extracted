package Sort::Sub::by_data_cmp_strornumeric;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'Sort-Sub-data_struct_by_data_cmp'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
require Sort::Sub::data_struct_by_data_cmp_strornumeric;
*gen_sorter = \&Sort::Sub::data_struct_by_data_cmp_strornumeric::gen_sorter;
*meta       = \&Sort::Sub::data_struct_by_data_cmp_strornumeric::meta;

1;
# ABSTRACT: Sort data structures by Data::Cmp::StrOrNumeric

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_data_cmp_strornumeric - Sort data structures by Data::Cmp::StrOrNumeric

=head1 VERSION

This document describes version 0.002 of Sort::Sub::by_data_cmp_strornumeric (from Perl distribution Sort-Sub-data_struct_by_data_cmp), released on 2019-12-15.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_data_cmp_strornumeric'; # use '$by_data_cmp_strornumeric<i>' for case-insensitive sorting, '$by_data_cmp_strornumeric<r>' for reverse sorting
 my @sorted = sort $by_data_cmp_strornumeric ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_data_cmp_strornumeric<ir>';
 my @sorted = sort {by_data_cmp_strornumeric} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_data_cmp_strornumeric;
 my $sorter = Sort::Sub::by_data_cmp_strornumeric::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_data_cmp_strornumeric
 % some-cmd | sortsub by_data_cmp_strornumeric --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

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

L<Sort::Sub>

L<Sort::Sub::data_struct_by_data_cmp_strornumeric>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
