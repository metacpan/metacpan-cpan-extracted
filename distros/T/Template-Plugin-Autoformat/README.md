Template::Plugin::Autoformat
============================

This Template Toolkit plugin module is an interface to Damian Conway's
"Text::Autoformat" Perl module which provides advanced text wrapping and
formatting.


### Instalation ###

    # from CPAN
    $ cpan Template::Plugin::Autoformat

    # or from cpanm
    $ cpanm Template::Plugin::Autoformat

    # or cloning the repository
    $ git clone git@github.com:karpet/template-plugin-autoformat.git

    # or manual installation (after downloading / unpacking)
    perl Makefile.PL
    make
    make test
    make install

### Usage ###

in your template, define some text on a variable or block:

    [% text = BLOCK %]
       Be not afeard.  The isle is full of noises, sounds and sweet
       airs that give delight but hurt not.
    [% END %]

then either pass options to constructor...

    [% USE Autoformat(case => 'upper') %]
    [% Autoformat(text) %]

... or to the Autoformat subroutine itself

    [% USE Autoformat %]
    [% Autoformat(text, case => 'upper') %]

You can also use the Autoformat filter

    [% USE Autoformat %]
    [% FILTER Autoformat(left => 10, right => 30) %]
       Be not afeard.  The isle is full of noises, sounds and sweet
       airs that give delight but hurt not.
    [% END %]

and even create your custom filters with it:

    [% USE Autoformat %]
    [% text FILTER poetry = Autoformat(left => 20, right => 40) %]

    # reuse the 'poetry' filter alias
    [% some_text | poetry %]

Using forms is also easy and straightforward:

    [% USE Autoformat(form => '>>>>.<<<', numeric => 'AllPlaces') %]
    [% Autoformat(10, 20.32, 11.35) %]

Please refer to https://metacpan.org/pod/Template::Plugin::Autoformat for
the complete documentation, or type:

    perldoc Template::Plugin::Autoformat

in your terminal after installation.


### Authors ###

Robert McArthur wrote the original plugin code, with some modifications
and additions from Andy Wardley.

Damian Conway wrote the Text::Autoformat module which does all the
clever stuff.

The module was moved out of the Template Toolkit core and into a
separate distribution in December 2008. Peter Karman is the current
maintainer.


### Copyright ###

Copyright (C) 2000-2015 Robert McArthur & Andy Wardley. All Rights
Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
