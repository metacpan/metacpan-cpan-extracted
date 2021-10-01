package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::CPAN::Release::Static;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::CSVInFiles';

around new => sub {
    require File::ShareDir;

    my $orig = shift;

    my @filenames;
    for my $year (1995..2021) {
        my $filename = File::ShareDir::dist_file(
            ($year < 2021 ? 'TableDataBundle-CPAN-Release-Static-Older' : "TableData-CPAN-Release-Static-$year"),
            "$year.csv");
        push @filenames, $filename;
    }
    $orig->(@_, filenames=>\@filenames);
};

package TableData::CPAN::Release::Static;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-28'; # DATE
our $DIST = 'TableDataBundle-CPAN-Release'; # DIST
our $VERSION = '0.003'; # VERSION

with 'TableDataRole::CPAN::Release::Static';

our %STATS = ("num_rows",350795,"num_columns",9); # STATS

1;
# ABSTRACT: CPAN releases (from oldest to newest)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::CPAN::Release::Static - CPAN releases (from oldest to newest)

=head1 VERSION

This document describes version 0.003 of TableDataRole::CPAN::Release::Static (from Perl distribution TableDataBundle-CPAN-Release), released on 2021-09-28.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::CPAN::Release::Static;

 my $td = TableData::CPAN::Release::Static->new;

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
 % tabledata CPAN::Release::Static --page

 # Get number of rows
 % tabledata --action count_rows CPAN::Release::Static

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA NOTES

The data was retrieved from MetaCPAN.

The C<status> column is the status of the release when the row was retrieved from
MetaCPAN. It is probably not current, so do not use it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-CPAN-Release>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-CPAN-Release>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-CPAN-Release>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
