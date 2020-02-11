# NAME

Mojo::File::Share - Better local share directory support with Mojo::File

# STATUS

<div>
    <a href="https://travis-ci.org/srchulo/Mojo-File-Share"><img src="https://travis-ci.org/srchulo/Mojo-File-Share.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-File-Share?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-File-Share/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    package Foo::Bar;
    use Mojo::File::Share qw(dist_dir dist_file);

    # defaults to using calling package to determine dist_dir
    my $dist_dir = dist_dir();
    my $collection = $dist_dir->list_tree; # is a Mojo::File

    # same as above, but specifies dist explicitly
    my $dist_dir = dist_dir('Foo-Bar');

    # with one argument, calling package is used for dist
    my $file = dist_file('file.txt');
    say $file->slurp; # is a Mojo::File

    # same as above, but specifies dist explicitly
    my $file = dist_file('Foo-Bar', 'file.txt');

    # use path so there is only one arg and default dist is used
    my $file = dist_file(path('path', 'to', 'file.txt'));

    # or specify dist and path is not necessary
    my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

# DESCRIPTION

[Mojo::File::Share](https://metacpan.org/pod/Mojo::File::Share) is a dropin replacement for [File::ShareDir](https://metacpan.org/pod/File::ShareDir) based on [File::Share](https://metacpan.org/pod/File::Share). [Mojo::File::Share](https://metacpan.org/pod/Mojo::File::Share) has
three main differences from [File::Share](https://metacpan.org/pod/File::Share):

- ["dist\_dir"](#dist_dir) and ["dist\_file"](#dist_file) both return [Mojo::File](https://metacpan.org/pod/Mojo::File) objects.
- ["dist\_dir"](#dist_dir) and ["dist\_file"](#dist_file) have been enhanced even more to understand when the developer's
local `./share/` directory should be used.

    [File::Share](https://metacpan.org/pod/File::Share) checks `%INC` to determine if the dist has been `use`d or `require`d, and then it checks for the
    `share` directory relative to the dist's `.pm` file location. This is good for a lot of local development, but it
    is not good for using in tests if you want to access the `share` directory but haven't loaded the dist.
    [Mojo::File::Share](https://metacpan.org/pod/Mojo::File::Share) does the above check, and then if that doesn't work, it checks the current working
    directory for the existence of `lib/$path_to_dist.pm` and the existence of a `share` directory, and
    returns that `share` directory if both conditions are true. This removes the need a lot of the time to
    do something like this in your tests:

        $File::ShareDir::DIST_SHARE{'Foo-Bar'} = path('share')->realpath;

- If no dist is provided to ["dist\_dir"](#dist_dir) or ["dist\_file"](#dist_file), [Mojo::File::Share](https://metacpan.org/pod/Mojo::File::Share) will default to using
the calling package as the dist.

NOTE: `module_dist` and `module_file` are not supported.

# FUNCTIONS

## dist\_dir

    # defaults to using calling package to determine dist_dir
    # package Foo::Bar becomes dist Foo-Bar
    my $dist_dir = dist_dir();
    my $collection = $dist_dir->list_tree; # is a Mojo::File

    # specify dist explicitly
    my $dist_dir = dist_dir('Foo-Bar');

The ["dist\_dir"](#dist_dir) function takes a single parameter of the name of an installed (CPAN or otherwise) distribution, and locates either
the local share directory, if one exists, or the shared data directory created at install time for it. If no distribution is provided,
["dist\_dir"](#dist_dir) will use the package of the caller to determine the name of the distribution.

Returns the directory as a [Mojo::File](https://metacpan.org/pod/Mojo::File) returned by ["realpath" in Mojo::File](https://metacpan.org/pod/Mojo::File#realpath), or dies if it cannot be located or is not readable.

See ["DESCRIPTION"](#description) for an explanation on how ["dist\_dir"](#dist_dir) works better for local development and local distributions.

## dist\_file

    # with one argument, calling package is used for dist
    my $file = dist_file('file.txt');
    say $file->slurp; # is a Mojo::File

    # same as above, but specifies dist explicitly
    my $file = dist_file('Foo-Bar', 'file.txt');

    # use path so there is only one arg and default dist is used
    my $file = dist_file(path('path', 'to', 'file.txt'));

    # or specify dist and path is not necessary
    my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

The ["dist\_file"](#dist_file) function takes one more more parameters. If one parameter is provided, the distribution will be determined
using the caller's package name. Then the provided argument will be used to find a file within the `share` directory
for that distribution. When you want to pass multiple arguments for the file path and you want to have the distribution
determined by ["dist\_file"](#dist_file), use ["path" in Mojo::File](https://metacpan.org/pod/Mojo::File#path) to wrap multiple arguments into one:

    # use path so there is only one arg and default dist based on the calling package is used
    my $file = dist_file(path('path', 'to', 'file.txt'));

If more than one argument is provided to ["dist\_file"](#dist_file), the first argument is the distribution and the remainder
will be passed to ["child" in Mojo::File](https://metacpan.org/pod/Mojo::File#child) on the [Mojo::File](https://metacpan.org/pod/Mojo::File) directory returned by ["dist\_dir"](#dist_dir):

    my $file = dist_file('Foo-Bar', 'path', 'to', 'file.txt');

Returns the file as a [Mojo::File](https://metacpan.org/pod/Mojo::File) returned by ["realpath" in Mojo::File](https://metacpan.org/pod/Mojo::File#realpath), or dies if it cannot be located or is not readable.

See ["DESCRIPTION"](#description) for an explanation on how ["dist\_file"](#dist_file) works better for local development and local distributions.

# LICENSE

Copyright (C) srchulo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

srchulo <srchulo@cpan.org>
