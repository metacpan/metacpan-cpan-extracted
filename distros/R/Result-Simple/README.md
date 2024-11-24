[![Actions Status](https://github.com/kfly8/Result-Simple/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Result-Simple/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Result-Simple/main.svg?style=flat)](https://coveralls.io/r/kfly8/Result-Simple?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Result-Simple.svg)](https://metacpan.org/release/Result-Simple)
# NAME

Result::Simple - A dead simple perl-ish Result like F#, Rust, Go, etc.

# SYNOPSIS

```perl
# Enable type check. The default is false.
BEGIN { $ENV{RESULT_SIMPLE_CHECK_ENABLED} = 1 }

use Test2::V0;
use Result::Simple;
use Types::Common -types;

use kura ErrorMessage => StrLength[3,];
use kura ValidName    => sub { my (undef, $e) = validate_name($_); !$e };
use kura ValidAge     => sub { my (undef, $e) = validate_age($_); !$e };
use kura ValidUser    => Dict[name => ValidName, age => ValidAge];

sub validate_name {
    my $name = shift;
    return Err('No name') unless defined $name;
    return Err('Empty name') unless length $name;
    return Err('Reserved name') if $name eq 'root';
    return Ok($name);
}

sub validate_age {
    my $age = shift;
    return Err('No age') unless defined $age;
    return Err('Invalid age') unless $age =~ /\A\d+\z/;
    return Err('Too young age') if $age < 18;
    return Ok($age);
}

sub new_user :Result(ValidUser, ArrayRef[ErrorMessage]) {
    my $args = shift;
    my @errors;

    my ($name, $name_err) = validate_name($args->{name});
    push @errors, $name_err if $name_err;

    my ($age, $age_err) = validate_age($args->{age});
    push @errors, $age_err if $age_err;

    return Err(\@errors) if @errors;
    return Ok({ name => $name, age => $age });
}

my ($user1, $err1) = new_user({ name => 'taro', age => 42 });
is $user1, { name => 'taro', age => 42 };
is $err1, undef;

my ($user2, $err2) = new_user({ name => 'root', age => 1 });
is $user2, undef;
is $err2, ['Reserved name', 'Too young age'];
```

# DESCRIPTION

Result::Simple is a dead simple Perl-ish Result.

Result represents a function's return value as success or failure, enabling safer error handling and more effective control flow management.
This pattern is used in other languages such as F#, Rust, and Go.

In Perl, this pattern is also useful, and this module provides a simple way to use it.
This module does not wrap a return value in an object. Just return a tuple like `($data, undef)` or `(undef, $err)`.

## EXPORT FUNCTIONS

### Ok

```perl
Ok($data)
# => ($data, undef)
```

Return a tuple of a given value and undef. When the function succeeds, it should return this.

### Err

```perl
Err($err)
# => (undef, $err)
```

Return a tuple of undef and a given error. When the function fails, it should return this.
Note that the error value must be a truthy value, otherwise it will throw an exception.

## ATTRIBUTES

### :Result(T, E)

You can use the `:Result(T, E)` attribute to define a function that returns a success or failure and asserts the return value types. Here is an example:

```perl
sub half :Result(Int, ErrorMessage) ($n) {
    if ($n % 2) {
        return Err('Odd number');
    } else {
        return Ok($n / 2);
    }
}
```

- T (success type)

    When the function succeeds, then returns `($data, undef)`, and `$data` should satisfy this type.

- E (error type)

    When the function fails, then returns `(undef, $err)`, and `$err` should satisfy this type.
    Additionally, type E must be truthy value to distinguish between success and failure.

    ```perl
    sub foo :Result(Int, Str) ($input) { }
    # => throw exception: Result E should not allow falsy values: ["0"] because Str allows "0"
    ```

    When a function never returns an error, you can set type E to `undef`:

    ```perl
    sub double :Result(Int, undef) ($n) { Ok($n * 2) }
    ```

Note that types require `check` method that returns true or false. So you can use your favorite type constraint module like
[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose](https://metacpan.org/pod/Moose), [Mouse](https://metacpan.org/pod/Mouse) or [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks) etc.

## ENVIRONMENTS

### `$ENV{RESULT_SIMPLE_CHECK_ENABLED}`

If the `ENV{RESULT_SIMPLE_CHECK_ENABLED}` environment is truthy before loading this module, it works as an assertion.
Otherwise, if it is falsy, `:Result(T, E)` attribute does nothing. The default is false.

```perl
sub invalid :Result(Int, undef) { Ok("hello") }

my ($data, $err) = invalid();
# => throw exception when check enabled
# => no exception when check disabled
```

The following code is an example to enable it:

```perl
BEGIN { $ENV{RESULT_SIMPLE_CHECK_ENABLED} = is_test ? 1 : 0 }
use Result::Simple;
```

This option is useful for development and testing mode, and it recommended to set it to false for production.

# NOTE

## What happens when you forget to call `Ok` or `Err`?

Forgetting to call `Ok` or `Err` function is a common mistake. Consider the following example:

```perl
sub validate_name :Result(Str, ErrorMessage) ($name) {
    return "Empty name" unless $name; # Oops! Forgot to call `Err` function.
    return Ok($name);
}

my ($name, $err) = validate_name('');
# => throw exception: Invalid result tuple (T, E)
```

In this case, the function throws an exception because the return value is not a valid result tuple `($data, undef)` or `(undef, $err)`.
This is fortunate, as the mistake is detected immediately. The following case is not detected:

```perl
sub foo :Result(Str, ErrorMessage) {
    return (undef, 'apple'); # No use of `Ok` or `Err` function.
}

my ($data, $err) = foo;
# => $err is 'apple'
```

Here, the function returns a valid failure tuple `(undef, $err)`. However, it is unclear whether this was intentional or a mistake.
The lack of `Ok` or `Err` makes the intent ambiguous.

Conclusively, be sure to use `Ok` or `Err` functions to make it clear whether the success or failure is intentional.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
