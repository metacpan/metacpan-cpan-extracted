package ## no critic: Modules::RequireFilenameMatchesPackage
    TableDataRole::Health::Nutrient0; # hide from PAUSE indexer

use strict;
use utf8;

use Role::Tiny;
with 'TableDataRole::Source::AOH';

our $table_def = {
    fields => {
        symbol   => {pos=>0, schema=>'str*'},
        aliases  => {pos=>1, schema=>'aos'}, # alternate symbols
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
        aliases => undef,
        summary => 'Vitamin A',
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
        aliases => undef,
        summary => 'Vitamin D',
        category => 'vitamin',
        eng_name => 'Vitamin D',
        ind_name => 'Vitamin D',
        default_unit => 'IU-vitd',
        fat_soluble => 1,
    },
    {
        symbol => 'VE',
        aliases => undef,
        summary => 'Vitamin E',
        category => 'vitamin',

        eng_name => 'Vitamin E',
        ind_name => 'Vitamin E',
        default_unit => 'IU-vite',
        fat_soluble => 1,
    },
    {
        symbol => 'VK',
        aliases => undef,
        summary => 'Vitamin K',
        category => 'vitamin',

        eng_name => 'Vitamin K',
        ind_name => 'Vitamin K',
        category => 'vitamin',
        default_unit => 'mcg',
        fat_soluble => 1,
    },
    {
        symbol => 'VB1',
        aliases => ['Thiamine'],
        summary => 'Vitamin B1 (Thiamine)',
        category => 'vitamin',

        eng_name => 'Vitamin B1',
        eng_aliases => ['Thiamine'],
        ind_name => 'Vitamin B1',
        ind_aliases => ['Thiamin'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB2',
        aliases => ['Riboflavin'],
        summary => 'Vitamin B2 (Riboflavin)',
        category => 'vitamin',

        eng_name => 'Vitamin B2',
        eng_aliases => ['Riboflavin'],
        ind_name => 'Vitamin B2',
        ind_aliases => ['Riboflavin'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB3',
        aliases => ['Niacin'],
        summary => 'Vitamin B3 (Niacin)',
        category => 'vitamin',

        eng_name => 'Vitamin B3',
        eng_aliases => ['Niacin', 'Vitamin PP'],
        ind_name => 'Vitamin B3',
        ind_aliases => ['Niasin'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB5',
        aliases => ['Pantothenic_Acid'],
        summary => 'Vitamin B5 (Pantothenic Acid)',
        category => 'vitamin',

        eng_name => 'Pantothenic acid',
        eng_aliases => ['Vitamin B5'],
        ind_name => 'Asam pantotenat',
        ind_aliases => ['Vitamin B5'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB6',
        aliases => ['Pyridoxine'],
        summary => 'Vitamin B6 refers to a group of six vitamers, one of which is pyridoxine',
        category => 'vitamin',

        eng_name => 'Vitamin B6',
        eng_aliases => ['Pyridoxine'],
        ind_name => 'Vitamin B6',
        ind_aliases => ['Piridoksin'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VB9',
        aliases => ['Folate'],
        summary => 'Vitamin B9 (Folate)',
        category => 'vitamin',

        eng_name => 'Folate',
        eng_aliases => ['Vitamin B9', 'Folacin'],
        ind_name => 'Folat',
        ind_aliases => ['Vitamin B9', 'Folasin'],
        default_unit => 'mcg',
        water_soluble => 1,
    },
    {
        symbol => 'VB12',
        aliases => ['Cobalamin'],
        summary => 'Vitamin B12 (Cobalamin)',
        category => 'vitamin',

        eng_name => 'Vitamin B12',
        eng_aliases => ['Cobalamin'],
        ind_name => 'Vitamin B12',
        ind_aliases => ['Kobalamin'],
        default_unit => 'mcg',
        water_soluble => 1,
    },
    {
        symbol => 'Biotin',
        aliases => ['VB7'],
        summary => 'Biotin (Vitamin B7)',
        category => 'vitamin',

        eng_name => 'Biotin',
        eng_aliases => ['Vitamin B7', 'Vitamin H'],
        ind_name => 'Biotin',
        ind_aliases => ['Vitamin B7', 'Vitamin H'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'Choline',
        aliases => ['VB4'],
        summary => 'Choline (Vitamin B4)',
        category => 'essential nutrient',

        eng_name => 'Choline',
        eng_aliases => ['Vitamin B4'],
        ind_name => 'Kolin',
        ind_aliases => ['Vitamin B4'],
        default_unit => 'mg',
        water_soluble => 1,
    },
    {
        symbol => 'VC',
        aliases => undef,
        summary => 'Vitamin C',
        category => 'vitamin',

        eng_name => 'Vitamin C',
        ind_name => 'Vitamin C',
        default_unit => 'mg',
        water_soluble => 1,
    },

    # minerals

    {
        symbol => 'Ca',
        aliases => undef,
        summary => 'Calcium',
        category => 'mineral',

        eng_name => 'Calcium',
        ind_name => 'Kalsium',
        default_unit => 'mg',
    },
    {
        symbol => 'P',
        aliases => undef,
        summary => 'Phosphorus',
        category => 'mineral',

        eng_name => 'Phosphorus',
        ind_name => 'Fosfor',
        default_unit => 'mg',
    },
    {
        symbol => 'Mg',
        aliases => undef,
        summary => 'Magnesium',
        category => 'mineral',

        eng_name => 'Magnesium',
        ind_name => 'Magnesium',
        default_unit => 'mg',
    },
    {
        symbol => 'Fe',
        aliases => undef,
        summary => 'Iron',
        category => 'mineral',

        eng_name => 'Iron',
        ind_name => 'Besi',
        default_unit => 'mg',
    },
    {
        symbol => 'I',
        aliases => undef,
        summary => 'Iodium',
        category => 'mineral',

        eng_name => 'Iodium',
        ind_name => 'Iodium',
        default_unit => 'mcg',
    },
    {
        symbol => 'Zn',
        aliases => undef,
        summary => 'Zinc',
        category => 'mineral',

        eng_name => 'Zinc',
        ind_name => 'Seng',
        default_unit => 'mg',
    },
    {
        symbol => 'Se',
        aliases => undef,
        summary => 'Selenium',
        category => 'mineral',

        eng_name => 'Selenium',
        ind_name => 'Selenium',
        default_unit => 'mcg',
    },
    {
        symbol => 'Mn',
        aliases => undef,
        summary => 'Mangan',
        category => 'mineral',

        eng_name => 'Mangan',
        ind_name => 'Mangan',
        default_unit => 'mg',
    },
    {
        symbol => 'F',
        aliases => undef,
        summary => 'Fluorine',
        category => 'mineral',

        eng_name => 'Fluorine',
        ind_name => 'Fluor',
        default_unit => 'mg',
    },
    {
        symbol => 'Cr',
        aliases => undef,
        summary => 'Chromium',
        category => 'mineral',

        eng_name => 'Chromium',
        ind_name => 'Kromium',
        default_unit => 'mcg',
    },
    {
        symbol => 'K',
        aliases => undef,
        summary => 'Potassium',
        category => 'mineral',

        eng_name => 'Potassium',
        ind_name => 'Kalium',
        default_unit => 'mg',
    },
    {
        symbol => 'Na',
        aliases => undef,
        summary => 'Sodium',
        category => 'mineral',

        eng_name => 'Sodium',
        ind_name => 'Natrium',
        default_unit => 'mg',
    },
    {
        symbol => 'Cl',
        aliases => undef,
        summary => 'Chlorine',
        category => 'mineral',

        eng_name => 'Chlorine',
        ind_name => 'Klor',
        default_unit => 'mg',
    },
    {
        symbol => 'Cu',
        aliases => undef,
        summary => 'Copper',
        category => 'mineral',

        eng_name => 'Copper',
        ind_name => 'Tembaga',
        default_unit => 'mcg',
    },
    {
        symbol => 'B',
        aliases => undef,
        summary => 'Boron',
        category => 'mineral',

        eng_name => 'Boron',
        ind_name => 'Boron',
        default_unit => 'mg',
    },
    {
        symbol => 'Mo',
        aliases => undef,
        summary => 'Molybdenum',
        category => 'mineral',

        eng_name => 'Molybdenum',
        ind_name => 'Molibdenum',
        default_unit => 'mcg',
    },
    {
        symbol => 'V',
        aliases => undef,
        summary => 'Vanadium',
        category => 'mineral',
        eng_name => 'Vanadium',
        ind_name => 'Vanadium',
        default_unit => 'mcg',
    },

    # other
    {
        symbol => 'Energy',
        aliases => undef,
        summary => 'Energy',
        category => 'energy',

        eng_name => 'Energy',
        ind_name => 'Energi',
        default_unit => 'kcal',
    },
    {
        symbol => 'Protein',
        aliases => undef,
        summary => 'Protein',
        category => 'macronutrient',

        eng_name => 'Protein',
        ind_name => 'Protein',
        default_unit => 'g',
    },
    {
        symbol => 'Total_Fat',
        aliases => undef,
        summary => 'Fat (total)',
        category => 'macronutrient',

        eng_name => 'Total fat',
        ind_name => 'Lemak total',
        default_unit => 'g',
    },
    {
        symbol => 'Saturated_Fat',
        aliases => undef,
        summary => 'Fat (saturated)',
        category => 'macronutrient',

        eng_name => 'Saturated fat',
        ind_name => 'Lemak jenuh',
        default_unit => 'g',
    },
    {
        symbol => 'Cholesterol',
        aliases => undef,
        summary => 'Cholesterol',
        category => 'other',

        eng_name => 'Cholesterol',
        ind_name => 'Kolesterol',
        default_unit => 'mg',
    },
    {
        symbol => 'Linoleic_Acid',
        aliases => undef,
        summary => 'Linoleic acid (LA)',
        category => 'fatty acid',

        eng_name => 'Linoleic acid',
        ind_name => 'Asam linoleat',
        default_unit => 'g',
    },
    {
        symbol => 'Omega6',
        aliases => undef,
        summary => 'Omega-6 fatty acids',
        category => 'fatty acid',

        eng_name => 'Omega-6 fatty acids',
        ind_name => 'Asam lemak omega-6',
        default_unit => 'g',
    },
    {
        symbol => 'Alpha_Linolenic_Acid',
        aliases => undef,
        summary => 'ɑ-linolenic acid (ALA)',
        category => 'fatty acid',

        eng_name => 'ɑ-linolenic acid',
        ind_name => 'Asam ɑ-linolenat',
        default_unit => 'g',
    },
    {
        symbol => 'Omega3',
        aliases => undef,
        summary => 'Omega-3 fatty acids',
        category => 'fatty acid',

        eng_name => 'Omega-3 fatty acids',
        ind_name => 'Asam lemak omega-3',
        default_unit => 'g',
    },
    {
        symbol => 'Carbohydrate',
        aliases => undef,
        summary => 'Carbohydrate (total)',
        category => 'macronutrient',

        eng_name => 'Total carbohydrate',
        ind_name => 'Karbohidrat total',
        default_unit => 'g',
    },
    {
        symbol => 'Dietary_Fiber',
        aliases => undef,
        summary => 'Dietary fiber',
        category => 'other',

        eng_name => 'Dietary fiber',
        ind_name => 'Serat pangan',
        default_unit => 'g',
    },
    {
        symbol => 'L_Carnitine',
        aliases => undef,
        summary => 'L-Carnitine',
        category => 'amino acid',

        eng_name => 'L-Carnitine',
        ind_name => 'L-Karnitin',
        default_unit => 'mg',
    },
    {
        symbol => 'Myo_Inositol',
        aliases => undef,
        summary => 'Myo-Inositol',
        category => 'sugar',

        eng_name => 'Myo-Inositol',
        ind_name => 'Myo-Inositol',
        default_unit => 'mg',
    },
    {
        symbol => 'H2O',
        aliases => ['Water'],
        summary => 'Water',
        category => 'other',

        eng_name => 'Water',
        ind_name => 'Air',
        default_unit => 'ml',
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
with 'TableDataRole::Health::Nutrient0';
with 'TableDataRole::Spec::TableDef';

sub get_table_def {
    $TableDataRole::Health::Nutrient0::table_def;
}

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-11-03'; # DATE
our $DIST = 'TableData-Health-Nutrient'; # DIST
our $VERSION = '0.006'; # VERSION

our %STATS = ("num_columns",13,"num_rows",45); # STATS

1;
# ABSTRACT: Nutrients

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Health::Nutrient0 - Nutrients

=head1 VERSION

This document describes version 0.006 of TableDataRole::Health::Nutrient0 (from Perl distribution TableData-Health-Nutrient), released on 2025-11-03.

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
 | num_rows    | 45    |
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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Health-Nutrient>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
