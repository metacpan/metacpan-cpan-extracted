package ## no critic: Modules::RequireFilenameMatchesPackage
    TableDataRole::Health::Nutrient0; # hide from PAUSE indexer

use strict;
use utf8;

use Role::Tiny;
with 'TableDataRole::Source::AOH';

our $table_def = {
    fields => {
        symbol   => {pos=>0, schema=>'str*'},
        aliases  => {pos=>1, schema=>'str*'}, # alternate symbols, comma-separated
        summary  => {pos=>2, schema=>'str'},

        category => {pos=>3, schema=>['str*', in=>[
            'vitamin',
            'mineral',
            'essential nutrient',
            'macronutrient',
            'fatty acid',
            'amino acid',
            'sugar',
            'other',
        ]]},

        eng_name    => {pos=>4, schema=>'str*'},
        eng_aliases => {pos=>5, schema=>'aos'},
        ind_name    => {pos=>6, schema=>'str*'},
        ind_aliases => {pos=>7, schema=>'aos'},

        default_unit => {pos=>8, schema=>'str*'},

        water_soluble      => {pos=> 9, schema=>'bool'},
        water_soluble_note => {pos=>10, schema=>'str'},
        fat_soluble        => {pos=>11, schema=>'bool'},
        fat_soluble_note   => {pos=>12, schema=>'str'},
    },
    pk => 'symbol',
};

