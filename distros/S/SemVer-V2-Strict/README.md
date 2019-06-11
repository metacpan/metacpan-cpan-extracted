[![Build Status](https://travis-ci.org/pine/p5-SemVer-V2-Strict.svg?branch=master)](https://travis-ci.org/pine/p5-SemVer-V2-Strict) [![Build Status](https://img.shields.io/appveyor/ci/pine/p5-SemVer-V2-Strict/master.svg?logo=appveyor)](https://ci.appveyor.com/project/pine/p5-SemVer-V2-Strict/branch/master) [![Coverage Status](http://codecov.io/github/pine/p5-SemVer-V2-Strict/coverage.svg?branch=master)](https://codecov.io/github/pine/p5-SemVer-V2-Strict?branch=master)
# NAME

SemVer::V2::Strict - Semantic version v2.0 object for Perl

# SYNOPSIS

    use SemVer::V2::Strict;

    my $v1 = SemVer::V2::Strict->new('1.0.2');
    my $v2 = SemVer::V2::Strict->new('2.0.0-alpha.10');

    if ($v1 < $v2) {
        print "$v1 < $v2\n"; # => '1.0.2 < 2.0.0-alpha.10'
    }

# DESCRIPTION

This module subclasses version to create semantic versions, as defined by the [Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html) Specification.

# METHODS

## CLASS METHODS

### `new()`

Create new empty `SemVer::V2::Strict` instance.
`SemVer::V2::Strict->new()` equals `SemVer::V2::Strict->new('0.0.0')`.

### `new($version_string)`

Create new `SemVer::V2::Strict` instance from a version string.
`SemVer::V2::Strict->new('1.0.0')` equals `SemVer::V2::Strict->new(1, 0, 0)`.

### `new($major, $minor = 0, $patch = 0, $pre_release = undef, $build_metadata = undef)`

Create new `SemVer::V2::Strict` instance from version numbers.
`SemVer::V2::Strict->new('1.0.0-alpha+100')` equals `SemVer::V2::Strict->new(1, 0, 0, 'alpha', '100')`.

### `clean($version_string)`

Clean version string. Trim spaces and `'v'` prefix.

### `sort(... $version_string)`

Sort version strings.

## METHODS

### `major`

Get the major version number.

### `minor`

Return the minor version number.

### `patch`

Return the patch version number.

### `pre_release`

Return the pre\_release string.

### `build_metadata`

Return the build\_metadata string.

### `<=>`

Compare two `SemVer::V2::Strict` instances.

### `""`

Convert a `SemVer::V2::Strict` instance to string.

### `as_string()`

Convert a `SemVer::V2::Strict` instance to string.

# SEE ALSO

- [SemVer](https://metacpan.org/pod/SemVer)
- [version](https://metacpan.org/pod/version)

# LICENSE

The MIT License (MIT)

Copyright (c) 2015-2019 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

# ACKNOWLEDGEMENT

`SemVer::V2::Strict` is based from rosylilly's [semver](https://github.com/rosylilly/semver).
Thank you.

# AUTHOR

Pine Mizune <pinemz@gmail.com>
