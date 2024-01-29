package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Perl::CPAN::Release::Static;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::CSVInFiles';

around new => sub {
    require DateTime;
    require File::ShareDir;

    my $orig = shift;

    my $now = DateTime->now;
    my $cur_year = $now->year;

    my @filenames;
    for my $year (1995..$cur_year) {
        my $filename = File::ShareDir::dist_file(
            ($year < 2022 ? 'TableDataBundle-Perl-CPAN-Release-Static-Older' : "TableData-Perl-CPAN-Release-Static-$year"),
            "$year.csv");
        push @filenames, $filename;
    }
    $orig->(@_, filenames=>\@filenames);
};

package TableData::Perl::CPAN::Release::Static;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-26'; # DATE
our $DIST = 'TableDataBundle-Perl-CPAN-Release'; # DIST
our $VERSION = '20231126.0'; # VERSION

with 'TableDataRole::Perl::CPAN::Release::Static';

our %STATS = ("num_columns",9,"num_rows",371121); # STATS

1;
# ABSTRACT: CPAN releases (from oldest to newest)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Perl::CPAN::Release::Static - CPAN releases (from oldest to newest)

=head1 VERSION

This document describes version 20231126.0 of TableDataRole::Perl::CPAN::Release::Static (from Perl distribution TableDataBundle-Perl-CPAN-Release), released on 2023-11-26.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Perl::CPAN::Release::Static;

 my $td = TableData::Perl::CPAN::Release::Static->new;

 # Iterate rows of the table
 $td->each_row_arrayref(sub { my $row = shift; ... });
 $td->each_row_hashref (sub { my $row = shift; ... });

 # Get the list of column names
 my @columns = $td->get_column_names;

 # Get the number of rows
 my $row_count = $td->get_row_count;

See also L<TableDataRole::Spec::Basic> for other methods.

To use from command-line (using L<tabledata> CLI):

 # Display as ASCII table and view with pager
 % tabledata Perl::CPAN::Release::Static --page

 # Get number of rows
 % tabledata --action count_rows Perl::CPAN::Release::Static

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+--------+
 | key         | value  |
 +-------------+--------+
 | num_columns | 9      |
 | num_rows    | 371121 |
 +-------------+--------+

The statistics is available in the C<%STATS> package variable.

=head1 TABLEDATA NOTES

The data was retrieved from MetaCPAN.

The C<status> column is the status of the release when the row was retrieved from
MetaCPAN. It is probably not current, so do not use it.

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
