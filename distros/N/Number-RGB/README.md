# NAME

Number::RGB - Manipulate RGB Tuples

# SYNOPSIS

    use Number::RGB;
    my $white :RGB(255);
    my $black :RGB(0);

    my $gray = $black + ( $white / 2 );

    my @rgb = @{ $white->rgb };
    my $hex = $black->hex;

    my $blue   = Number::RGB->new(rgb => [0,0,255]);
    my $green  = Number::RGB->new(hex => '#00FF00');

    my $red :RGB(255,0,0);

    my $purple = $blue + $green;
    my $yellow = $red  + $green;

# DESCRIPTION

This module creates RGB tuple objects and overloads their operators to
make RGB math easier. An attribute is also exported to the caller to
make construction shorter.

## Methods

### `new`

    my $red   = Number::RGB->new(rgb => [255,0,0])
    my $blue  = Number::RGB->new(hex => '#0000FF');
    my $blue  = Number::RGB->new(hex => '#00F');
    my $black = Number::RGB->new(rgb_number => 0);

This constructor accepts named parameters. One of three parameters are
required.

`rgb` is a array reference containing three integers within the range
of `0..255`. In order, each integer represents _red_, _green_, and
_blue_.

`hex` is a hexadecimal representation of an RGB tuple commonly used in
Cascading Style Sheets. The format begins with an optional hash (`#`)
and follows with three groups of hexadecimal numbers representing
_red_, _green_, and _blue_ in that order. A shorthand, 3-digit version
can be used: `#123` is equivalent to `#112233`.

`rgb_number` is a single integer to use for each of the three primary colors.
This is shorthand to create _white_, _black_, and all shades of
_gray_.

This method throws an exception on error.

### `new_from_guess`

    my $color = Number::RGB->new_from_guess( ... );

This constructor tries to guess the format being used and returns a
tuple object. If it can't guess, an exception will be thrown.

_Note:_ a single number between `0..255` will _never_ be interpreted as
a hex shorthand. You'll need to explicitly prepend `#` character to
disambiguate and force hex mode.

### `r`

Accessor and mutator for the _red_ value.

### `g`

Accessor and mutator for the _green_ value.

### `b`

Accessor and mutator for the _blue_ value.

### `rgb`

Returns a array reference containing three elements. In order they
represent _red_, _green_, and _blue_.

### `hex`

Returns a hexadecimal representation of the tuple conforming to the format
used in Cascading Style Sheets.

### `hex_uc`

Returns the same thing as ["hex"](#hex), but any hexadecimal numbers that
include `'A'..'F'` will be in upper case.

### `as_string`

Returns a string representation of the tuple.  For example, _white_
would be the string `255,255,255`.

## Attributes

### `:RGB()`

    my $red   :RGB(255,0,0);
    my $blue  :RGB(#0000FF);
    my $white :RGB(0);

This attribute is exported to the caller and provides a shorthand wrapper
around ["new\_from\_guess"](#new_from_guess).

## Overloads

`Number::RGB` [overloads](https://metacpan.org/pod/overload) the following operations:

    ""
    +
    -
    *
    /
    %
    **
    <<
    >>
    &
    ^
    |

Stringifying a `Number::RGB` object will produce a string with three
RGB tuples joined with commas. All other operators operate on each
individual RGB tuple number.

If the tuple value is below `0` after
the operation, it will set to `0`. If the tuple value is above `255` after
the operation, it will set to `255`.

_Note:_ illegal operations (such us dividing by zero) result in the tuple
value being set to `0`.

Operations create new `Number::RGB` objects,
which means that even something as strange as this still works:

    my $color :RGB(5,10,50);
    print 110 - $color; # prints '105,100,60'

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Number-RGB](https://github.com/zoffixznet/Number-RGB)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Number-RGB/issues](https://github.com/zoffixznet/Number-RGB/issues)

If you can't access GitHub, you can email your request
to `bug-Number-RGB at rt.cpan.org`

<div>
    </div></div>
</div>

# MAINTAINER

This module is currently maintained by:

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/CWEST"> <img src="http://www.gravatar.com/avatar/1ed0b822068d34032bca7d2beeb2f846?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fb3bb9984adabb61d974f96965b2ed074" alt="CWEST" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">CWEST</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