our $data = [
    # for the first row, make sure we mention all columns because
    # TableDataRole::Source::AOH uses the first row to enumerate the columns
    {
        symbol => 'VA',
        aliases => '',
        summary => undef,

        category => 'vitamin',

        eng_name => 'Vitamin A',
        eng_aliases => undef,
        ind_name => 'Vitamin A',
        ind_aliases => undef,

        default_unit => 'IU-vita',

        fat_soluble => 1,
        fat_soluble_note => undef,
        water_soluble => undef,
        water_soluble_note => undef,

    },
    {
        symbol => 'VD',
        eng_name => 'Vitamin D',
        ind_name => 'Vitamin D',
        category => 'vitamin',
        default_unit => 'IU-vitd',
        fat_soluble => 1,
    },
    {
        symbol => 'VE',
        eng_name => 'Vitamin E',
        ind_name => 'Vitamin E',
        category => 'vitamin',
        default_unit => 'IU-vite',
        fat_soluble => 1,
    },
    {
        symbol => 'VK',
        eng_name => 'Vitamin K',
        ind_name => 'Vitamin K',
        category => 'vitamin',
        default_unit => 'mcg',
        fat_soluble => 1,
    },
    {
        symbol => 'VB1',
        aliases => 'Thiamine',
        eng_name => 'Vitamin B1',
        eng_aliases => ['Thiamine'],
        ind_name => 'Vitamin B1',
        ind_aliases => ['Thiamin'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB2',
        aliases => 'Riboflavin',
        eng_name => 'Vitamin B2',
        eng_aliases => ['Riboflavin'],
        ind_name => 'Vitamin B2',
        ind_aliases => ['Riboflavin'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB3',
        aliases => 'Niacin',
        eng_name => 'Vitamin B3',
        eng_aliases => ['Niacin'],
        ind_name => 'Vitamin B3',
        ind_aliases => ['Niacin'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB5',
        aliases => 'Pantothenic_Acid',
        eng_name => 'Pantothenic acid',
        eng_aliases => ['Vitamin B5'],
        ind_name => 'Asam pantotenat',
        ind_aliases => ['Vitamin B5'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB6',
        aliases => 'Pyridoxine',
        summary => 'Vitamin B6 refers to a group of six vitamers, one of which is pyridoxine',
        eng_name => 'Vitamin B6',
        eng_aliases => ['Pyridoxine'],
        ind_name => 'Vitamin B6',
        ind_aliases => ['Pyridoxine'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB9',
        aliases => 'Folate',
        eng_name => 'Folate',
        eng_aliases => ['Vitamin B9', 'Folacin'],
        ind_name => 'Folat',
        ind_aliases => ['Vitamin B9', 'Folasin'],
        category => 'vitamin',
        default_unit => 'mcg',
        water_soluble => 1,
    },
    {
        symbol => 'VB12',
        aliases => 'Cobalamin',
        eng_name => 'Vitamin B12',
        eng_aliases => ['Cobalamin'],
        ind_name => 'Vitamin B12',
        ind_aliases => ['Kobalamin'],
        category => 'vitamin',
        default_unit => 'mcg',
        water_soluble => 1,
    },
    {
        symbol => 'VB7',
        aliases => 'Biotin',
        eng_name => 'Biotin',
        eng_aliases => ['Vitamin B7', 'Vitamin H'],
        ind_name => 'Biotin',
        ind_aliases => ['Vitamin B7', 'Vitamin H'],
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB4',
        aliases => 'Choline',
        eng_name => 'Choline',
        eng_aliases => ['Vitamin B4'],
        ind_name => 'Kolin',
        ind_aliases => ['Vitamin B4'],
        category => 'essential nutrient',
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VC',
        eng_name => 'Vitamin C',
        ind_name => 'Vitamin C',
        category => 'vitamin',
        default_unit => 'mg',
        water_soluble => 1,
    },

    # minerals

    {
        symbol => 'Ca',
        eng_name => 'Calcium',
        ind_name => 'Kalsium',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'P',
        eng_name => 'Phosphorus',
        ind_name => 'Fosfor',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Mg',
        eng_name => 'Magnesium',
        ind_name => 'Magnesium',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Fe',
        eng_name => 'Iron',
        ind_name => 'Besi',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'I',
        eng_name => 'Iodium',
        ind_name => 'Iodium',
        category => 'mineral',
        default_unit => 'mcg',
    },
    {
        symbol => 'Zn',
        eng_name => 'Zinc',
        ind_name => 'Seng',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Se',
        eng_name => 'Selenium',
        ind_name => 'Selenium',
        category => 'mineral',
        default_unit => 'mcg',
    },
    {
        symbol => 'Mn',
        eng_name => 'Mangan',
        ind_name => 'Mangan',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'F',
        eng_name => 'Fluorine',
        ind_name => 'Fluor',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Cr',
        eng_name => 'Chromium',
        ind_name => 'Kromium',
        category => 'mineral',
        default_unit => 'mcg',
    },
    {
        symbol => 'K',
        eng_name => 'Potassium',
        ind_name => 'Kalium',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Na',
        eng_name => 'Sodium',
        ind_name => 'Natrium',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Cl',
        eng_name => 'Chlorine',
        ind_name => 'Klor',
        category => 'mineral',
        default_unit => 'mg',
    },
    {
        symbol => 'Cu',
        eng_name => 'Copper',
        ind_name => 'Tembaga',
        category => 'mineral',
        default_unit => 'mcg',
    },

    {
        symbol => 'Energy',
        eng_name => 'Energy',
        ind_name => 'Energi',
        category => 'energy',
        default_unit => 'kcal',
    },
    {
        symbol => 'Protein',
        eng_name => 'Protein',
        ind_name => 'Protein',
        category => 'macronutrient',
        default_unit => 'g',
    },
    {
        symbol => 'Total_Fat',
        eng_name => 'Total fat',
        ind_name => 'Lemak total',
        category => 'macronutrient',
        default_unit => 'g',
    },
    {
        symbol => 'Saturated_Fat',
        eng_name => 'Saturated fat',
        ind_name => 'Lemak jenuh',
        category => 'macronutrient',
        default_unit => 'g',
    },
    {
        symbol => 'Cholesterol',
        eng_name => 'Cholesterol',
        ind_name => 'Kolesterol',
        category => 'other',
        default_unit => 'mg',
    },
    {
        symbol => 'Linoleic_Acid',
        eng_name => 'Linoleic acid',
        ind_name => 'Asam linoleat',
        category => 'fatty acid',
        default_unit => 'g',
    },
    {
        symbol => 'Omega6',
        eng_name => 'Omega-6 fatty acids',
        ind_name => 'Asam lemak omega-6',
        category => 'fatty acid',
        default_unit => 'g',
    },
    {
        symbol => 'Alpha_Linolenic_Acid',
        eng_name => 'ɑ-linolenic acid',
        ind_name => 'Asam ɑ-linolenat',
        category => 'fatty acid',
        default_unit => 'g',
    },
    {
        symbol => 'Omega3',
        eng_name => 'Omega-3 fatty acids',
        ind_name => 'Asam lemak omega-3',
        category => 'fatty acid',
        default_unit => 'g',
    },
    {
        symbol => 'Carbohydrate',
        eng_name => 'Total carbohydrate',
        ind_name => 'Karbohidrat total',
        category => 'macronutrient',
        default_unit => 'g',
    },
    {
        symbol => 'Dietary_Fiber',
        eng_name => 'Dietary fiber',
        ind_name => 'Serat pangan',
        category => 'other',
        default_unit => 'g',
    },
    {
        symbol => 'L_Carnitine',
        eng_name => 'L-Carnitine',
        ind_name => 'L-Karnitin',
        category => 'amino acid',
        default_unit => 'mg',
    },
    {
        symbol => 'Myo_Inositol',
        eng_name => 'Myo-Inositol',
        ind_name => 'Myo-Inositol',
        category => 'sugar',
        default_unit => 'mg',
    },
];

around new => sub {
    my $orig = shift;

    $orig->(
        @_,
        aoh => $data,
        column_names => [
            sort { $table_def->{fields}{$a}{pos} <=> $table_def->{fields}{$b}{pos} }
            keys %{ $table_def->{fields} }
        ],
    );
};

package ## no critic: Modules::RequireFilenameMatchesPackage
    TableData::Health::Nutrient0; # hide from PAUSE indexer

use strict;

use Role::Tiny::With;
with 'TableDataRole::Health::Nutrient0';

package ## no critic: Modules::RequireFilenameMatchesPackage
    TableDataRole::Health::Nutrient; # hide from PAUSE indexer

use strict;

use Role::Tiny;
with 'TableDataRole::Munge::SerializeRef';

around new => sub {
    my $orig = shift;

    $orig->(@_, tabledata=>'Health::Nutrient0', load=>0);
};

package TableData::Health::Nutrient;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Health::Nutrient';
with 'TableDataRole::Spec::TableDef';

sub get_table_def {
    $TableDataRole::Health::Nutrient0::table_def;
}

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'TableData-Health-Nutrient'; # DIST
our $VERSION = '0.004'; # VERSION

our %STATS = ("num_rows",41,"num_columns",13); # STATS

1;
# ABSTRACT: Nutrients

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Health::Nutrient0 - Nutrients

=head1 VERSION

This document describes version 0.004 of TableDataRole::Health::Nutrient0 (from Perl distribution TableData-Health-Nutrient), released on 2024-05-30.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Health::Nutrient;

 my $td = TableData::Health::Nutrient->new;

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
 % tabledata Health::Nutrient --page

 # Get number of rows
 % tabledata --action count_rows Health::Nutrient

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 13    |
 | num_rows    | 41    |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=for Pod::Coverage ^(get_table_def)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Health-Nutrient>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Health-Nutrient>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Health-Nutrient>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
