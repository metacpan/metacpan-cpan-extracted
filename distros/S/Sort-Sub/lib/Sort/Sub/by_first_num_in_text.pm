package Sort::Sub::by_first_num_in_text;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-28'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.118'; # VERSION

use 5.010001;
use strict;
use warnings;
require Sort::Sub::by_num_in_text;
*gen_sorter = \&Sort::Sub::by_num_in_text::gen_sorter;
*meta       = \&Sort::Sub::by_num_in_text::meta;

1;
# ABSTRACT: Sort by first number found in text or (if no number is found) ascibetically

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_first_num_in_text - Sort by first number found in text or (if no number is found) ascibetically

=head1 VERSION

This document describes version 0.118 of Sort::Sub::by_first_num_in_text (from Perl distribution Sort-Sub), released on 2020-02-28.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_first_num_in_text'; # use '$by_first_num_in_text<i>' for case-insensitive sorting, '$by_first_num_in_text<r>' for reverse sorting
 my @sorted = sort $by_first_num_in_text ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_first_num_in_text<ir>';
 my @sorted = sort {by_first_num_in_text} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_first_num_in_text;
 my $sorter = Sort::Sub::by_first_num_in_text::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_first_num_in_text
 % some-cmd | sortsub by_first_num_in_text --ignore-case -r

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

L<Sort::Sub::by_num_in_text>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
