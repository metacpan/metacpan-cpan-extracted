package Result::Simple;
use strict;
use warnings;

our $VERSION = "0.06";

use Exporter::Shiny qw(
    ok
    err
    result_for
    chain
    pipeline
    combine
    combine_with_all_errors
    flatten
    match
    unsafe_unwrap
    unsafe_unwrap_err
);

use Carp;
use Scope::Upper ();
use Sub::Util ();
use Scalar::Util ();

# If this option is true, then check `ok` and `err` functions usage and check a return value type.
# However, it should be falsy for production code, because of performance, and it is an assertion, not a validation.
use constant CHECK_ENABLED => $ENV{RESULT_SIMPLE_CHECK_ENABLED} // 1;

# err does not allow these values.
use constant FALSY_VALUES => [0, '0', '', undef];

# When the function is successful, it should return this.
sub ok {
    if (CHECK_ENABLED) {
        croak "`ok` must be called in list context" unless wantarray;
        croak "`ok` does not allow multiple arguments" if @_ > 1;
        croak "`ok` does not allow no arguments" if @_ == 0;
    }
    ($_[0], undef)
}

# When the function fails, it should return this.
sub err {
    if (CHECK_ENABLED) {
        croak "`err` must be called in list context" unless wantarray;
        croak "`err` does not allow multiple arguments." if @_ > 1;
        croak "`err` does not allow no arguments" if @_ == 0;
        croak "`err` does not allow a falsy value: @{[ _ddf($_[0]) ]}" unless $_[0];
    }
    (undef, $_[0])
}

# result_for foo => (T, E);
# This is used to define a function that returns a success or failure.
#
# Example
#
#   result_for div => Int, ErrorMessage;
#
#   sub div {
#     my ($a, $b) = @_;
#     if ($b == 0) {
#       return err('Division by zero');
#     }
#     return ok($a / $b);
#   }
sub result_for {
    unless (CHECK_ENABLED) {
        # This is a no-op if CHECK_ENABLED is false.
        return;
    }

    my ($function_name, $T, $E, %opts) = @_;

    my @caller   = caller($opts{caller_level} || 0);
    my $package  = $opts{package} || $caller[0];
    my $filename = $caller[1];
    my $line     = $caller[2];

    my $code = $package->can($function_name);

    unless ($code) {
        croak "result_for: function `$function_name` not found in package `$package` at $filename line $line\n";
    }

    unless (Scalar::Util::blessed($T) && $T->can('check')) {
        croak "result_for T requires `check` method, got: @{[ _ddf($T) ]} at $filename line $line\n";
    }

    if (defined $E) {
        unless (Scalar::Util::blessed($E) && $E->can('check')) {
            croak "result_for E requires `check` method, got: @{[ _ddf($E) ]} at $filename line $line\n";
        }

        if (my @f = grep { $E->check($_) } @{ FALSY_VALUES() }) {
            croak "result_for E should not allow falsy values: @{[ _ddf(\@f) ]} at $filename line $line\n";
        }
    }

    wrap_code($code, $package, $function_name, $T, $E);
}

# Wrap the original coderef with type check.
sub wrap_code {
    my ($code, $package, $name, $T, $E) = @_;

    my $wrapped = sub {
        croak "Must handle error in `$name`" unless wantarray;

        my @result = &Scope::Upper::uplevel($code, @_, &Scope::Upper::CALLER(0));
        unless (@result == 2) {
            Carp::confess "Invalid result tuple (T, E) in `$name`. Do you forget to call `ok` or `err` function? Got: @{[ _ddf(\@result) ]}";
        }

        my ($data, $err) = @result;

        if ($err) {
            if (defined $E) {
                if (!$E->check($err) || defined $data) {
                    Carp::confess "Invalid failure result in `$name`: @{[ _ddf([$data, $err]) ]}";
                }
            } else {
                # Result(T, undef) should not return an error.
                Carp::confess "Never return error in `$name`: @{[ _ddf([$data, $err]) ]}";
            }
        } else {
            if (!$T->check($data) || defined $err) {
                Carp::confess "Invalid success result in `$name`: @{[ _ddf([$data, $err]) ]}";
            }
        }

        ($data, $err);
    };

    my $fullname = "$package\::$name";
    Sub::Util::set_subname($fullname, $wrapped);

    my $prototype = Sub::Util::prototype($code);
    if (defined $prototype) {
        Sub::Util::set_prototype($prototype, $wrapped);
    }

    no strict qw(refs);
    no warnings qw(redefine);
    *{$fullname} = $wrapped;
}

