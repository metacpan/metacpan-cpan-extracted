# NAME

Path::Tiny::Archive::Tar - Tar/untar add-on for file path utility

# VERSION

version 0.003

# SYNOPSIS

    use Path::Tiny
    use Path::Tiny::Archive::Tar qw( :const );

    path("foo/bar.txt")->tar("foo/bar.tgz", COMPRESSION_GZIP);
    path("foo/bar.zip")->untar("baz");

# DESCRIPTION

This module provides two additional methods for [Path::Tiny](https://metacpan.org/pod/Path::Tiny) for working with
tar archives.

# METHODS

## tar

    path("/tmp/foo.txt")->tar("/tmp/foo.tar");
    path("/tmp/foo")->tar("/tmp/foo.tar.gz", COMPRESSION_GZIP);

Creates a tar archive and appends a file or directory tree to it. Returns the
path to the archive or undef.

You can choose different compression types and levels.

    path("/tmp/foo")->zip("/tmp/foo.tgz", COMPRESSION_GZIP);

The types and levels given can be:

- `COMPRESSION_NONE`: No compression. This is the type that will be used
if not specified.
- `COMPRESSION_GZIP`: Compress using `gzip`.
    - `1` to `9`: This is `gzip` compression levels. 1 gives the best
    speed and worst compression, and 9 gives the best compression and worst speed.
    - `COMPRESSION_GZIP_NONE`: This is a synonym for `gzip` level 0. No
    compression.
    - `COMPRESSION_GZIP_FASTEST`: This is a synonym for `gzip` level 1.
    - `COMPRESSION_GZIP_BEST`: This is a synonym for `gzip` level 9.
    - `COMPRESSION_GZIP_DEFAULT`: This gives a good compromise between speed
    and compression for `gzip`, and is currently equivalent to 6 (this is in the
    zlib code). This is a synonym for `COMPRESSION_GZIP`.
- `COMPRESSION_BZIP2`: Compress using `bzip2`.

## tgz

    path("/tmp/foo.txt")->tgz("/tmp/foo.tar.gz");

Method `tgz` is synonym for `tar` with `COMPRESSION_GZIP` type.

## tbz2

    path("/tmp/foo.txt")->tbz2("/tmp/foo.tar.bzip2");

Method `tbz2` is synonym for `tar` with `COMPRESSION_BZIP2` type.

## untar

    path("/tmp/foo.tar")->untar("/tmp/foo");

Extracts a tar archive to specified directory. Returns the path to the
destination directory or undef.

# AUTHOR

Denis Ibaev <dionys@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Denis Ibaev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
