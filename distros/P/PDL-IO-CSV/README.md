# NAME

PDL::IO::CSV - Load/save PDL from/to CSV file (optimized for speed and large data)

# SYNOPSIS

    use PDL;
    use PDL::IO::CSV ':all';

    my $pdl = rcsv2D('input.csv');
    $pdl *= 2;
    wcsv2D($pdl, 'double.csv');

    my ($pdl1, $pdl2, $pdl3) = rcsv1D('input.csv', [0, 1, 6]);
    wcsv1D($pdl1, 'col2.csv');
    #or
    $pdl2->wcsv1D('col2.csv');
    $pdl2->wcsv1D('col2_tabs.csv', {sep_char=>"\t"});

# DESCRIPTION

The traditional way of creating PDL piddle from CSV data is via [rcols](https://metacpan.org/pod/PDL::IO::Misc#rcols) function.

    my $pdl = rcols("data.csv", [1..4], { DEFTYPE=>double, COLSEP=>"," });

This module provides alternative implementation based on [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS) which should be significantly faster than
traditional approach.

PDL::IO::CSV supports reading CSV data and creating PDL piddle(s) as well as saving PDL data to CSV file.

# FUNCTIONS

By default, PDL::IO::CSV doesn't import any function. You can import individual functions like this:

    use PDL::IO::CSV qw(rcsv2D wcsv2D);

Or import all available functions:

    use PDL::IO::CSV ':all';

## rcsv1D

Loads data from CSV file into 1D piddles (separate for each column).

    my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle);
    #or
    my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \@column_ids);
    #or
    my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \%options);
    #or
    my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \@column_ids, \%options);

Parameters:

- csv\_filename\_or\_filehandle

    Path to CSV file to be loaded or a filehandle open for reading.

- column\_ids

    Optional column indices (0-based) defining which columns to load from CSV file.
    Default is `undef` which means to load all columns.

Items supported in **options** hash:

- type

    Defines the type of output piddles: `double`, `float`, `longlong`, `long`, `short`, `byte`.
    Default value is `double`. **BEWARE:** type \`longlong\` can be used only on perls with 64bitint support.

    You can set one type for all columns/piddles:

        my ($a, $b, $c) = rcsv1D($csv, {type => double});

    or separately for each column/piddle:

        my ($a, $b, $c) = rcsv1D($csv, {type => [long, double, double]});

    Special datetime handling (you need to have [PDL::DateTime](https://metacpan.org/pod/PDL::DateTime) installed):

        my ($a, $b, $c) = rcsv1D($csv, {type => [long, 'datetime', double]});
        # piddle $b will be an instance of PDL::DateTime

    or

        my ($a, $b, $c) = rcsv1D($csv, {type => [long, '%m/%d/%Y', double]});
        # piddle $b will be an instance of PDL::DateTime

    or you cat let PDL::IO::CSV try to detect datetime columns (detection is based only on the first csv line)

        my ($a, $b, $c) = rcsv1D($csv, {detect_datetime=>1});

- detect\_datetime

    Values `1` (default) or `0`. Try to detect datetime columns, corresponding output piddles will be
    instances of [PDL::Datetime](https://metacpan.org/pod/PDL::Datetime) (which you need to have installed).

    Value `1` means: try to detect datetime in ISO8601 format, e.g. `'2016-12-16 11:59'`.

    You can also specify a value as strptime format string, e.g. `'%m/%d/%Y %H:%M:%S'`.

- fetch\_chunk

    We do not try to load all CSV data into memory at once; we load them in chunks defined by this parameter.
    Default value is `40000` (CSV rows).

- reshape\_inc

    As we do not try to load the whole CSV file into memory at once, we also do not know at the beginning how
    many rows there will be. Therefore we do not know how big piddle to allocate, we have to incrementally
    (re)allocated the piddle by increments defined by this parameter. Default value is `80000`.

    If you know how many rows there will be you can improve performance by setting this parameter to expected row count.

- empty2bad

    Values `0` (default) or `1` - convert empty cells to BAD values (there is a performance cost when turned on).
    If not enabled the empty values are silently converted into `0`.

- text2bad

    Values `0` (default) or `1` - convert values that don't pass [looks\_like\_number](https://metacpan.org/pod/Scalar::Util#looks_like_number)
    check to BAD values (there is a significant performance cost when turned on). If not enabled these non-numerical
    values are silently converted into `0`.

- header

    Values `0` or `N` (positive integer) - consider the first `N` lines as headers and skip them.
    BEWARE: we are talking here about skipping CSV lines which in some cases might be more than 1 text line.

    NOTE: header values (if any) are considered to be column names and are stored in loaded piddles in $pdl->hdr->{col\_name}

    NOTE: `rcsv1D` accepts a special `header` value `'auto'` which skips rows (from beginning) that have
    in all columns non-numeric values.

    Default: for `rcsv1D` - `'auto'`; for `rcsv2D` - `0`.

- decimal\_comma

    Values `0` (default) or `1` - accept `,` (comma) as a decimal separator (there is a performance cost when turned on).

- encoding

    Optional enconding e.g. `:utf8` (default `undef`) that will be applied on input filehandle.

- debug

    Values `0` (default) or `1` - turn on/off debug messages

- sep\_char

    Value separator, default value `,` (comma).

- and all other options valid for [new](https://metacpan.org/pod/Text::CSV_XS#new) method of [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS)

## rcsv2D

Loads data from CSV file into 2D piddle.

    my $pdl = rcsv2D($csv_filename_or_filehandle);
    #or
    my $pdl = rcsv2D($csv_filename_or_filehandle, \@column_ids);
    #or
    my $pdl = rcsv2D($csv_filename_or_filehandle, \%options);
    #or
    my $pdl = rcsv2D($csv_filename_or_filehandle, \@column_ids, \%options);

Parameters and items supported in `options` hash are the same as by ["rcsv1D"](#rcsv1d).

## wcsv1D

Saves data from one or more 1D piddles to CSV file.

    wcsv1D($pdl1, $pdl2, $pdl3, $csv_filename_or_filehandle, \%options);
    #or
    wcsv1D($pdl1, $pdl2, $pdl3, $csv_filename_or_filehandle);
    #or
    wcsv1D($pdl1, $pdl2, \%options); #prints to STDOUT
    #or
    wcsv1D($pdl1, $pdl2);

    # but also as a piddle method
    $pdl1D->wcsv1D("file.csv");

NOTE: piddles piddles are instances of [PDL::DateTime](https://metacpan.org/pod/PDL::DateTime) are exported by wcsv1D as ISO 8601 strings.

Parameters:

- piddles

    One or more 1D piddles. All has to be 1D but may have different count of elements.

- csv\_filename\_or\_filehandle

    Path to CSV file to write to or a filehandle open for writing. Default is STDOUT.

Items supported in **options** hash:

- header

    Arrayref with values that will be printed as the first CSV line. Or `'auto'` value which means that column
    names are taken from $pdl->hdr->{col\_name}.

    Default: for `wcsv1D` - `'auto'`; for `wcsv2D` - `undef`.

- bad2empty

    Values `0` or `1` (default) - convert BAD values into empty strings (there is a performance cost when turned on).

- encoding

    Optional enconding e.g. `:utf8` (default `undef`) that will be applied on output filehandle.

- debug

    Values `0` (default) or `1` - turn on/off debug messages

- sep\_char

    Value separator, default value `,` (comma).

- eol

    New line separator, default value `\n` (UNIX newline).

- and all other options valid for [new](https://metacpan.org/pod/Text::CSV_XS#new) method of [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS)

## wcsv2D

Saves data from one 2D piddle to CSV file.

    wcsv2D($pdl, $csv_filename_or_filehandle, \%options);
    #or
    wcsv2D($pdl, $csv_filename_or_filehandle);
    #or
    wcsv2D($pdl, \%options); #prints to STDOUT
    #or
    wcsv2D($pdl);

    # but also as a piddle method
    $pdl->wcsv2D("file.csv");

Parameters and items supported in `options` hash are the same as by ["wcsv1D"](#wcsv1d).

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL), [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS)

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2014+ KMX <kmx@cpan.org>
