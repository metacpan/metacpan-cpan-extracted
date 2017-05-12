# NAME

Number::Denominal - break up numbers into arbitrary denominations

# SYNOPSIS



    use Number::Denominal;

    my ( $sec, $min, $hr ) = (localtime)[0..2];
    my $seconds = $hr*3600 + $min*60 + $sec;

    print 'So far today you lived for ',
        denominal($seconds,
            [ qw/second seconds/ ] =>
                60 => [ qw/minute minutes/ ] =>
                    60 => [ qw/hour hours/ ]
        ) . "\n";
    ## Prints: So far today you lived for 23 hours,
    ## 48 minutes, and 23 seconds

    # Same thing but with a 'time' unit set shortcut:
    print 'So far today you lived for ', denominal($seconds, \'time');

    print 'If there were 100 seconds in a minute, and 100 minutes in an hour,',
        ' then you would have lived today for ',
        denominal(
            # This is a shortcut for units that pluralize by adding "s"
            $seconds, second => 100 => minute => 100 => 'hour',
        ) . "\n";
    ## Prints: If there were 100 seconds in a minute, and 100 minutes
    ## in an hour, then you would have lived today for 8 hours, 57 minutes,
    ## and 3 seconds

    print 'And if we called seconds "foos," minutes "bars," and hours "bers"',
        ' then you would have lived today for ',
        denominal(
            $seconds, foo => 100 => bar => 100 => 'ber',
        ) . "\n";
    ## Prints: And if we called seconds "foos," minutes "bars," and hours
    ## "bers" then you would have lived today for 8 bers, 57 bars, and 3 foos

    ## You can get the denominalized data as a list:
    my @data = denominal_list(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

    ## Or same thing as a shorthand:
    my @data = denominal_list(  $seconds, [ 100, 100 ], );

    ## Or get the data as a hashref:
    my $data = denominal_hashref(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

    # We can also handle precision (with rounding):
    print denominal( 3*3600 + 31*60 + 40, \'time', { precision => 2 } );
    # Prints '3 hours and 32 minutes'

# DESCRIPTION

Define arbitrary set of units and split up a number into those units.

This module arose from a discussion in IRC, regarding splitting
a number of seconds into minutes, hours, days...
[Paul 'LeoNerd' Evans](https://metacpan.org/author/PEVANS) brought up
the idea for [Number::Denominal](https://metacpan.org/pod/Number::Denominal) that would split up a number into any
arbitrarily defined arbitrary units and I am the code monkey that
released it.

# EXPORTS

## `denominal`

    ## All these are equivalent:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ] =>
                    24 => day => 7 => 'week',
    );



    # Specify precision:
    my $string = denominal( $number, \'time', { precision => 2 } );

Breaks up the number into given denominations and __returns__ it as a
human-readable string (e.g. `"5 hours, 22 minutes, and 4 seconds"`.
If the value for any unit ends up being zero, that unit will be omitted
(an empty string will be returned if the given number is zero).

__The first argument__ is the number that needs to be broken up into units.
Negative numbers will be `abs()'ed`.

__The other arguments__ are given as a list and
define unit denominations. The list of denominations should start
with a unit name and end with a unit name, and each unit name must be
separated by a number that represents how many left-side units fit into the
right-side unit. __Unit name__ can be an arrayref, a simple string,
or a scalarref. The meaning is as follows:

__The last argument__ is optional and, if present, is given as a
hashref. It specifies various options. See `OPTIONS HASHREF` section
below for possible values.

### an arrayref

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/foo bar/ ]
    );

The arrayref must have two elements. The first element is a string
that is the singular name of the unit. The second element is a string
that is the plural name of the unit Arrayref unit names can be mixed
with simple-string unit names.

### a simple string

    # These are the same:

    my $string = denominal( $number, second => 60 => 'minute' );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] => 60 => [ qw/minute minutes/ ]
    );

When a unit name is a simple string, it's taken as a shortcut for
an arrayref unit name with this simple string as the first element
in that arrayref and the string with letter "s" added at the end as the
second element. (Basically a shortcut for typing units that pluralize
by adding "s" to the end).

### a scalarref

    ## All these are the same:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

Instead of giving a list of unit names and their denominations, you
can pass a scalarref as the second argument to `denominal()`. The
value of the scalar that scalarref references is the name of a unit
set shortcut. Currently available unit sets and their definitions are as
follows:

#### `time`

    time    => [
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    ],

#### `weight`

    weight  => [
        gram => 1000 => kilogram => 1000 => 'tonne',
    ],

#### `weight_imperial`

    weight_imperial => [
       ounce => 16 => pound => 14 => stone => 160 => 'ton',
    ],

#### `length`

    length  => [
       meter => 1000 => kilometer => 9_460_730_472.5808 => 'light year',
    ],