# `chain` takes a function name and a result tuple (T, E) and returns a new result tuple (T, E).
sub chain {
    my ($function, $value, $error) = @_;

    if (CHECK_ENABLED) {
        croak "`chain` must be called in list context" unless wantarray;
        croak "`chain` arguments must be func and result like (func, T, E)" unless @_ == 3;
    }

    my $code = ref $function ? $function : do {
        my $caller = caller(0);
        $caller->can($function) or croak "Function `$function` not found in $caller";
    };
    return err($error) if $error;
    return $code->($value);
}

# `pipeline` takes a list of function names and returns a new function.
sub pipeline {
    my (@functions) = @_;

    my @codes = map {
        my $f = $_;
        ref $f ? $f : do {
            my $caller = caller(0);
            $caller->can($f) or croak "Function `$f` not found in $caller";
        };
    } @functions;

    my $pipelined = sub {
        my ($value, $error) = @_;

        if (CHECK_ENABLED) {
            croak "pipelined function must be called in list context" unless wantarray;
            croak "pipelined function arguments must be result such as (T, E) " unless @_ == 2;
        }

        return err($error) if $error;
        for my $code (@codes) {
            ($value, $error) = $code->($value);
            return err($error) if $error;
        }
        return ok($value);
    };

    my $package = caller(0);
    my $fullname = "$package\::__PIPELINED_FUNCTION__";
    Sub::Util::set_subname($fullname, $pipelined);

    return $pipelined;
}

# `combine` takes a list of Result like `((T1,E1), (T2,E2), (T3,E3))` and returns a new Result like `([T1,T2,T3], E)`.
sub combine {
    my @results = @_;

    if (CHECK_ENABLED) {
        croak "`combine` must be called in list context" unless wantarray;
        croak "`combine` arguments must be Result list" unless @_ % 2 == 0;
    }

    my @values;
    for (my $i = 0; $i < @results; $i += 2) {
        my ($value, $error) = @results[$i, $i + 1];
        if ($error) {
            return err($error);
        }
        push @values, $value;
    }
    return ok(\@values);
}

# `combine_with_all_errors` takes a list of Result like `((T1,E1), (T2,E2), (T3,E3))` and returns a new Result like `([T1,T2,T3], [E1,E2,E3])`.
sub combine_with_all_errors {
    my @results = @_;

    if (CHECK_ENABLED) {
        croak "`combine_with_all_errors` must be called in list context" unless wantarray;
        croak "`combine_with_all_errors` arguments must be Result list" unless @_ % 2 == 0;
    }

    my @values;
    my @errors;
    for (my $i = 0; $i < @results; $i += 2) {
        my ($value, $err) = @results[$i, $i + 1];
        if ($err) {
            push @errors, $err;
        } else {
            push @values, $value;
        }
    }
    return err(\@errors) if @errors;
    return ok(\@values);
}

# `flatten` takes a list of Result like `([T1,E1], [T2,E2], [T3,E3])` and returns a new Result like ((T1,E1), (T2,E2), (T3,E3)).
sub flatten {
    map { ref $_ && ref $_ eq 'ARRAY' ? @$_ : $_ } @_;
}

