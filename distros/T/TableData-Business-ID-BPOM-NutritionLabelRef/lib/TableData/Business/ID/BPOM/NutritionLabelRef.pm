package ## no critic: Modules::RequireFilenameMatchesPackage
    TableDataRole::Business::ID::BPOM::NutritionLabelRef; # hide from PAUSE indexer

use strict;

use Role::Tiny;
with 'TableDataRole::Source::AOH';

my $data = [
    # for the first row, make sure we mention all columns because
    # TableDataRole::Source::AOH uses the first row to enumerate the columns
    {group => '0to6mo', ref => 550, symbol => 'Energy', unit => 'kkal'},
    {group => '7to11mo', ref => 725, symbol => 'Energy', unit => 'kkal'},
    {group => '1to3y', ref => 1125, symbol => 'Energy', unit => 'kkal'},
    {group => 'general', ref => 2150, symbol => 'Energy', unit => 'kkal'},
    {group => 'pregnant', ref => 2510, symbol => 'Energy', unit => 'kkal'},
    {group => 'breastfeeding', ref => 2615, symbol => 'Energy', unit => 'kkal'},
    {group => '0to6mo', ref => 12, symbol => 'Protein', unit => 'g'},
    {group => '7to11mo', ref => 18, symbol => 'Protein', unit => 'g'},
    {group => '1to3y', ref => 26, symbol => 'Protein', unit => 'g'},
    {group => 'general', ref => 60, symbol => 'Protein', unit => 'g'},
    {group => 'pregnant', ref => 76, symbol => 'Protein', unit => 'g'},
    {group => 'breastfeeding', ref => 76, symbol => 'Protein', unit => 'g'},
    {group => '0to6mo', ref => 34, symbol => 'Total_Fat', unit => 'g'},
    {group => '7to11mo', ref => 36, symbol => 'Total_Fat', unit => 'g'},
    {group => '1to3y', ref => 44, symbol => 'Total_Fat', unit => 'g'},
    {group => 'general', ref => 67, symbol => 'Total_Fat', unit => 'g'},
    {group => 'pregnant', ref => 84, symbol => 'Total_Fat', unit => 'g'},
    {group => 'breastfeeding', ref => 87, symbol => 'Total_Fat', unit => 'g'},
    {group => '0to6mo', ref => undef, symbol => 'Saturated_Fat', unit => 'g'},
    {group => '7to11mo', ref => undef, symbol => 'Saturated_Fat', unit => 'g'},
    {group => '1to3y', ref => undef, symbol => 'Saturated_Fat', unit => 'g'},
    {group => 'general', ref => 20, symbol => 'Saturated_Fat', unit => 'g'},
    {group => 'pregnant', ref => 20, symbol => 'Saturated_Fat', unit => 'g'},
    {group => 'breastfeeding', ref => 20, symbol => 'Saturated_Fat', unit => 'g'},
    {group => '0to6mo', ref => undef, symbol => 'Cholesterol', unit => 'mg'},
    {group => '7to11mo', ref => undef, symbol => 'Cholesterol', unit => 'mg'},
    {group => '1to3y', ref => undef, symbol => 'Cholesterol', unit => 'mg'},
    {group => 'general', ref => '<300', symbol => 'Cholesterol', unit => 'mg'},
    {group => 'pregnant', ref => '<300', symbol => 'Cholesterol', unit => 'mg'},
    {group => 'breastfeeding', ref => '<300', symbol => 'Cholesterol', unit => 'mg'},
    {group => '0to6mo', ref => 4.4, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => '7to11mo', ref => 4.4, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => '1to3y', ref => 7, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => 'general', ref => 13, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => 'pregnant', ref => 14, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => 'breastfeeding', ref => 14, symbol => 'Linoleic_Acid', unit => 'g'},
    {group => '0to6mo', ref => 0.5, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => '7to11mo', ref => 0.5, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => '1to3y', ref => 0.7, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => 'general', ref => 1.4, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => 'pregnant', ref => 1.4, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => 'breastfeeding', ref => 1.3, symbol => 'Alpha_Linoleic_Acid', unit => 'g'},
    {group => '0to6mo', ref => 58, symbol => 'Carbohydrate', unit => 'g'},
    {group => '7to11mo', ref => 82, symbol => 'Carbohydrate', unit => 'g'},
    {group => '1to3y', ref => 155, symbol => 'Carbohydrate', unit => 'g'},
    {group => 'general', ref => 325, symbol => 'Carbohydrate', unit => 'g'},
    {group => 'pregnant', ref => 345, symbol => 'Carbohydrate', unit => 'g'},
    {group => 'breastfeeding', ref => 360, symbol => 'Carbohydrate', unit => 'g'},
    {group => '0to6mo', ref => 0, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => '7to11mo', ref => 5, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => '1to3y', ref => 16, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => 'general', ref => 30, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => 'pregnant', ref => 35, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => 'breastfeeding', ref => 38, symbol => 'Dietary_Fiber', unit => 'g'},
    {group => '0to6mo', ref => 375, symbol => 'VA', unit => 'mcg'},
    {group => '7to11mo', ref => 400, symbol => 'VA', unit => 'mcg'},
    {group => '1to3y', ref => 400, symbol => 'VA', unit => 'mcg'},
    {group => 'general', ref => 600, symbol => 'VA', unit => 'mcg'},
    {group => 'pregnant', ref => 816, symbol => 'VA', unit => 'mcg'},
    {group => 'breastfeeding', ref => 850, symbol => 'VA', unit => 'mcg'},
    {group => '0to6mo', ref => 5, symbol => 'VD', unit => 'mcg'},
    {group => '7to11mo', ref => 5, symbol => 'VD', unit => 'mcg'},
    {group => '1to3y', ref => 15, symbol => 'VD', unit => 'mcg'},
    {group => 'general', ref => 15, symbol => 'VD', unit => 'mcg'},
    {group => 'pregnant', ref => 15, symbol => 'VD', unit => 'mcg'},
    {group => 'breastfeeding', ref => 15, symbol => 'VD', unit => 'mcg'},
    {group => '0to6mo', ref => 4, symbol => 'VE', unit => 'mg'},
    {group => '7to11mo', ref => 5, symbol => 'VE', unit => 'mg'},
    {group => '1to3y', ref => 6, symbol => 'VE', unit => 'mg'},
    {group => 'general', ref => 15, symbol => 'VE', unit => 'mg'},
    {group => 'pregnant', ref => 15, symbol => 'VE', unit => 'mg'},
    {group => 'breastfeeding', ref => 19, symbol => 'VE', unit => 'mg'},
    {group => '0to6mo', ref => 5, symbol => 'VK', unit => 'mcg'},
    {group => '7to11mo', ref => 10, symbol => 'VK', unit => 'mcg'},
    {group => '1to3y', ref => 15, symbol => 'VK', unit => 'mcg'},
    {group => 'general', ref => 60, symbol => 'VK', unit => 'mcg'},
    {group => 'pregnant', ref => 55, symbol => 'VK', unit => 'mcg'},
    {group => 'breastfeeding', ref => 55, symbol => 'VK', unit => 'mcg'},
    {group => '0to6mo', ref => 0.3, symbol => 'VB1', unit => 'mg'},
    {group => '7to11mo', ref => 0.4, symbol => 'VB1', unit => 'mg'},
    {group => '1to3y', ref => 0.6, symbol => 'VB1', unit => 'mg'},
    {group => 'general', ref => 1.4, symbol => 'VB1', unit => 'mg'},
    {group => 'pregnant', ref => 1.4, symbol => 'VB1', unit => 'mg'},
    {group => 'breastfeeding', ref => 1.4, symbol => 'VB1', unit => 'mg'},
    {group => '0to6mo', ref => 0.3, symbol => 'VB2', unit => 'mg'},
    {group => '7to11mo', ref => 0.4, symbol => 'VB2', unit => 'mg'},
    {group => '1to3y', ref => 0.7, symbol => 'VB2', unit => 'mg'},
    {group => 'general', ref => 1.6, symbol => 'VB2', unit => 'mg'},
    {group => 'pregnant', ref => 1.7, symbol => 'VB2', unit => 'mg'},
    {group => 'breastfeeding', ref => 1.8, symbol => 'VB2', unit => 'mg'},
    {group => '0to6mo', ref => 2, symbol => 'VB3', unit => 'mg'},
    {group => '7to11mo', ref => 4, symbol => 'VB3', unit => 'mg'},
    {group => '1to3y', ref => 6, symbol => 'VB3', unit => 'mg'},
    {group => 'general', ref => 15, symbol => 'VB3', unit => 'mg'},
    {group => 'pregnant', ref => 16, symbol => 'VB3', unit => 'mg'},
    {group => 'breastfeeding', ref => 15, symbol => 'VB3', unit => 'mg'},
    {group => '0to6mo', ref => 1.7, symbol => 'VB5', unit => 'mg'},
    {group => '7to11mo', ref => 1.8, symbol => 'VB5', unit => 'mg'},
    {group => '1to3y', ref => 2, symbol => 'VB5', unit => 'mg'},
    {group => 'general', ref => 5, symbol => 'VB5', unit => 'mg'},
    {group => 'pregnant', ref => 6, symbol => 'VB5', unit => 'mg'},
    {group => 'breastfeeding', ref => 7, symbol => 'VB5', unit => 'mg'},
    {group => '0to6mo', ref => 0.1, symbol => 'VB6', unit => 'mg'},
    {group => '7to11mo', ref => 0.3, symbol => 'VB6', unit => 'mg'},
    {group => '1to3y', ref => 0.5, symbol => 'VB6', unit => 'mg'},
    {group => 'general', ref => 1.3, symbol => 'VB6', unit => 'mg'},
    {group => 'pregnant', ref => 1.7, symbol => 'VB6', unit => 'mg'},
    {group => 'breastfeeding', ref => 1.8, symbol => 'VB6', unit => 'mg'},
    {group => '0to6mo', ref => 65, symbol => 'VB9', unit => 'mcg'},
    {group => '7to11mo', ref => 80, symbol => 'VB9', unit => 'mcg'},
    {group => '1to3y', ref => 160, symbol => 'VB9', unit => 'mcg'},
    {group => 'general', ref => 400, symbol => 'VB9', unit => 'mcg'},
    {group => 'pregnant', ref => 600, symbol => 'VB9', unit => 'mcg'},
    {group => 'breastfeeding', ref => 500, symbol => 'VB9', unit => 'mcg'},
    {group => '0to6mo', ref => 0.4, symbol => 'VB12', unit => 'mcg'},
    {group => '7to11mo', ref => 0.5, symbol => 'VB12', unit => 'mcg'},
    {group => '1to3y', ref => 0.9, symbol => 'VB12', unit => 'mcg'},
    {group => 'general', ref => 2.4, symbol => 'VB12', unit => 'mcg'},
    {group => 'pregnant', ref => 2.6, symbol => 'VB12', unit => 'mcg'},
    {group => 'breastfeeding', ref => 2.8, symbol => 'VB12', unit => 'mcg'},
    {group => '0to6mo', ref => 5, symbol => 'Biotin', unit => 'mcg'},
    {group => '7to11mo', ref => 6, symbol => 'Biotin', unit => 'mcg'},
    {group => '1to3y', ref => 8, symbol => 'Biotin', unit => 'mcg'},
    {group => 'general', ref => 30, symbol => 'Biotin', unit => 'mcg'},
    {group => 'pregnant', ref => 30, symbol => 'Biotin', unit => 'mcg'},
    {group => 'breastfeeding', ref => 35, symbol => 'Biotin', unit => 'mcg'},
    {group => '0to6mo', ref => 125, symbol => 'Choline', unit => 'mg'},
    {group => '7to11mo', ref => 150, symbol => 'Choline', unit => 'mg'},
    {group => '1to3y', ref => 200, symbol => 'Choline', unit => 'mg'},
    {group => 'general', ref => 450, symbol => 'Choline', unit => 'mg'},
    {group => 'pregnant', ref => 450, symbol => 'Choline', unit => 'mg'},
    {group => 'breastfeeding', ref => 500, symbol => 'Choline', unit => 'mg'},
    {group => '0to6mo', ref => 40, symbol => 'VC', unit => 'mg'},
    {group => '7to11mo', ref => 50, symbol => 'VC', unit => 'mg'},
    {group => '1to3y', ref => 40, symbol => 'VC', unit => 'mg'},
    {group => 'general', ref => 90, symbol => 'VC', unit => 'mg'},
    {group => 'pregnant', ref => 90, symbol => 'VC', unit => 'mg'},
    {group => 'breastfeeding', ref => 100, symbol => 'VC', unit => 'mg'},
    {group => '0to6mo', ref => 200, symbol => 'Ca', unit => 'mg'},
    {group => '7to11mo', ref => 250, symbol => 'Ca', unit => 'mg'},
    {group => '1to3y', ref => 650, symbol => 'Ca', unit => 'mg'},
    {group => 'general', ref => 1100, symbol => 'Ca', unit => 'mg'},
    {group => 'pregnant', ref => 1300, symbol => 'Ca', unit => 'mg'},
    {group => 'breastfeeding', ref => 1300, symbol => 'Ca', unit => 'mg'},
    {group => '0to6mo', ref => 100, symbol => 'P', unit => 'mg'},
    {group => '7to11mo', ref => 250, symbol => 'P', unit => 'mg'},
    {group => '1to3y', ref => 500, symbol => 'P', unit => 'mg'},
    {group => 'general', ref => 700, symbol => 'P', unit => 'mg'},
    {group => 'pregnant', ref => 700, symbol => 'P', unit => 'mg'},
    {group => 'breastfeeding', ref => 700, symbol => 'P', unit => 'mg'},
    {group => '0to6mo', ref => 30, symbol => 'Mg', unit => 'mg'},
    {group => '7to11mo', ref => 55, symbol => 'Mg', unit => 'mg'},
    {group => '1to3y', ref => 60, symbol => 'Mg', unit => 'mg'},
    {group => 'general', ref => 350, symbol => 'Mg', unit => 'mg'},
    {group => 'pregnant', ref => 350, symbol => 'Mg', unit => 'mg'},
    {group => 'breastfeeding', ref => 310, symbol => 'Mg', unit => 'mg'},
    {group => '0to6mo', ref => 120, symbol => 'Na', unit => 'mg'},
    {group => '7to11mo', ref => 200, symbol => 'Na', unit => 'mg'},
    {group => '1to3y', ref => 1000, symbol => 'Na', unit => 'mg'},
    {group => 'general', ref => 1500, symbol => 'Na', unit => 'mg'},
    {group => 'pregnant', ref => 1500, symbol => 'Na', unit => 'mg'},
    {group => 'breastfeeding', ref => 1500, symbol => 'Na', unit => 'mg'},
    {group => '0to6mo', ref => 500, symbol => 'K', unit => 'mg'},
    {group => '7to11mo', ref => 700, symbol => 'K', unit => 'mg'},
    {group => '1to3y', ref => 3000, symbol => 'K', unit => 'mg'},
    {group => 'general', ref => 4700, symbol => 'K', unit => 'mg'},
    {group => 'pregnant', ref => 4700, symbol => 'K', unit => 'mg'},
    {group => 'breastfeeding', ref => 5100, symbol => 'K', unit => 'mg'},
    {group => '0to6mo', ref => 5.5, symbol => 'Mn', unit => 'mcg'},
    {group => '7to11mo', ref => 600, symbol => 'Mn', unit => 'mcg'},
    {group => '1to3y', ref => 1200, symbol => 'Mn', unit => 'mcg'},
    {group => 'general', ref => 2000, symbol => 'Mn', unit => 'mcg'},
    {group => 'pregnant', ref => 2000, symbol => 'Mn', unit => 'mcg'},
    {group => 'breastfeeding', ref => 2600, symbol => 'Mn', unit => 'mcg'},
    {group => '0to6mo', ref => 200, symbol => 'Cu', unit => 'mcg'},
    {group => '7to11mo', ref => 220, symbol => 'Cu', unit => 'mcg'},
    {group => '1to3y', ref => 340, symbol => 'Cu', unit => 'mcg'},
    {group => 'general', ref => 800, symbol => 'Cu', unit => 'mcg'},
    {group => 'pregnant', ref => 1000, symbol => 'Cu', unit => 'mcg'},
    {group => 'breastfeeding', ref => 1300, symbol => 'Cu', unit => 'mcg'},
    {group => '0to6mo', ref => undef, symbol => 'Cr', unit => 'mcg'},
    {group => '7to11mo', ref => 6, symbol => 'Cr', unit => 'mcg'},
    {group => '1to3y', ref => 11, symbol => 'Cr', unit => 'mcg'},
    {group => 'general', ref => 26, symbol => 'Cr', unit => 'mcg'},
    {group => 'pregnant', ref => 30, symbol => 'Cr', unit => 'mcg'},
    {group => 'breastfeeding', ref => 45, symbol => 'Cr', unit => 'mcg'},
    {group => '0to6mo', ref => 2.5, symbol => 'Fe', unit => 'mg'},
    {group => '7to11mo', ref => 7, symbol => 'Fe', unit => 'mg'},
    {group => '1to3y', ref => 8, symbol => 'Fe', unit => 'mg'},
    {group => 'general', ref => 22, symbol => 'Fe', unit => 'mg'},
    {group => 'pregnant', ref => 34, symbol => 'Fe', unit => 'mg'},
    {group => 'breastfeeding', ref => 33, symbol => 'Fe', unit => 'mg'},
    {group => '0to6mo', ref => 90, symbol => 'I', unit => 'mcg'},
    {group => '7to11mo', ref => 120, symbol => 'I', unit => 'mcg'},
    {group => '1to3y', ref => 120, symbol => 'I', unit => 'mcg'},
    {group => 'general', ref => 150, symbol => 'I', unit => 'mcg'},
    {group => 'pregnant', ref => 220, symbol => 'I', unit => 'mcg'},
    {group => 'breastfeeding', ref => 250, symbol => 'I', unit => 'mcg'},
    {group => '0to6mo', ref => 2.75, symbol => 'Zn', unit => 'mg'},
    {group => '7to11mo', ref => 3, symbol => 'Zn', unit => 'mg'},
    {group => '1to3y', ref => 4, symbol => 'Zn', unit => 'mg'},
    {group => 'general', ref => 13, symbol => 'Zn', unit => 'mg'},
    {group => 'pregnant', ref => 16, symbol => 'Zn', unit => 'mg'},
    {group => 'breastfeeding', ref => 15, symbol => 'Zn', unit => 'mg'},
    {group => '0to6mo', ref => 5, symbol => 'Se', unit => 'mcg'},
    {group => '7to11mo', ref => 10, symbol => 'Se', unit => 'mcg'},
    {group => '1to3y', ref => 17, symbol => 'Se', unit => 'mcg'},
    {group => 'general', ref => 30, symbol => 'Se', unit => 'mcg'},
    {group => 'pregnant', ref => 35, symbol => 'Se', unit => 'mcg'},
    {group => 'breastfeeding', ref => 40, symbol => 'Se', unit => 'mcg'},
    {group => '0to6mo', ref => undef, symbol => 'F', unit => 'mg'},
    {group => '7to11mo', ref => 0.4, symbol => 'F', unit => 'mg'},
    {group => '1to3y', ref => 0.6, symbol => 'F', unit => 'mg'},
    {group => 'general', ref => 2.5, symbol => 'F', unit => 'mg'},
    {group => 'pregnant', ref => 2.5, symbol => 'F', unit => 'mg'},
    {group => 'breastfeeding', ref => 2.5, symbol => 'F', unit => 'mg'},
    {group => '0to6mo', ref => 6.6, symbol => 'L_Carnitine', unit => 'mg'},
    {group => '7to11mo', ref => 8.7, symbol => 'L_Carnitine', unit => 'mg'},
    {group => '1to3y', ref => 13.5, symbol => 'L_Carnitine', unit => 'mg'},
    {group => 'general', ref => undef, symbol => 'L_Carnitine', unit => 'mg'},
    {group => 'pregnant', ref => undef, symbol => 'L_Carnitine', unit => 'mg'},
    {group => 'breastfeeding', ref => undef, symbol => 'L_Carnitine', unit => 'mg'},
    {group => '0to6mo', ref => 22, symbol => 'Myo_Inositol', unit => 'mg'},
    {group => '7to11mo', ref => 29, symbol => 'Myo_Inositol', unit => 'mg'},
    {group => '1to3y', ref => 45, symbol => 'Myo_Inositol', unit => 'mg'},
    {group => 'general', ref => undef, symbol => 'Myo_Inositol', unit => 'mg'},
    {group => 'pregnant', ref => undef, symbol => 'Myo_Inositol', unit => 'mg'},
    {group => 'breastfeeding', ref => undef, symbol => 'Myo_Inositol', unit => 'mg'},
];

