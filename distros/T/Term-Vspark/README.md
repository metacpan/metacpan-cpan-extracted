[![Build Status](https://travis-ci.org/kablamo/Term-Vspark.svg?branch=master)](https://travis-ci.org/kablamo/Term-Vspark) [![Coverage Status](https://img.shields.io/coveralls/kablamo/Term-Vspark/master.svg)](https://coveralls.io/r/kablamo/Term-Vspark?branch=master)
# NAME

Term::Vspark - Displays a graph in the terminal

# SYNOPSIS

    use Term::Vspark qw/vspark/;
    binmode STDOUT, ':encoding(UTF-8)';
    print vspark(
        values  => [0,1,2,3,4,5], # required
        labels  => [0,1,2,3,4,5],
        max     => 7,   # max value
        columns => 80,  # width of the graph including labels
    );

    # The output looks like this:
    # 0 
    # 1 ███████████
    # 2 ██████████████████████
    # 3 █████████████████████████████████
    # 4 ████████████████████████████████████████████
    # 5 ███████████████████████████████████████████████████████

# DESCRIPTION

This module displays beautiful graphs in the terminal.  It is a companion to
Term::Spark but instead of displaying normal sparklines it displays "vertical"
sparklines.

# METHODS

## vspark(%params)

show\_graph() returns a string.

The 'values' parameter should be an ArrayRef of numbers.   This is required.

The 'labels' parameter should be an ArrayRef of strings.  This is optional.
Each label will be used with the corresponding value.

The 'max' parameter is the maximum value of the graph.  Without this parameter
you cannot compare graphs because the scaling changes depending on the data.
This parameter is optional.

The 'columns' parameter is the maximum width of the graph.  This defaults to
your terminal width or 80 characters -- whichever is smaller.  Set 'columns' to
'max' if you want to use the full width of your terminal.

# AUTHOR

Eric Johnson (kablamo)

Gil Gonçalves <lurst@cpan.org> (original author)

# SEE ALSO

[Term::Spark](https://metacpan.org/pod/Term::Spark)