# `match` takes two coderefs for on success and on failure, and returns a new function.
sub match {
    my ($on_success, $on_failure) = @_;

    if (CHECK_ENABLED) {
        croak "`match` arguments must be two coderefs for on success and on error" unless _is_callable($on_success) && _is_callable($on_failure);
    }

    my $match = sub {
        my ($value, $err) = @_;

        if (CHECK_ENABLED) {
            croak "`match` function arguments must be result like (T, E)" unless @_ == 2;
        }

        if ($err) {
            return $on_failure->($err);
        } else {
            return $on_success->($value);
        }
    };

    my $package = caller(0);
    my $fullname = "$package\::__MATCHER_FUNCTION__";
    Sub::Util::set_subname($fullname, $match);

    return $match;
}

# `unsafe_nwrap` takes a Result<T, E> and returns a T when the result is an Ok, otherwise it throws exception.
# It should be used in tests or debugging code.
sub unsafe_unwrap {
    my ($value, $err) = @_;
    if ($err) {
        croak "Error called in `unsafe_unwrap`: @{[ _ddf($err) ]}"
    }
    return $value;
}

# `unsafe_unwrap_err` takes a Result<T, E> and returns an E when the result is an Err, otherwise it throws exception.
# It should be used in tests or debugging code.
sub unsafe_unwrap_err {
    my ($value, $err) = @_;
    if (!$err) {
        croak "No error called in `unsafe_unwrap_err`: @{[ _ddf($value) ]}"
    }
    return $err;
}

# Dump data for debugging.
sub _ddf {
    my $v = shift;

    no warnings 'once';
    require Data::Dumper;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Useqq    = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Maxdepth = 2;
    Data::Dumper::Dumper($v);
}

# Check if the argument is a callable.
sub _is_callable {
    my $code = shift;
    (Scalar::Util::reftype($code)||'') eq 'CODE'
}

1;
__END__

=encoding utf-8

=head1 NAME

Result::Simple - A dead simple perl-ish Result like F#, Rust, Go, etc.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Result::Simple is a dead simple Perl-ish Result.

Result represents a function's return value as success or failure, enabling safer error handling and more effective control flow management.
This pattern is used in other languages such as F#, Rust, and Go.

In Perl, this pattern is also useful, and this module provides a simple way to use it.
This module does not wrap a return value in an object. Just return a tuple like C<($data, undef)> or C<(undef, $err)>.

=head2 FUNCTIONS

=head3 ok($value)

Return a tuple of a given value and undef. When the function succeeds, it should return this.

    sub add($a, $b) {
        ok($a + $b); # => ($a + $b, undef)
    }

=head3 err($error)

Return a tuple of undef and a given error. When the function fails, it should return this.

    sub div($a, $b) {
        return err('Division by zero') if $b == 0; # => (undef, 'Division by zero')
        ok($a / $b);
    }

Note that the error value must be a truthy value, otherwise it will throw an exception.

=head3 result_for $function_name => $T, $E

You can use the C<result_for> to define a function that returns a success or failure and asserts the return value types. Here is an example:

    result_for half => Int, ErrorMessage;

    sub half ($n) {
        if ($n % 2) {
            return err('Odd number');
        } else {
            return ok($n / 2);
        }
    }

=over 2

=item T (success type)

When the function succeeds, then returns C<($data, undef)>, and C<$data> should satisfy this type.

=item E (error type)

When the function fails, then returns C<(undef, $err)>, and C<$err> should satisfy this type.
Additionally, type E must be truthy value to distinguish between success and failure.

    result_for foo => Int, Str;

    sub foo ($input) { }
    # => throw exception: Result E should not allow falsy values: ["0"] because Str allows "0"

When a function never returns an error, you can set type E to C<undef>:

    result_for bar => Int, undef;
    sub double ($n) { ok($n * 2) }

=back

=head3 chain($function, $data, $err)

C<chain> is a helper function for passing result type C<(T, E)> to the next function.

