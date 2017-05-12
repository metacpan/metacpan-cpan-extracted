# NAME

Term::GnuScreen::WindowArrayLike - window list is operated like Array

# SYNOPSIS

    use Term::GnuScreen::WindowArrayLike;
    my $screen = Term::GnuScreen::WindowArrayLike->new;
    $screen->insert;
    $screen->insert(3);
    $screen->push;
    $screen->compact;

    # .screenrc
    # push is [C-t l p]
    escape ^Tt
    bind  l command -c window_array_like
    bind  -c window_array_like  p exec perl -e 'use Term::GnuScreen::WindowArrayLike; Term::GnuScreen::WindowArrayLike->new->push'

# DESCRIPTION

Term::GnuScreen::WindowArrayLike operates screen window list using Array method.

# METHODS

## new(\\%opts)

Constructor.

## push

Add window to the end of a list. 

## insert($window\_number)

A window is inserted in the given number.
Before inserting window, as for window number not less than the given number, 1 is added.

The current window number becomes a default value when not giving a number. 

## compact

Reassign sequential numbers.

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass <tokubass@cpan.org>
