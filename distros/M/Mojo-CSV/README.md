# NAME

Mojo::CSV - no-nonsense CSV handling

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    # Just convert data to CSV and gimme it
    say Mojo::CSV->new->text([
        [ qw/foo bar baz/ ],
        [ qw/moo mar mer/ ],
    ]);

    my $data = Mojo::CSV->new->slurp('file.csv') # returns a Mojo::Collection
        ->grep(sub{ $_->[0] eq 'Zoffix' });

    my $csv = Mojo::CSV->new( in => 'file.csv' );
    while ( my $row = $csv->row ) {
        # Read row-by-row
    }

    # Write CSV file in one go
    Mojo::CSV->new->spurt( $data => 'file.csv' );

    # Write CSV file row-by-row
    my csv = Mojo::CSV->new( out => 'file.csv' );
    $csv->trickle( $row ) for @data;

<div>
    </div></div>
</div>

# DESCRIPTION

Read and write CSV (Comma Separated Values) like a boss, Mojo style.

# METHODS

Unless otherwise indicated, all methods return their invocant.

## `flush`

    $csv->flush;

Flushes buffer and closes ["out"](#out) filehandle. Call this when you're done
[trickling](#trickle) data. This will be done automatically when the
`Mojo::CSV` object is destroyed.

## `in`

    my $csv = Mojo::CSV->new( in => 'file.csv' );

    $csv->in('file.csv');

    open my $fh, '<', 'foo.csv' or die $!;
    $csv->in( $fh );
    $csv->in( Mojo::Asset::File->new(path => 'file.csv') );
    $csv->in( Mojo::Asset::Memory->new->add_chunk('foo,bar,baz') );

Specifies the input for ["slurp"](#slurp), ["slurp\_body"](#slurp_body) and ["row"](#row).
Takes a filename, an opened filehandle, a [Mojo::Asset::File](https://metacpan.org/pod/Mojo::Asset::File) object, or
a [Mojo::Asset::Memory](https://metacpan.org/pod/Mojo::Asset::Memory) object.

## `new`

    Mojo::CSV->new;
    Mojo::CSV->new( in => 'file.csv', out => 'file.csv' );

Creates a new `Mojo::CSV` object. Takes two optional arguments. See
["in"](#in) and ["out"](#out) for details.

## `out`

    my $csv = Mojo::CSV->new( out => 'file.csv' );

    $csv->out('file.csv');

    open my $fh, '>', 'foo.csv' or die $!;
    $csv->out( $fh );

Specifies the output for ["spurt"](#spurt) and ["trickle"](#trickle). Takes either
a filename or an opened filehandle.

## `row`

    my $row = $csv->row;

Returns an arrayref, which is a row of data from the CSV. The thing
to read must be first set with [in method](#in) or `in` argument to
["new"](#new)

## `slurp`

    my $data = Mojo::CSV->new->slurp('file.csv');
    my $data = Mojo::CSV->new( in => 'file.csv' )->slurp;

Returns a [Mojo::Collection](https://metacpan.org/pod/Mojo::Collection) object, each item of which is an arrayref
representing a row of CSV data.

## `slurp_body`

    my $data = Mojo::CSV->new->slurp_body('file.csv');

A shortcut for calling ["slurp"](#slurp) and discarding the first row
(use this for CSV with headers you want to get rid of).

## `spurt`

    Mojo::CSV->new->spurt( $data => 'file.csv');
    Mojo::CSV->new( out => 'file.csv' )->spurt( $data );

Writes a data structure into CSV. `$data` is an arrayref of rows, which
are themselves arrayrefs (each item is a cell data). It will call
["flush"](#flush) on completion. See also ["trickle"](#trickle).

## `text`

    say Mojo::CSV->new->text([qw/foo bar baz/]);

    say Mojo::CSV->new->text([
        [ qw/foo bar baz/ ],
        [ qw/moo mar mer/ ],
    ]);

Returns a CSV string. Takes either a single arrayref to encode just a single
row or an arrayref of arrayrefs to include multiple rows.
[Arrayref-like things](https://metacpan.org/pod/Mojo::Collection) should work too.

## `trickle`

    my $csv = Mojo::CSV->new( out => 'file.csv' );
    $csv->trickle( $_ ) for @data;

Writes out a single row of CSV. Takes an arrayref of cell values. Note that
the writes may be buffered (see ["flush"](#flush))

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text::CSV), [Text::xSV](https://metacpan.org/pod/Text::xSV)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojo-CSV](https://github.com/zoffixznet/Mojo-CSV)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojo-CSV/issues](https://github.com/zoffixznet/Mojo-CSV/issues)

If you can't access GitHub, you can email your request
to `bug-Mojo-CSV at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
