# NAME

MooX::Roles::Pluggable - Moo eXtension for pluggable roles

# SYNOPSIS

    package MyPackage;

    use Moo;

    sub foo { ... }

    use MooX::Roles::Pluggable search_path => 'MyPackage::Role';

    package MyPackage::Role::Bar;

    use Moo::Role;

    around foo => sub {
        ...
    };

    1;

# DESCRIPTION

This module allows a class consuming several roles based on rules passed
to [Module::Pluggable::Object](https://metacpan.org/pod/Module::Pluggable::Object).

The basic idea behind this tool is the ability to have plugins as roles
which attach themselve using the `around`, `before` and `behind` sugar
of _Moo(se)_.

The arguments of import are redirected to [Module::Pluggable::Object](https://metacpan.org/pod/Module::Pluggable::Object),
with following defaults (unless specified):

- `search_path`

    Default search\_path is `${caller}::Role`.

- `require`

    Default for require is 1.

## USE WITH CAUTION

Remember that using a module like this which automatically injects code
into your existing and running and (hopefully) well tested programs
and/or modules can be dangerous and should be avoided whenever possible.

## USE ANYWAY

On the other hand, when you're allowing plugins being loaded by your
code, it's probably faster compiling the chain of responsibility once than
doing it at runtime again and again. Allowing plugins changing the
behaviour of your code anyway. When that's the intension, this is your
module.

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-moox-roles-pluggable at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Roles-Pluggable](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Roles-Pluggable).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Roles::Pluggable

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Roles-Pluggable](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Roles-Pluggable)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-Roles-Pluggable](http://annocpan.org/dist/MooX-Roles-Pluggable)

- CPAN Ratings

    [http://cpanratings.perl.org/d/MooX-Roles-Pluggable](http://cpanratings.perl.org/d/MooX-Roles-Pluggable)

- Search CPAN

    [http://search.cpan.org/dist/MooX-Roles-Pluggable/](http://search.cpan.org/dist/MooX-Roles-Pluggable/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
