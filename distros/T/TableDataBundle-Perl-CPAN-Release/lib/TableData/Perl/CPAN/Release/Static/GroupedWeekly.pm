package TableData::Perl::CPAN::Release::Static::GroupedWeekly;

use 5.010001;
use strict;
use warnings;

use parent 'TableData::Munge::GroupRows';

use DateTime;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-28'; # DATE
our $DIST = 'TableDataBundle-Perl-CPAN-Release'; # DIST
our $VERSION = '20231228.0'; # VERSION

my $re_date = qr/\A(\d\d\d\d)-(\d\d)-(\d\d)/;

sub new {
    require DateTime;

    my $self = shift;
    my $dt_sunday;
    my $dt_prev_sunday;
    my $prev_date; # to cache, for speed
    $self->SUPER::new(
        tabledata => 'Perl::CPAN::Release::Static',
        key => 'sunday',
        calc_key => sub {
            my ($rowh, $aoa) = @_;
            $rowh->{date} =~ $re_date or die;
            my $date = "$1-$2-$3";
            if (!$prev_date || $date ne $prev_date) {
                $dt_sunday = DateTime->new(year=>$1, month=>$2, day=>$3); $dt_sunday->subtract(days => $dt_sunday->day_of_week) unless $dt_sunday->day_of_week == 7;
                #print "D:sunday=".($dt_sunday->ymd)."\n";
                if ($dt_prev_sunday && DateTime->compare($dt_prev_sunday, $dt_sunday)) {
                    $dt_prev_sunday->add(days => 7);
                    while (DateTime->compare($dt_prev_sunday, $dt_sunday) < 0) {
                        push @$aoa, [$dt_prev_sunday->ymd, []];
                        $dt_prev_sunday->add(days => 7);
                    }
                }
                $dt_prev_sunday = $dt_sunday;
            }
            $prev_date = $date;
            $dt_sunday->ymd;
        },
    );
}

our %STATS = ("num_columns",2,"num_rows",1479); # STATS

1;
# ABSTRACT: CPAN releases (grouped weekly)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Perl::CPAN::Release::Static::GroupedWeekly - CPAN releases (grouped weekly)

=head1 VERSION

This document describes version 20231228.0 of TableData::Perl::CPAN::Release::Static::GroupedWeekly (from Perl distribution TableDataBundle-Perl-CPAN-Release), released on 2023-12-28.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Perl::CPAN::Release::Static::GroupedWeekly;

 my $td = TableData::Perl::CPAN::Release::Static::GroupedWeekly->new;

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
 % tabledata Perl::CPAN::Release::Static::GroupedWeekly --page

 # Get number of rows
 % tabledata --action count_rows Perl::CPAN::Release::Static::GroupedWeekly

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 2     |
 | num_rows    | 1479  |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=for Pod::Coverage ^(.+)$

=head1 TABLEDATA NOTES

The data was filtered from L<TableData::Perl::CPAN::Release::Static>.

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
