# NAME

Module::Filename - Provides an object oriented, cross platform interface for getting a module's filename

# SYNOPSIS

    use Module::Filename;
    my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File

    use Module::Filename qw{module_filename};
    my $filename=module_filename("Test::More");                 #isa Path::Class::File

# DESCRIPTION

This module returns the filename as a [Path::Class::File](https://metacpan.org/pod/Path%3A%3AClass%3A%3AFile) object.  It does not load any packages as it scans.  It simply scans @INC looking for a module of the same name as the package passed.

# USAGE

    use Module::Filename;
    my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File
    print "Test::More can be found at $filename\n";

# CONSTRUCTOR

## new

    my $mf=Module::Filename->new();

# METHODS

## initialize

You can inherit the filename method in your package.

    use base qw{Module::Filename};
    sub initialize{do_something_else()};

## filename

Returns a [Path::Class::File](https://metacpan.org/pod/Path%3A%3AClass%3A%3AFile) object for the first filename that matches the module in the @INC path array.

    my $filename=Module::Filename->new->filename("Test::More"); #isa Path::Class::File
    print "Filename: $filename\n";

# FUNCTIONS

## module\_filename

Returns a [Path::Class::File](https://metacpan.org/pod/Path%3A%3AClass%3A%3AFile) object for the first filename that matches the module in the @INC path array.

    my $filname=module_filename("Test::More"); #isa Path::Class::File
    print "Filename: $filename\n";

# LIMITATIONS

The algorithm does not scan inside module files for provided packages.

# BUGS

Submit to RT and email author.

# AUTHOR

    Michael R. Davis

# COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

Module::Filename predates [Module::Path](https://metacpan.org/pod/Module%3A%3APath) by almost 4 years but it appears more people prefer [Module::Path](https://metacpan.org/pod/Module%3A%3APath) over Module::Filename as it does not have the dependency on [Path::Class](https://metacpan.org/pod/Path%3A%3AClass).  After the reviews on [http://neilb.org/reviews/module-path.html](http://neilb.org/reviews/module-path.html). I added the functional API to Module::Filename.  So, your decision is simply an object/non-object decision.   The operations with the file system that both packages perform outweigh the performance of the object creation in Module::Filename.  So, any performance penalty should not be measurable.  Since Module::Filename does not need three extra file test operations that Module::Path 0.18 performs on each @INC directory, Module::Filename may actually be faster than [Module::Path](https://metacpan.org/pod/Module%3A%3APath) for most applications.

## Similar Capabilities

[Module::Path](https://metacpan.org/pod/Module%3A%3APath), [perlvar](https://metacpan.org/pod/perlvar) %INC, [pmpath](https://metacpan.org/pod/pmpath), [Module::Info](https://metacpan.org/pod/Module%3A%3AInfo) constructor=>new\_from\_module, method=>file, [Module::InstalledVersion](https://metacpan.org/pod/Module%3A%3AInstalledVersion) property=>"dir", [Module::Locate](https://metacpan.org/pod/Module%3A%3ALocate) method=>locate, [Module::Util](https://metacpan.org/pod/Module%3A%3AUtil) method=>find\_installed, ["module\_notional\_filename" in Module::Runtime](https://metacpan.org/pod/Module%3A%3ARuntime#module_notional_filename)

## Comparison

CPAN modules for getting a module's path [http://neilb.org/reviews/module-path.html](http://neilb.org/reviews/module-path.html)
