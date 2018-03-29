[![Build Status](https://travis-ci.org/pine/p5-Scope-UndefSafe.svg?branch=master)](https://travis-ci.org/pine/p5-Scope-UndefSafe) [![Build Status](https://img.shields.io/appveyor/ci/pine/p5-Scope-UndefSafe/master.svg?logo=appveyor)](https://ci.appveyor.com/project/pine/p5-Scope-UndefSafe/branch/master) [![Coverage Status](http://codecov.io/github/pine/p5-Scope-UndefSafe/coverage.svg?branch=master)](https://codecov.io/github/pine/p5-Scope-UndefSafe?branch=master)
# NAME

Scope::UndefSafe - The functions to limit the scope.

# SYNOPSIS

    use Scope::UndefSafe qw/let apply/;

    my $obj = AnyObject->new;
    let { $_->method() } $obj; # `method` is executed.
    apply { $_->method() } $obj; # `method` is executed, and return $obj.

    $obj = undef;
    let { $_->method() } $obj; # `method` is not executed.
    apply { $_->method() } $obj; # `method` is not executedm, but return $obj.

# DESCRIPTION

Scope::UndefSafe has two functions to limit scope undef safety.

## METHODS

### `let`

Invoke block if pass non undef value as second argument.
And return block returned value.

The following two are the same behavior.

    let { $_->method() } $obj;
    $obj ? $obj->method() : undef;

### `apply`

Invoke block if pass non undef value as a second argument.
And return a second argument.

The following two are the same behavior.

    apply { $_->method() } $obj;
    $obj ? do { $obj->method(); $obj } : undef;

# SEE ALSO

- [stdlib.kotlin.let](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html)
- [stdlib.kotlin.apply](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/apply.html)

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 Pine Mizune

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

# AUTHOR

Pine Mizune <pinemz@gmail.com>
