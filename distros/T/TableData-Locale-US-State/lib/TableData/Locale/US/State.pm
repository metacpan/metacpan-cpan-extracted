package TableData::Locale::US::State;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-07'; # DATE
our $DIST = 'TableData-Locale-US-State'; # DIST
our $VERSION = '20230207.0.0'; # VERSION

our %STATS = ("num_rows",52,"num_columns",4); # STATS

1;
# ABSTRACT: US states

=pod

=encoding UTF-8

=head1 NAME

TableData::Locale::US::State - US states

=head1 VERSION

This document describes version 20230207.0.0 of TableData::Locale::US::State (from Perl distribution TableData-Locale-US-State), released on 2023-02-07.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Locale::US::State;

 my $td = TableData::Locale::US::State->new;

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
 % tabledata Locale::US::State --page

 # Get number of rows
 % tabledata --action count_rows Locale::US::State

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 4     |
 | num_rows    | 52    |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Locale-US-State>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Locale-US-State>.

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Locale-US-State>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
code,latitude,longitude,name
AK,63.588753,-154.493062,Alaska
AL,32.318231,-86.902298,Alabama
AR,35.20105,-91.831833,Arkansas
AZ,34.048928,-111.093731,Arizona
CA,36.778261,-119.417932,California
CO,39.550051,-105.782067,Colorado
CT,41.603221,-73.087749,Connecticut
DC,38.905985,-77.033418,District of Columbia
DE,38.910832,-75.52767,Delaware
FL,27.664827,-81.515754,Florida
GA,32.157435,-82.907123,Georgia
HI,19.898682,-155.665857,Hawaii
IA,41.878003,-93.097702,Iowa
ID,44.068202,-114.742041,Idaho
IL,40.633125,-89.398528,Illinois
IN,40.551217,-85.602364,Indiana
KS,39.011902,-98.484246,Kansas
KY,37.839333,-84.270018,Kentucky
LA,31.244823,-92.145024,Louisiana
MA,42.407211,-71.382437,Massachusetts
MD,39.045755,-76.641271,Maryland
ME,45.253783,-69.445469,Maine
MI,44.314844,-85.602364,Michigan
MN,46.729553,-94.6859,Minnesota
MO,37.964253,-91.831833,Missouri
MS,32.354668,-89.398528,Mississippi
MT,46.879682,-110.362566,Montana
NC,35.759573,-79.0193,North Carolina
ND,47.551493,-101.002012,North Dakota
NE,41.492537,-99.901813,Nebraska
NH,43.193852,-71.572395,New Hampshire
NJ,40.058324,-74.405661,New Jersey
NM,34.97273,-105.032363,New Mexico
NV,38.80261,-116.419389,Nevada
NY,43.299428,-74.217933,New York
OH,40.417287,-82.907123,Ohio
OK,35.007752,-97.092877,Oklahoma
OR,43.804133,-120.554201,Oregon
PA,41.203322,-77.194525,Pennsylvania
PR,18.220833,-66.590149,Puerto Rico
RI,41.580095,-71.477429,Rhode Island
SC,33.836081,-81.163725,South Carolina
SD,43.969515,-99.901813,South Dakota
TN,35.517491,-86.580447,Tennessee
TX,31.968599,-99.901813,Texas
UT,39.32098,-111.093731,Utah
VA,37.431573,-78.656894,Virginia
VT,44.558803,-72.577841,Vermont
WA,47.751074,-120.740139,Washington
WI,43.78444,-88.787868,Wisconsin
WV,38.597626,-80.454903,West Virginia
WY,43.075968,-107.290284,Wyoming
