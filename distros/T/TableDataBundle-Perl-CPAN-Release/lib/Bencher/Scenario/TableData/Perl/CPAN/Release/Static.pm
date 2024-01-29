package Bencher::Scenario::TableData::Perl::CPAN::Release::Static;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-26'; # DATE
our $DIST = 'TableDataBundle-Perl-CPAN-Release'; # DIST
our $VERSION = '20231126.0'; # VERSION

our $scenario = {
    summary => 'Benchmark loading TableData::Perl::CPAN::Release::Static',
    participants => [
        {
            module=>'TableData::Perl::CPAN::Release::Static',
            code_template => 'TableData::Perl::CPAN::Release::Static->new->each_row_hashref(sub {1})',
        },
    ],
    precision => 1,
};

1;
# ABSTRACT: Benchmark loading TableData::Perl::CPAN::Release::Static

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TableData::Perl::CPAN::Release::Static - Benchmark loading TableData::Perl::CPAN::Release::Static

=head1 VERSION

This document describes version 20231126.0 of Bencher::Scenario::TableData::Perl::CPAN::Release::Static (from Perl distribution TableDataBundle-Perl-CPAN-Release), released on 2023-11-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TableData::Perl::CPAN::Release::Static

To run module startup overhead benchmark:

 % bencher --module-startup -m TableData::Perl::CPAN::Release::Static

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<TableData::Perl::CPAN::Release::Static>

=head1 BENCHMARK PARTICIPANTS

=over

=item * TableData::Perl::CPAN::Release::Static (perl_code)

Code template:

 TableData::Perl::CPAN::Release::Static->new->each_row_hashref(sub {1})



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m TableData::Perl::CPAN::Release::Static

Result formatted as table:

 #table1#
 +----------------------------------------+---------+--------+------+--------------+-------------+-----------------------+-----------------------+---------+---------+
 | participant                            | ds_tags | p_tags | perl |    rate (/s) |        time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------+---------+--------+------+--------------+-------------+-----------------------+-----------------------+---------+---------+
 | TableData::Perl::CPAN::Release::Static |         |        | perl | 0.2047387959 | 4.884272156 |                 0.00% |                 0.00% | 6.9e-11 |       1 |
 +----------------------------------------+---------+--------+------+--------------+-------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

              Rate     
    0.2047387959/s  -- 
 
 Legends:
   : ds_tags= p_tags= participant=TableData::Perl::CPAN::Release::Static perl=perl

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m TableData::Perl::CPAN::Release::Static --module-startup

Result formatted as table:

 #table2#
 +----------------------------------------+------------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                            |  time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------------+------------+-------------------+-----------------------+-----------------------+---------+---------+
 | TableData::Perl::CPAN::Release::Static | 217.944692 |           2.29145 |                 0.00% |                 1.06% | 2.4e-11 |       1 |
 | perl -e1 (baseline)                    | 215.653242 |           0       |                 1.06% |                 0.00% | 7.4e-11 |       1 |
 +----------------------------------------+------------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                        Rate  TPCR:S  perl -e1 (baseline) 
  TPCR:S               4.6/s      --                  -1% 
  perl -e1 (baseline)  4.6/s      1%                   -- 
 
 Legends:
   TPCR:S: mod_overhead_time=2.29145 participant=TableData::Perl::CPAN::Release::Static
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Perl-CPAN-Release>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Perl-CPAN-Release>.

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

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Perl-CPAN-Release>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