around new => sub {
    my $orig = shift;

    $orig->(@_, aoh => $data);
};

package TableData::Business::ID::BPOM::NutritionLabelRef; # hide from PAUSE indexer

use strict;

use Role::Tiny::With;
with 'TableDataRole::Business::ID::BPOM::NutritionLabelRef';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'TableData-Business-ID-BPOM-NutritionLabelRef'; # DIST
our $VERSION = '0.005'; # VERSION

our %STATS = ("num_columns",4,"num_rows",228); # STATS

1;
# ABSTRACT: BPOM's nutrition label reference (ALG, acuan label gizi)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Business::ID::BPOM::NutritionLabelRef - BPOM's nutrition label reference (ALG, acuan label gizi)

=head1 VERSION

This document describes version 0.005 of TableDataRole::Business::ID::BPOM::NutritionLabelRef (from Perl distribution TableData-Business-ID-BPOM-NutritionLabelRef), released on 2024-06-13.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Business::ID::BPOM::NutritionLabelRef;

 my $td = TableData::Business::ID::BPOM::NutritionLabelRef->new;

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
 % tabledata Business::ID::BPOM::NutritionLabelRef --page

 # Get number of rows
 % tabledata --action count_rows Business::ID::BPOM::NutritionLabelRef

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 4     |
 | num_rows    | 228   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=for Pod::Coverage ^(get_table_def)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Business-ID-BPOM-NutritionLabelRef>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Business-ID-BPOM-NutritionLabelRef>.

=head1 SEE ALSO

BPOM regulation 9/2016 on Nutrition Label Reference ("acuan label gizi"),
L<https://tabel-gizi.pom.go.id/regulasi/4_Peraturan_Kepala_BPOM_Nomor_9_Tahun_2016_tentang_Acuan_Label_Gizi.pdf>

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
