package ## no critic: Modules::RequireFilenameMatchesPackage
    # hide from PAUSE
    TableDataRole::Business::ID::BPOM::FoodCategory;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
with 'TableDataRole::Source::AOA';

around new => sub {
    require App::BPOMUtils::Table::FoodCategory;

    my $orig = shift;
    my $self = shift;

    $orig->(
        $self,
        column_names => [ sort {
            $App::BPOMUtils::Table::FoodCategory::meta_idn_bpom_kategori_pangan->{fields}{$a}{pos} <=>
            $App::BPOMUtils::Table::FoodCategory::meta_idn_bpom_kategori_pangan->{fields}{$b}{pos};
        } keys %{ $App::BPOMUtils::Table::FoodCategory::meta_idn_bpom_kategori_pangan->{fields} } ],
        aoa => $App::BPOMUtils::Table::FoodCategory::data_idn_bpom_kategori_pangan,
        @_,
    );
};

package TableData::Business::ID::BPOM::FoodCategory;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-07'; # DATE
our $DIST = 'TableDataBundle-Business-ID-BPOM'; # DIST
our $VERSION = '20230207.0.0'; # VERSION

with 'TableDataRole::Business::ID::BPOM::FoodCategory';

our %STATS = ("num_rows",1959,"num_columns",4); # STATS

1;
# ABSTRACT: Food categories in BPOM processed food division

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Business::ID::BPOM::FoodCategory - Food categories in BPOM processed food division

=head1 VERSION

This document describes version 20230207.0.0 of TableDataRole::Business::ID::BPOM::FoodCategory (from Perl distribution TableDataBundle-Business-ID-BPOM), released on 2023-02-07.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Business::ID::BPOM::FoodCategory;

 my $td = TableData::Business::ID::BPOM::FoodCategory->new;

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
 % tabledata Business::ID::BPOM::FoodCategory --page

 # Get number of rows
 % tabledata --action count_rows Business::ID::BPOM::FoodCategory

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 DESCRIPTION

Keyword: BPOM, pangan olahan, kategori pangan

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 4     |
 | num_rows    | 1959  |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Business-ID-BPOM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Business-ID-BPOM>.

=head1 SEE ALSO

L<TableData::Business::ID::BPOM::FoodType>

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

This software is copyright (c) 2023, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Business-ID-BPOM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
