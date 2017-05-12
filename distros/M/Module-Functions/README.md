# NAME

Module::Functions - Get function list from package.

# SYNOPSIS

    package My::Class;
    use parent qw/Exporter/;
    use Module::Functions;
    our @EXPORT = get_public_functions();

# DESCRIPTION

Module::Functions is a library to get a public functions list from package.
It is useful to create a exportable function list.

# METHODS

## my @functions = get\_public\_functions()

## my @functions = get\_public\_functions($package)

Get a public function list from the package.

If you don't pass the `$package` parameter, the function use `caller(0)` as a source package.

This function does not get a function, that imported from other package.

For example:

    package Foo;
    use File::Spec::Functions qw/catfile/;
    sub foo { }

In this case, return value of `get_public_functions('Foo')` does not contain 'catfile'. Return value is `('foo')`.

### RULES

This `get_public_functions` removes some function names.

Rules are here:

- BEGIN, UNITCHECK, CHECK, INIT, and END are hidden.
- 'import' method is hidden
- function name prefixed by '\_' is hidden.

## my @functions = get\_full\_functions();

## my @functions = get\_full\_functions($package)

This function get ALL functions.
ALL means functions that were imported from other packages.
And included specially named functions(BEGIN , UNITCHECK , CHECK , INIT and END).
Of course, included also private functions( ex. \_foo ).

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Exporter::Auto](http://search.cpan.org/perldoc?Exporter::Auto) have same feature of this module, but it stands on very tricky thing.

[Class::Inspector](http://search.cpan.org/perldoc?Class::Inspector) finds the function list. But it does not check the function defined at here or imported from other package.

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
