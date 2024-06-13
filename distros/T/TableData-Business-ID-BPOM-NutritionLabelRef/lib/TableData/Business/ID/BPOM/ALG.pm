package TableData::Business::ID::BPOM::ALG;

use strict;

require TableData::Business::ID::BPOM::NutritionLabelRef;

use Role::Tiny::With;
with 'TableDataRole::Business::ID::BPOM::NutritionLabelRef';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'TableData-Business-ID-BPOM-NutritionLabelRef'; # DIST
our $VERSION = '0.004'; # VERSION

our %STATS = ("num_columns",4,"num_rows",228); # STATS

1;
# ABSTRACT: Nutrients (shorter alias for TableData::Business::ID::BPOM::NutritionLabelRef)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::Business::ID::BPOM::ALG - Nutrients (shorter alias for TableData::Business::ID::BPOM::NutritionLabelRef)

=head1 VERSION

This document describes version 0.004 of TableData::Business::ID::BPOM::ALG (from Perl distribution TableData-Business-ID-BPOM-NutritionLabelRef), released on 2024-06-13.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Business::ID::BPOM::ALG;

 my $td = TableData::Business::ID::BPOM::ALG->new;

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
 % tabledata Business::ID::BPOM::ALG --page

 # Get number of rows
 % tabledata --action count_rows Business::ID::BPOM::ALG

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 DESCRIPTION

Keywords: acuan label gizi

=for Pod::Coverage ^()$

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 4     |
 | num_rows    | 228   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Business-ID-BPOM-NutritionLabelRef>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Business-ID-BPOM-NutritionLabelRef>.

=head1 SEE ALSO

L<TableData::Business::ID::BPOM::NutritionLabelRef>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Business-ID-BPOM-NutritionLabelRef>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