#### `length_mm`

    length_mm  => [
       millimeter => 10 => centimeter => 100 => meter => 1000
            => kilometer => 9_460_730_472.5808 => 'light year',
    ],

#### `length_imperial`

    length_imperial => [
        [qw/inch  inches/] => 12 =>
            [qw/foot  feet/] => 3 => yard => 1760
                => [qw/mile  miles/],
    ],

#### `volume`

    volume => [
       milliliter => 1000 => 'Liter',
    ],

#### `volume_imperial`

    volume_imperial => [
       'fluid ounce' => 20 => pint => 2 => quart => 4 => 'gallon',
    ],

#### `info`

    info => [
        bit => 8 => byte => 1000 => kilobyte => 1000 => megabyte => 1000
            => gigabyte => 1000 => terabyte => 1000 => petabyte => 1000
                => exabyte => 1000 => zettabyte => 1000 => 'yottabyte',
    ],

#### `info_1024`

    info_1024  => [
        bit => 8 => byte => 1024 => kibibyte => 1024 => mebibyte => 1024
            => gibibyte => 1024 => tebibyte => 1024 => pebibyte => 1024
                => exbibyte => 1024 => zebibyte => 1024 => 'yobibyte',
    ],

### OPTIONS HASHREF

    my $string = denominal( $number, \'time', { precision => 2 } );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
        { precision => 2 },
    );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ] =>
                    24 => day => 7 => 'week',
        { precision => 2 },
    );

If the last argument to `denominal()` (or `denominal_hashref()`
or `denominal_list()`) is a hashref, its contents will be interpreted
as various options, dictating specifics of how the number should be
denominated. Currently supported values are as follows:

#### `precision`

    my $string = denominal( $number, \'time', { precision => 2 } );

__Takes__ a positive integer as a value. Specifies precision of output.
This means the output will have at most `precision` number of different
units. __Rounding__ is in place for units smaller than `precision`.

For example,

    denominal( 3*3600 + 31*60 + 1, \'time', );

will output `3 hours, 31 minutes, and 1 second`. If we set `precision`to
`2` units:

    denominal( 3*3600 + 31*60 + 40, \'time', { precision => 2 } );

The output will be `3 hours and 32 minutes` (note how the minutes got
rounded, because 40 seconds is more than half a minute). Further, if
we set `precision` to `1` unit:

    denominal( 3*3600 + 31*60 + 1, \'time', { precision => 1} );

We'll get `4 hours` as output.

It is possible to get fewer than `precision` units in the output, even
if without precision you'd get more than 1. For example,

    denominal( 23*3600 + 59*60 + 59, \'time', );

Would output `23 hours, 59 minutes, and 59 seconds`. Now, if we set
`precision` to `2` units:

    denominal( 23*3600 + 59*60 + 59, \'time', { precision => 2 } );

The output will be `1 day`. What happens is a 2-unit precision rounds
off to `23 hours and 60 seconds`, which rounds off to `24 hours`, and
we have a larger unit that is equal to 24 hours: `1 day`.

For `denominal_list`, `precision` affects how many units can have
values other than zero. Units outside `precision` will have their values
as zero.

## `denominal_list`

    ## These two are equivalent

    my @bits = denominal_list(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );
    ## @bits will always contain 5 elements, some of which might be 0



    my @bits = denominal_list(
        $number,
        [ qw/60  60  24  7/ ],
    );

Functions the same as `denominal()`, except it __returns__ a list of unit
values, instead of a string. (e.g. when `denominal()` would return
"8 hours, 23 minutes, and 5 seconds", `denominal_list()` would return
a list of numbers—`8, 23, 5`—for hours, minutes, seconds, and
`0` __for all the remaining units__).

Another shortcut is possible with `denominal_list()`. Instead of giving
each unit a name, you can call `denominal_list()` with just
__two arguments__ and pass an arrayref as the second
argument, containing a list of numbers defining unit denominations.

__Note on precision:__ if you're using `precision` argument to specify
the precision of units (see its description in ["OPTIONS HASHREF"](#options-hashref)
section above), then it will affect how many units will have values
other than zeros; i.e. you'll still have the same number of elements
as without `precision`.

## `denominal_hashref`

    ## These two are equivalent

    my $data = denominal_hashref(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    say "The number has $data->{second} seconds and $data->{week} weeks!";

Functions the same as `denominal()`, except it __returns__ a hashref
where the keys are the __singular__ names of the units and values are
the numerical values of each unit. If a unit's value is zero, its key
will be absent from the hashref.

# AUTHORS

- __Idea:__ Paul Evans, `<pevans at cpan.org>`
- __Code:__ Zoffix Znet, `<zoffix at cpan.org>`

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Number-Denominal](https://github.com/zoffixznet/Number-Denominal)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Number-Denominal/issues](https://github.com/zoffixznet/Number-Denominal/issues)

If you can't access GitHub, you can email your request
to `bug-Number-Denominal at rt.cpan.org`

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
