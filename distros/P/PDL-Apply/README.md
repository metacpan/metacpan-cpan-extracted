# NAME

PDL::Apply - Apply a given function in "rolling" / "moving" / "over" manners

# SYNOPSIS

    use PDL;
    use PDL::Apply ':all';

    my $x = pdl([40.7,81.7,28.9,33.3,40.8,16.3]);

    print $x->apply_rolling(3, 'sum');
    # [ BAD BAD 151.3 143.9 103 90.4]

    print $x->apply_over('sum');
    # 241.7
    print $x->sumover;
    # 241.7

    my $slices = indx([ [0, 2], [4, 5] ]);
    print $x->apply_slice($slices, 'sum');
    # [151.3, 57.1]
    # 151.3 = 40.7+81.7+28.9 (indices 0..2)
    # 57.1  = 40.8+16.3 (indices 4..5)

# DESCRIPTION

This module allows you to:

- compute "rolling" functions (like `Moving Average`) with given sliding window
- compute "over" like functions (like `sumover`) with arbitrary function applied

But keep in mind that the speed is far far beyond the functions with C implementation like `sumover`.

# FUNCTIONS

By default, PDL::Apply doesn't import any function. You can import individual functions like this:

    use PDL::Apply qw(apply_rolling apply_over);

Or import all available functions:

    use PDL::Apply ':all';

## apply\_over

    $result = apply_over($pdl, $func, @fargs);
    #or
    $result = $pdl->apply_over($func, @fargs);

    # $pdl    .. Input piddle, 1D or ND
    # $func   .. Function (PDL method) name as a string or code reference
    # @fargs  .. Optional arguments passed to function

## apply\_rolling

    $result = apply_rolling($pdl, $width, $func, @fargs);
    #or
    $result = $pdl->apply_rolling($width, $func, @fargs);

    # $pdl    .. Input piddle, 1D or ND
    # $width  .. Size of rolling window
    # $func   .. Function (PDL method) name as a string or code reference
    # @fargs  .. Optional arguments passed to function

## apply\_slice

    $result = apply_slice($pdl, $slices, $func, @fargs);
    #or
    $result = $pdl->apply_slice($slices, $func, @fargs);

    # $pdl    .. Input piddle, 1D or ND
    # $slices .. Piddle (2,N) with slices - [startidx, endidx] pairs
    # $func   .. Function (PDL method) name as a string or code reference
    # @fargs  .. Optional arguments passed to function

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2015+ KMX <kmx@cpan.org>
