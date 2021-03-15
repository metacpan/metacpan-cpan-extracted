# NAME

Path::Tiny::Archive::Zip - Zip/unzip add-on for file path utility

# VERSION

version 0.004

# SYNOPSIS

    use Path::Tiny
    use Path::Tiny::Archive::Zip qw( :const );

    path("foo/bar.txt")->zip("foo/bar.zip", COMPRESSION_BEST);
    path("foo/bar.zip")->unzip("baz");

# DESCRIPTION

This module provides two additional methods for [Path::Tiny](https://metacpan.org/pod/Path::Tiny) for working with
zip archives.

# METHODS

## zip

    path("/tmp/foo.txt")->zip("/tmp/foo.zip");
    path("/tmp/foo")->zip("/tmp/foo.zip");

Creates a zip archive and appends a file or directory tree to it. Returns the
path to the zip archive or undef.

You can choose different compression levels.

    path("/tmp/foo")->zip("/tmp/foo.zip", COMPRESSION_FASTEST);

The levels given can be:

- `0` or `COMPRESSION_NONE`: No compression.
- `1` to `9`: 1 gives the best speed and worst compression, and 9 gives
the best compression and worst speed.
- `COMPRESSION_FASTEST`: This is a synonym for level 1.
- `COMPRESSION_BEST`: This is a synonym for level 9.
- `COMPRESSION_DEFAULT`: This gives a good compromise between speed and
compression, and is currently equivalent to 6 (this is in the zlib code). This
is the level that will be used if not specified.

## unzip

    path("/tmp/foo.zip")->unzip("/tmp/foo");

Extracts a zip archive to specified directory. Returns the path to the
destination directory or undef.

# AUTHOR

Denis Ibaev <dionys@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Denis Ibaev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
