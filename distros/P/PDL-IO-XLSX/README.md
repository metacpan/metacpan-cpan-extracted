# NAME

PDL::IO::XLSX - Load/save PDL from/to XLSX file (optimized for speed and large data)

# SYNOPSIS

    use PDL;
    use PDL::IO::XLSX ':all';

    my $pdl = rxlsx2D('input.xlsx');
    $pdl *= 2;
    wxlsx2D($pdl, 'double.xlsx');

    my ($pdl1, $pdl2, $pdl3) = rxlsx1D('input.xlsx', [0, 1, 6]);
    wxlsx1D($pdl1, 'col2.xlsx');
    #or
    $pdl2->wxlsx1D('col2.xlsx');

# DESCRIPTION

PDL::IO::XLSX supports reading XLSX files and creating PDL piddle(s) as well as saving PDL data to XLSX file.

# FUNCTIONS

By default, PDL::IO::XLSX doesn't import any function. You can import individual functions like this:

    use PDL::IO::XLSX qw(rxlsx2D wxlsx2D);

Or import all available functions:

    use PDL::IO::XLSX ':all';

## rxlsx1D

Loads data from XLSX file into 1D piddles (separate for each column).

    my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle);
    #or
    my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \@column_ids);
    #or
    my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \%options);
    #or
    my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \@column_ids, \%options);

Parameters:

- xlsx\_filename\_or\_filehandle

    Path to XLSX file to be loaded or a filehandle open for reading.

- column\_ids

    Optional column indices (0-based) defining which columns to load from XLSX file.
    Default is `undef` which means to load all columns.

Items supported in **options** hash:

- type

    Defines the type of output piddles: `double`, `float`, `longlong`, `long`, `short`, `byte` + special
    values `'auto'` (try to autodetect) and `'datetime'` (PDL::DateTime).

    Default: for `rxlsx1D` - `'auto'`; for `rxlsx2D` - `double`.

    You can set one type for all columns/piddles:

        my ($a, $b, $c) = rxlsx1D($xlsx, {type => double});

    or separately for each column/piddle:

        my ($a, $b, $c) = rxlsx1D($xlsx, {type => [long, double, double]});

    Special datetime handling:

        my ($a, $b, $c) = rxlsx1D($xlsx, {type => [long, 'datetime', double]});
        # piddle $b will be an instance of PDL::DateTime

- reshape\_inc

    As we do not try to load the whole XLSX file into memory at once, we also do not know at the beginning how
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

    Values `0` or `N` (positive integer) - consider the first `N` rows as headers and skip them.

    NOTE: header values (if any) are considered to be column names and are stored in loaded piddles in $pdl->hdr->{col\_name}

    NOTE: `rxlsx1D` accepts a special `header` value `'auto'` which skips rows (from beginning) that have
    in all columns non-numeric values.

    Default: for `rxlsx1D` - `'auto'`; for `rxlsx2D` - `0`.

- sheet\_name

    The name of xlsx sheet that will be read (default is the first sheet).

- debug

    Values `0` (default) or `1` - turn on/off debug messages

## rxlsx2D

Loads data from XLSX file into 2D piddle.

    my $pdl = rxlsx2D($xlsx_filename_or_filehandle);
    #or
    my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \@column_ids);
    #or
    my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \%options);
    #or
    my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \@column_ids, \%options);

Parameters and items supported in `options` hash are the same as by ["rxlsx1D"](#rxlsx1d).

## wxlsx1D

Saves data from one or more 1D piddles to XLSX file.

    wxlsx1D($pdl1, $pdl2, $pdl3, $xlsx_filename_or_filehandle, \%options);
    #or
    wxlsx1D($pdl1, $pdl2, $pdl3, $xlsx_filename_or_filehandle);
    #or
    wxlsx1D($pdl1, $pdl2);

    # but also as a piddle method
    $pdl1D->wxlsx1D("file.xlsx");

Parameters:

- piddles

    One or more 1D piddles. All has to be 1D but may have different count of elements.

- xlsx\_filename\_or\_filehandle

    Path to XLSX file to write to or a filehandle open for writing.

Items supported in **options** hash:

- header

    Arrayref with values that will be printed as the first XLSX row. Or `'auto'` value which means that column
    names are taken from $pdl->hdr->{col\_name}.

    Default: for `wxlsx1D` - `'auto'`; for `wxlsx2D` - `undef`.

- bad2empty

    Values `0` or `1` (default) - convert BAD values into empty strings (there is a performance cost when turned on).

- sheet\_name

    The name of created sheet inside xlsx (default is `'Sheet1'`).

- debug

    Values `0` (default) or `1` - turn on/off debug messages

## wxlsx2D

Saves data from one 2D piddle to XLSX file.

    wxlsx2D($pdl, $xlsx_filename_or_filehandle, \%options);
    #or
    wxlsx2D($pdl, $xlsx_filename_or_filehandle);
    #or
    wxlsx2D($pdl);

    # but also as a piddle method
    $pdl->wxlsx2D("file.xlsx");

Parameters and items supported in `options` hash are the same as by ["wxlsx1D"](#wxlsx1d).

# CREDITS

This modules is largely inspired by [Data::XLSX::Parser](https://metacpan.org/pod/Data::XLSX::Parser) and [Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX).

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL)

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2016+ KMX <kmx@cpan.org>
