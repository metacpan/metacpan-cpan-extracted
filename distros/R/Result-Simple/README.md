[![Actions Status](https://github.com/kfly8/Result-Simple/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Result-Simple/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Result-Simple/main.svg?style=flat)](https://coveralls.io/r/kfly8/Result-Simple?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Result-Simple.svg)](https://metacpan.org/release/Result-Simple)
# NAME

Result::Simple - A dead simple perl-ish Result like F#, Rust, Go, etc.

# SYNOPSIS

```perl
use Result::Simple qw( ok err result_for chain pipeline);
use Types::Standard -types;

use kura Error   => Dict[message => Str];
use kura Request => Dict[name => Str, age => Int];

result_for validate_name => Request, Error;

sub validate_name {
    my $req = shift;
    my $name = $req->{name};
    return err({ message => 'No name'}) unless defined $name;
    return err({ message => 'Empty name'}) unless length $name;
    return err({ message => 'Reserved name'}) if $name eq 'root';
    return ok($req);
}

result_for validate_age => Request, Error;

sub validate_age {
    my $req = shift;
    my $age = $req->{age};
    return err({ message => 'No age'}) unless defined $age;
    return err({ message => 'Invalid age'}) unless $age =~ /\A\d+\z/;
    return err({ message => 'Too young age'}) if $age < 18;
    return ok($req);
}

result_for validate_req => Request, Error;

sub validate_req {
    my $req = shift;
    my $err;

    ($req, $err) = validate_name($req);
    return err($err) if $err;

    ($req, $err) = validate_age($req);
    return err($err) if $err;

    return ok($req);
}

# my $req = validate_req({ name => 'taro', age => 42 });
# => Throw an exception, because `validate_req` requires calling in a list context to handle an error.

my ($req1, $err1) = validate_req({ name => 'taro', age => 42 });
$req1 # => { name => 'taro', age => 42 };
$err1 # => undef;

my ($req2, $err2) = validate_req({ name => 'root', age => 20 });
$req2 # => undef;
$err2 # => { message => 'Reserved name' };

# Following are the same as above but using `chain` and `pipeline` helper functions.

sub validate_req_with_chain {
    my $req = shift;

    my @r = ok($req);
    @r = chain(validate_name => @r);
    @r = chain(validate_age => @r);
    return @r;
}

sub validate_req_with_pipeline {
    my $req = shift;

    state $code = pipeline qw( validate_name validate_age );
    $code->(ok($req));
}
```

# DESCRIPTION

Result::Simple is a dead simple Perl-ish Result.

Result represents a function's return value as success or failure, enabling safer error handling and more effective control flow management.
This pattern is used in other languages such as F#, Rust, and Go.

In Perl, this pattern is also useful, and this module provides a simple way to use it.
This module does not wrap a return value in an object. Just return a tuple like `($data, undef)` or `(undef, $err)`.

## FUNCTIONS

### ok($value)

Return a tuple of a given value and undef. When the function succeeds, it should return this.

```perl
sub add($a, $b) {
    ok($a + $b); # => ($a + $b, undef)
}
```

### err($error)

Return a tuple of undef and a given error. When the function fails, it should return this.

```perl
sub div($a, $b) {
    return err('Division by zero') if $b == 0; # => (undef, 'Division by zero')
    ok($a / $b);
}
```

Note that the error value must be a truthy value, otherwise it will throw an exception.

### result\_for $function\_name => $T, $E

You can use the `result_for` to define a function that returns a success or failure and asserts the return value types. Here is an example:

```perl
result_for half => Int, ErrorMessage;

sub half ($n) {
    if ($n % 2) {
        return err('Odd number');
    } else {
        return ok($n / 2);
    }
}
```

- T (success type)

    When the function succeeds, then returns `($data, undef)`, and `$data` should satisfy this type.

- E (error type)

    When the function fails, then returns `(undef, $err)`, and `$err` should satisfy this type.
    Additionally, type E must be truthy value to distinguish between success and failure.

    ```perl
    result_for foo => Int, Str;

    sub foo ($input) { }
    # => throw exception: Result E should not allow falsy values: ["0"] because Str allows "0"
    ```

    When a function never returns an error, you can set type E to `undef`:

    ```perl
    result_for bar => Int, undef;
    sub double ($n) { ok($n * 2) }
    ```

### chain($function, $data, $err)

`chain` is a helper function for passing result type `(T, E)` to the next function.

If an error has already occurred (when `$err` is defined), the new function won't be called and the same error will be returned as is.
If there's no error, the given function will be applied to `$data`, and its result `(T, E)` will be returned.

This is mainly suitable for use cases where functions need to be applied serially, such as in validation processing.

Example:

```perl
my @result = ok($req);
@result = chain(validate_name => @result);
@result = chain(validate_age  => @result);
return @result;
```

In this way, if a failure occurs along the way, the process stops at that point and the failure result is returned.

### pipeline(@functions)

`pipeline` is a helper function that generates a pipeline function that applies multiple functions in series.

It returns a new function that applies the given list of functions in order. This generated function takes an argument in the form of `(T, E)`,
and if an error occurs during the process, it immediately halts processing as a failure. If processing succeeds all the way through, it returns `ok($value)`.

Example:

```perl
state $code = pipeline qw( validate_name validate_age );
my ($req, $err) = $code->($input);
```

This allows you to describe multiple processes concisely as a single flow.
Each function in the pipeline needs to return `(T, E)`.

### combine(@results)

`combine` takes a list of Result like `((T1,E1), (T2,E2), (T3,E3))` and returns a new Result like `([T1,T2,T3], E)`.

If all Result values are successful, it returns a new Result with all success values collected into an array reference. If any Result has an error, the function short-circuits and returns the first error encountered.

This is useful when you need to collect the results of multiple operations that all need to succeed, similar to how `Promise.all` works in JavaScript. For example, when fetching data from multiple sources or validating multiple aspects of input data.

Example:

```perl
sub fetch_user { ... }       # Returns Result<User, Error>
sub fetch_orders { ... }     # Returns Result<Order[], Error>
sub fetch_settings { ... }   # Returns Result<Settings, Error>

my ($data, $err) = combine(
    fetch_user($user_id),
    fetch_orders($user_id),
    fetch_settings($user_id)
);

if ($err) {
    # Handle error
} else {
    my ($user, $orders, $settings) = @$data;
    # Process all successful results
}
```

### combine\_with\_all\_errors(@results)

`combine_with_all_errors` takes a list of Result like `((T1,E1), (T2,E2), (T3,E3))` and returns a new Result.

Unlike `combine` which stops at the first error, this function collects all errors from the input Results. If all Results are successful, it returns `([T1,T2,T3], undef)`. If any Results have errors, it returns `(undef, [E1,E2,E3])` with an array reference containing all encountered errors.

This is particularly useful for validation scenarios where you want to report all validation errors at once rather than one at a time. For example, when validating a form, you might want to show the user all fields that have errors rather than making them fix one error at a time.

Example:

```perl
sub validate_name { ... }    # Returns Result<Name, Error>
sub validate_email { ... }   # Returns Result<Email, Error>
sub validate_age { ... }     # Returns Result<Age, Error>

my ($data, $errors) = combine_with_all_errors(
    validate_name($form->{name}),
    validate_email($form->{email}),
    validate_age($form->{age})
);

if ($errors) {
    # Show all validation errors to the user
    for my $error (@$errors) {
        print "Error: $error->{message}\n";
    }
} else {
    my ($name, $email, $age) = @$data;
    # Process valid form data
}
```

### flatten(@results)

`flatten` takes a list of array references that contain Result tuples and flattens them into a single list of Result tuples.

For example, it converts `([T1,E1], [T2,E2], [T3,E3])` to `(T1,E1, T2,E2, T3,E3)`.

This is useful when you have multiple arrays of Results that you need to combine or process together.

Example:

```perl
my @result1 = ok(1);
my @result2 = ok(2);
my @result3 = ok(3);

my @all_results = flatten([\@result1], [\@result2], [\@result3]);
# @all_results is now (1,undef, 2,undef, 3,undef)

# You can use it with combine:
my ($values, $error) = combine(flatten([\@result1], [\@result2], [\@result3]));
# $values is [1, 2, 3], $error is undef
```

### match($on\_success, $on\_failure)

`match` provides a way to handle both success and failure cases of a Result in a functional style, similar to pattern matching in other languages.

It takes two callbacks:
\- `$on_success`: a function that receives the success value
\- `$on_failure`: a function that receives the error value

`match` returns a new function that will call the appropriate callback depending on whether the Result passed to it represents success or failure.

Example:

```perl
my $handler = match(
    sub { my $value = shift; "Success: The value is $value" },
    sub { my $error = shift; "Error: $error occurred" }
);

$handler->(ok(42));               # => Success: The value is 42
$handler->(err("Invalid input")); # => Error: Invalid input occurred
```

### unsafe\_unwrap($data, $err)

`unsafe_unwrap` takes a Result<T, E> and returns a T when the result is an Ok, otherwise it throws exception.
It should be used in tests or debugging code.

```perl
sub div($a, $b) {
    return err('Division by zero') if $b == 0;
    return ok($a / $b);
}

unsafe_unwrap(div(4, 2)); # => 2
unsafe_unwrap(div(4, 0)); # => throw an exception: Error called in `unsafe_unwrap`: "Division by zero"
```

### unsafe\_unwrap\_err($data, $err)

`unsafe_unwrap_err` takes a Result<T, E> and returns an E when the result is an Err, otherwise it throws exception.
It should be used in tests or debugging code.

```perl
sub div($a, $b) {
    return err('Division by zero') if $b == 0;
    return ok($a / $b);
}
unsafe_unwrap_err(div(4, 2)); # => throw an exception: No error called in `unsafe_unwrap_err`: 2
unsafe_unwrap_err(div(4, 0)); # => "Division by zero"
```

## ENVIRONMENTS

### `$ENV{RESULT_SIMPLE_CHECK_ENABLED}`

If the `ENV{RESULT_SIMPLE_CHECK_ENABLED}` environment is truthy before loading this module, it works as an assertion.
Otherwise, if it is falsy, `result_for` attribute does nothing. The default is true.
This option is useful for development and testing mode, and it recommended to set it to false for production.

```perl
result_for foo => Int, undef;
sub foo { ok("hello") }

my ($data, $err) = foo();
# => throw exception when check enabled
```

# NOTE

## Type constraint requires `check` method

Perl has many type constraint modules, but this module requires the type constraint module that provides `check` method.
So you can use [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose](https://metacpan.org/pod/Moose), [Mouse](https://metacpan.org/pod/Mouse) or [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks) etc.

## Use different function name

Sometimes, you may want to use a different name for `ok`, `err`, or some other functions of `Result::Simple`.
For example, `Test2::V0` has `ok` functions, so it conflicts with `ok` function of `Result::Simple`.
This module provides a way to set a different function name using the `-as` option.

```perl
use Result::Simple
    ok => { -as => 'left' },   # `left` is equivalent to `ok`
    err => { -as => 'right' }; # `right` is equivalent to `err`
```

## Check unhandled error

[Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AVariables%3A%3AProhibitUnusedVarsStricter) is useful to check unhandled error at compile time.

```perl
use Result::Simple;
my ($v, $e) = ok(2); # => Critic: $e is declared but not used (Variables::ProhibitUnusedVarsStricter, Severity: 3)
print $v;
```

## Using Result::Simple with Promises for asynchronous operations

Result::Simple can be combined with Promise-based asynchronous operations to create clean, functional error handling in asynchronous code. Here's an example using Mojo::Promise:

```perl
use Mojo::Promise;
use Mojo::UserAgent;
use Result::Simple qw(ok err combine flatten match);

my $ua = Mojo::UserAgent->new;

# Convert HTTP responses to Result tuples
sub fetch_result {
    my $uri = shift;
    $ua->get_p($uri)->then(
        sub {
            my $tx = shift;
            my $res = $tx->result;
            if ($res->is_success) {
                return ok($res->json);  # Success case with parsed JSON
            } else {
                return err({            # Error case with details
                    uri => $uri,
                    code => $res->code,
                });
            }
        }
    )->catch(
        sub {
            my $err = shift;
            return err($err);           # Connection/network errors
        }
    );
}

# Fetch a specific todo item
sub fetch_todo {
    my $id = shift;
    my $uri = "https://jsonplaceholder.typicode.com/todos/${id}";
    fetch_result($uri);
}

# Fetch multiple todos in parallel
Mojo::Promise->all(
    fetch_todo(1),
    fetch_todo(2),
)->then(
    sub {
        # Combine the results of multiple promises
        my ($todos, $err) = combine(flatten(@_));

        # Create a matcher to handle the combined result
        state $handler = match(
            sub {
                my $todos = shift;
                say "Successfully fetched all todos:";
                for my $todo (@$todos) {
                    say "- Todo #$todo->{id}: $todo->{title}";
                    say "  Completed: " . ($todo->{completed} ? "Yes" : "No");
                }
            },
            sub {
                my $error = shift;
                say "Error fetching todos:";
                if (ref $error eq 'HASH' && exists $error->{code}) {
                    say "HTTP $error->{code} error for $error->{uri}";
                } else {
                    say "Connection error: $error";
                }
            }
        );

        # Process the result
        $handler->($todos, $err);
    }
)->wait;
```

This pattern provides several benefits:

- Clear separation between success and error cases
- Consistent error handling across both synchronous and asynchronous code
- Ability to combine multiple asynchronous operations and handle their results uniformly
- More expressive and maintainable code through functional composition

The combination of `flatten`, `combine`, and `match` makes it easy to work with multiple promises while maintaining clean error handling.

## Avoiding Ambiguity in Result Handling

Forgetting to call `ok` or `err` function is a common mistake. Consider the following example:

```perl
result_for validate_name => Str, ErrorMessage;

sub validate_name ($name) {
    return "Empty name" unless $name; # Oops! Forgot to call `err` function.
    return ok($name);
}

my ($name, $err) = validate_name('');
# => throw exception: Invalid result tuple (T, E)
```

In this case, the function throws an exception because the return value is not a valid result tuple `($data, undef)` or `(undef, $err)`.
This is fortunate, as the mistake is detected immediately. The following case is not detected:

```perl
result_for foo => Str, ErrorMessage;

sub foo {
    return (undef, 'apple'); # No use of `ok` or `err` function.
}

my ($data, $err) = foo;
# => $err is 'apple'
```

Here, the function returns a valid failure tuple `(undef, $err)`. However, it is unclear whether this was intentional or a mistake.
The lack of `ok` or `err` makes the intent ambiguous.

Conclusively, be sure to use `ok` or `err` functions to make it clear whether the success or failure is intentional.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