If an error has already occurred (when C<$err> is defined), the new function won't be called and the same error will be returned as is.
If there's no error, the given function will be applied to C<$data>, and its result C<(T, E)> will be returned.

This is mainly suitable for use cases where functions need to be applied serially, such as in validation processing.

Example:

    my @result = ok($req);
    @result = chain(validate_name => @result);
    @result = chain(validate_age  => @result);
    return @result;

In this way, if a failure occurs along the way, the process stops at that point and the failure result is returned.

=head3 pipeline(@functions)

C<pipeline> is a helper function that generates a pipeline function that applies multiple functions in series.

It returns a new function that applies the given list of functions in order. This generated function takes an argument in the form of C<(T, E)>,
and if an error occurs during the process, it immediately halts processing as a failure. If processing succeeds all the way through, it returns C<ok($value)>.

Example:

    state $code = pipeline qw( validate_name validate_age );
    my ($req, $err) = $code->($input);

This allows you to describe multiple processes concisely as a single flow.
Each function in the pipeline needs to return C<(T, E)>.

=head3 combine(@results)

C<combine> takes a list of Result like C<((T1,E1), (T2,E2), (T3,E3))> and returns a new Result like C<([T1,T2,T3], E)>.

If all Result values are successful, it returns a new Result with all success values collected into an array reference. If any Result has an error, the function short-circuits and returns the first error encountered.

This is useful when you need to collect the results of multiple operations that all need to succeed, similar to how C<Promise.all> works in JavaScript. For example, when fetching data from multiple sources or validating multiple aspects of input data.

Example:

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

=head3 combine_with_all_errors(@results)

C<combine_with_all_errors> takes a list of Result like C<((T1,E1), (T2,E2), (T3,E3))> and returns a new Result.

Unlike C<combine> which stops at the first error, this function collects all errors from the input Results. If all Results are successful, it returns C<([T1,T2,T3], undef)>. If any Results have errors, it returns C<(undef, [E1,E2,E3])> with an array reference containing all encountered errors.

This is particularly useful for validation scenarios where you want to report all validation errors at once rather than one at a time. For example, when validating a form, you might want to show the user all fields that have errors rather than making them fix one error at a time.

Example:

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

=head3 flatten(@results)

C<flatten> takes a list of array references that contain Result tuples and flattens them into a single list of Result tuples.

For example, it converts C<([T1,E1], [T2,E2], [T3,E3])> to C<(T1,E1, T2,E2, T3,E3)>.

This is useful when you have multiple arrays of Results that you need to combine or process together.

Example:

    my @result1 = ok(1);
    my @result2 = ok(2);
    my @result3 = ok(3);

    my @all_results = flatten([\@result1], [\@result2], [\@result3]);
    # @all_results is now (1,undef, 2,undef, 3,undef)

    # You can use it with combine:
    my ($values, $error) = combine(flatten([\@result1], [\@result2], [\@result3]));
    # $values is [1, 2, 3], $error is undef

=head3 match($on_success, $on_failure)

C<match> provides a way to handle both success and failure cases of a Result in a functional style, similar to pattern matching in other languages.

It takes two callbacks:
- C<$on_success>: a function that receives the success value
- C<$on_failure>: a function that receives the error value

C<match> returns a new function that will call the appropriate callback depending on whether the Result passed to it represents success or failure.

Example:

    my $handler = match(
        sub { my $value = shift; "Success: The value is $value" },
        sub { my $error = shift; "Error: $error occurred" }
    );

    $handler->(ok(42));               # => Success: The value is 42
    $handler->(err("Invalid input")); # => Error: Invalid input occurred

=head3 unsafe_unwrap($data, $err)

C<unsafe_unwrap> takes a Result<T, E> and returns a T when the result is an Ok, otherwise it throws exception.
It should be used in tests or debugging code.

    sub div($a, $b) {
        return err('Division by zero') if $b == 0;
        return ok($a / $b);
    }

    unsafe_unwrap(div(4, 2)); # => 2
    unsafe_unwrap(div(4, 0)); # => throw an exception: Error called in `unsafe_unwrap`: "Division by zero"

