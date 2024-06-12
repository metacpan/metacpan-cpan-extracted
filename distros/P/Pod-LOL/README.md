# NAME

Pod::LOL - parse Pod into a list of lists (LOL)

# VERSION

Version 0.14

# SYNOPSIS

    % cat my.pod

    =head1 NAME

    Pod::LOL - parse Pod into a list of lists (LOL)


    % perl -MPod::LOL -MData::Dumper -e 'print Dumper( Pod::LOL->new_root("my.pod") )'

Returns:

    [
       [
          "head1",
          "NAME"
       ],
       [
          "Para",
          "Pod::LOL - parse Pod into a list of lists (LOL)"
       ],
    ]

# DESCRIPTION

This class may be of interest to anyone writing a pod parser.

This module takes pod (as a file) and returns a list of lists (LOL) structure.

This is a subclass of [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple) and inherits all of its methods.

# SUBROUTINES/METHODS

## new\_root

Convenience method to do (mostly) this:

    Pod::LOL->new->parse_file( $file )->{root};

## \_handle\_element\_start

Overrides Pod::Simple.
Executed when a new pod element starts such as:

    "head1"
    "Para"

## \_handle\_text

Overrides Pod::Simple.
Executed for each text element such as:

    "NAME"
    "Pod::LOL - parse Pod into a list of lists (LOL)"

## \_handle\_element\_end

Overrides Pod::Simple.
Executed when a pod element ends.
Such as when these tags end:

    "head1"
    "Para"

# SEE ALSO

[App::Pod](https://metacpan.org/pod/App%3A%3APod)

[Pod::Query](https://metacpan.org/pod/Pod%3A%3AQuery)

[Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple)

# AUTHOR

Tim Potapov, `<tim.potapov[AT]gmail.com>`

# BUGS

Please report any bugs or feature requests to [https://github.com/poti1/pod-lol/issues](https://github.com/poti1/pod-lol/issues).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::LOL

You can also look for information at:

[https://metacpan.org/pod/Pod::LOL](https://metacpan.org/pod/Pod::LOL)
[https://github.com/poti1/pod-lol](https://github.com/poti1/pod-lol)

# ACKNOWLEDGEMENTS

TBD

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
