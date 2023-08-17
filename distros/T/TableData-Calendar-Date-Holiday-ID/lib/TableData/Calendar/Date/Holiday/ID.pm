package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Calendar::Date::Holiday::ID;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::AOA';

around new => sub {
    require Calendar::Indonesia::Holiday;

    my $orig = shift;

    my $res = Calendar::Indonesia::Holiday::list_idn_holidays(detail=>1);
    die "Can't list holidays from Calendar::Indonesia::Holiday: $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $aoa = [];
    my $column_names = [qw/
                              date day month year dow fixed_date
                              eng_name ind_name
                              is_holiday is_joint_leave
                              is_tag_religious is_tag_calendar_lunar
                              year_start
                              tags
                          /];
    for my $rec (@{ $res->[2] }) {
        push @$aoa, [
            $rec->{date},
            $rec->{day},
            $rec->{month},
            $rec->{year},
            $rec->{dow},
            $rec->{fixed_date} ? 1:0,

            $rec->{eng_name},
            $rec->{ind_name},

            $rec->{is_holiday},
            $rec->{is_joint_leave},

            ((grep { $_ eq 'religious' } @{ $rec->{tags} // [] }) ? 1:0),
            ((grep { $_ eq 'calendar=lunar' } @{ $rec->{tags} // [] }) ? 1:0),

            $rec->{year_start},

            join(", ", @{ $rec->{tags} // [] }),
        ];
    }

    $orig->(@_, aoa => $aoa, column_names=>$column_names);
};

package TableData::Calendar::Date::Holiday::ID;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-19'; # DATE
our $DIST = 'TableData-Calendar-Date-Holiday-ID'; # DIST
our $VERSION = '0.001'; # VERSION

with 'TableDataRole::Calendar::Date::Holiday::ID';

# STATS

1;
# ABSTRACT: Indonesian holiday dates

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Calendar::Date::Holiday::ID - Indonesian holiday dates

=head1 VERSION

This document describes version 0.001 of TableDataRole::Calendar::Date::Holiday::ID (from Perl distribution TableData-Calendar-Date-Holiday-ID), released on 2023-04-19.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Calendar::Date::Holiday::ID;

 my $td = TableData::Calendar::Date::Holiday::ID->new;

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
 % tabledata Calendar::Date::Holiday::ID --page

 # Get number of rows
 % tabledata --action count_rows Calendar::Date::Holiday::ID

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 DESCRIPTION

This table gets its data dynamically by querying
L<Calendar::Indonesia::Holiday>, so this is basically just a L<TableData>
interface for C<Calendar::Indonesia::Holiday>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Calendar-Date-Holiday-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Calendar-Date-Holiday-ID>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Calendar-Date-Holiday-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