=head3 unsafe_unwrap_err($data, $err)

C<unsafe_unwrap_err> takes a Result<T, E> and returns an E when the result is an Err, otherwise it throws exception.
It should be used in tests or debugging code.

    sub div($a, $b) {
        return err('Division by zero') if $b == 0;
        return ok($a / $b);
    }
    unsafe_unwrap_err(div(4, 2)); # => throw an exception: No error called in `unsafe_unwrap_err`: 2
    unsafe_unwrap_err(div(4, 0)); # => "Division by zero"

=head2 ENVIRONMENTS

=head3 C<$ENV{RESULT_SIMPLE_CHECK_ENABLED}>

If the C<ENV{RESULT_SIMPLE_CHECK_ENABLED}> environment is truthy before loading this module, it works as an assertion.
Otherwise, if it is falsy, C<result_for> attribute does nothing. The default is true.
This option is useful for development and testing mode, and it recommended to set it to false for production.

    result_for foo => Int, undef;
    sub foo { ok("hello") }

    my ($data, $err) = foo();
    # => throw exception when check enabled

=head1 NOTE

=head2 Type constraint requires C<check> method

Perl has many type constraint modules, but this module requires the type constraint module that provides C<check> method.
So you can use L<Type::Tiny>, L<Moose>, L<Mouse> or L<Data::Checks> etc.

=head2 Use different function name

Sometimes, you may want to use a different name for C<ok>, C<err>, or some other functions of C<Result::Simple>.
For example, C<Test2::V0> has C<ok> functions, so it conflicts with C<ok> function of C<Result::Simple>.
This module provides a way to set a different function name using the C<-as> option.

    use Result::Simple
        ok => { -as => 'left' },   # `left` is equivalent to `ok`
        err => { -as => 'right' }; # `right` is equivalent to `err`

=head2 Check unhandled error

L<Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter> is useful to check unhandled error at compile time.

    use Result::Simple;
    my ($v, $e) = ok(2); # => Critic: $e is declared but not used (Variables::ProhibitUnusedVarsStricter, Severity: 3)
    print $v;

=head2 Using Result::Simple with Promises for asynchronous operations

Result::Simple can be combined with Promise-based asynchronous operations to create clean, functional error handling in asynchronous code. Here's an example using Mojo::Promise:

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

This pattern provides several benefits:

=over 4

=item Clear separation between success and error cases

=item Consistent error handling across both synchronous and asynchronous code

=item Ability to combine multiple asynchronous operations and handle their results uniformly

=item More expressive and maintainable code through functional composition

=back

The combination of C<flatten>, C<combine>, and C<match> makes it easy to work with multiple promises while maintaining clean error handling.

=head2 Avoiding Ambiguity in Result Handling

Forgetting to call C<ok> or C<err> function is a common mistake. Consider the following example:

    result_for validate_name => Str, ErrorMessage;

    sub validate_name ($name) {
        return "Empty name" unless $name; # Oops! Forgot to call `err` function.
        return ok($name);
    }

    my ($name, $err) = validate_name('');
    # => throw exception: Invalid result tuple (T, E)

In this case, the function throws an exception because the return value is not a valid result tuple C<($data, undef)> or C<(undef, $err)>.
This is fortunate, as the mistake is detected immediately. The following case is not detected:

    result_for foo => Str, ErrorMessage;

    sub foo {
        return (undef, 'apple'); # No use of `ok` or `err` function.
    }

    my ($data, $err) = foo;
    # => $err is 'apple'

Here, the function returns a valid failure tuple C<(undef, $err)>. However, it is unclear whether this was intentional or a mistake.
The lack of C<ok> or C<err> makes the intent ambiguous.

Conclusively, be sure to use C<ok> or C<err> functions to make it clear whether the success or failure is intentional.

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

