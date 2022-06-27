# NAME

Specio::Library::Path::Tiny - Path::Tiny types and coercions for Specio

# VERSION

version 0.05

# SYNOPSIS

    use Specio::Library::Path::Tiny;

    has path => ( isa => t('Path') );

# DESCRIPTION

This library provides a set of [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) types and coercions for [Specio](https://metacpan.org/pod/Specio).
These types can be used with [Moose](https://metacpan.org/pod/Moose), [Moo](https://metacpan.org/pod/Moo), [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler),
and other modules.

# TYPES

This library provides the following types:

## Path

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object.

Will be coerced from a string or arrayref via `Path::Tiny::path`.

## AbsPath

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object where `$path->is_absolute` returns true.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->absolute`.

## RealPath

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object where `$path->realpath eq $path`.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->realpath`.

## File

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a file on disk according to `$path->is_file`.

Will be coerced from a string or arrayref via `Path::Tiny::path`.

## AbsFile

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a file on disk according to `$path->is_file` where `$path->is_absolute` returns true.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->absolute`.

## RealFile

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a file on disk according to `$path->is_file` where `$path->realpath eq $path`.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->realpath`.

## Dir

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a directory on disk according to `$path->is_dir`.

Will be coerced from a string or arrayref via `Path::Tiny::path`.

## AbsDir

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a directory on disk according to `$path->is_dir` where `$path->is_absolute` returns true.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->absolute`.

## RealDir

A [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object which is a directory on disk according to `$path->is_dir` where `$path->realpath eq $path`.

Will be coerced from a string or arrayref via `Path::Tiny::path` followed by
call to `$path->realpath`.

# CREDITS

The vast majority of the code in this distribution comes from David Golden's
[Types::Path::Tiny](https://metacpan.org/pod/Types%3A%3APath%3A%3ATiny) distribution.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Specio-Library-Path-Tiny/issues](https://github.com/houseabsolute/Specio-Library-Path-Tiny/issues).

# SOURCE

The source code repository for Specio-Library-Path-Tiny can be found at [https://github.com/houseabsolute/Specio-Library-Path-Tiny](https://github.com/houseabsolute/Specio-Library-Path-Tiny).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://www.urth.org/fs-donation.html](https://www.urth.org/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Paulo Custodio <pauloscustodio@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2022 by Dave Rolsky.

This is free software, licensed under:

    The Apache License, Version 2.0, January 2004

The full text of the license can be found in the
`LICENSE` file included with this distribution.
