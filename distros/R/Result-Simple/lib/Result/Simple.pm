package Result::Simple;
use strict;
use warnings;

our $VERSION = "0.03";

use Exporter 'import';

our @EXPORT = qw( Ok Err _ATTR_CODE_Result );

use Carp;
use Attribute::Handlers;
use Scope::Upper ();
use Sub::Util ();
use Scalar::Util ();

# If this option is true, then check `Ok` and `Err` functions usage and check a return value type.
# However, it should be falsy for production code, because of performance and it is an assertion, not a validation.
use constant CHECK_ENABLED => $ENV{RESULT_SIMPLE_CHECK_ENABLED} // 0;

# Err does not allow these values.
use constant FALSY_VALUES => [0, '0', '', undef];

# When the function is successful, it should return this.
sub Ok {
    if (CHECK_ENABLED) {
        croak "`Ok` must be called in list context" unless wantarray;
        croak "`Ok` does not allow multiple arguments" if @_ > 1;
        croak "`Ok` does not allow no arguments" if @_ == 0;
    }
    ($_[0], undef)
}

# When the function fails, it should return this.
sub Err {
    if (CHECK_ENABLED) {
        croak "`Err` must be called in list context" unless wantarray;
        croak "`Err` does not allow multiple arguments." if @_ > 1;
        croak "`Err` does not allow no arguments" if @_ == 0;
        croak "`Err` does not allow a falsy value: @{[ _ddf($_[0]) ]}" unless $_[0];
    }
    (undef, $_[0])
}

# This attribute is used to define a function that returns a success or failure.
# Example: `sub foo :Result(Int, Error)  { ... }`
sub Result : ATTR(CODE) {
    return unless CHECK_ENABLED;

    my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $line) = @_;
    my $name = *{$symbol}{NAME};

    my ($T, $E) = @$data;
    unless (Scalar::Util::blessed($T) && $T->can('check')) {
        croak "Result T requires `check` method, got: @{[ _ddf($T) ]} at $filename line $line\n";
    }

    if (defined $E) {
        unless (Scalar::Util::blessed($E) && $E->can('check')) {
            croak "Result E requires `check` method, got: @{[ _ddf($E) ]} at $filename line $line\n";
        }

        if (my @f = grep { $E->check($_) } @{ FALSY_VALUES() }) {
            croak "Result E should not allow falsy values: @{[ _ddf(\@f) ]} at $filename line $line\n";
        }
    }

    wrap_code($referent, $package, $name, $T, $E);
}

# Wrap the original coderef with type check.
sub wrap_code {
    my ($code, $package, $name, $T, $E) = @_;

    my $wrapped = sub {
        croak "Must handle error in `$name`" unless wantarray;

        my @result = &Scope::Upper::uplevel($code, @_, &Scope::Upper::CALLER(0));
        unless (@result == 2) {
            Carp::confess "Invalid result tuple (T, E) in `$name`. Do you forget to call `Ok` or `Err` function? Got: @{[ _ddf(\@result) ]}";
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

1;
__END__

=encoding utf-8

=head1 NAME

Result::Simple - A dead simple perl-ish Result like F#, Rust, Go, etc.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Result::Simple is a dead simple Perl-ish Result.

Result represents a function's return value as success or failure, enabling safer error handling and more effective control flow management.
This pattern is used in other languages such as F#, Rust, and Go.

In Perl, this pattern is also useful, and this module provides a simple way to use it.
This module does not wrap a return value in an object. Just return a tuple like C<($data, undef)> or C<(undef, $err)>.

=head2 EXPORT FUNCTIONS

=head3 Ok

Return a tuple of a given value and undef. When the function succeeds, it should return this.

    sub add($a, $b) {
        Ok($a + $b); # => ($a + $b, undef)
    }

=head3 Err

Return a tuple of undef and a given error. When the function fails, it should return this.

    sub div($a, $b) {
        return Err('Division by zero') if $b == 0; # => (undef, 'Division by zero')
        Ok($a / $b);
    }

Note that the error value must be a truthy value, otherwise it will throw an exception.

=head2 ATTRIBUTES

=head3 :Result(T, E)

You can use the C<:Result(T, E)> attribute to define a function that returns a success or failure and asserts the return value types. Here is an example:

    sub half :Result(Int, ErrorMessage) ($n) {
        if ($n % 2) {
            return Err('Odd number');
        } else {
            return Ok($n / 2);
        }
    }

=over 2

=item T (success type)

When the function succeeds, then returns C<($data, undef)>, and C<$data> should satisfy this type.

=item E (error type)

When the function fails, then returns C<(undef, $err)>, and C<$err> should satisfy this type.
Additionally, type E must be truthy value to distinguish between success and failure.

    sub foo :Result(Int, Str) ($input) { }
    # => throw exception: Result E should not allow falsy values: ["0"] because Str allows "0"

When a function never returns an error, you can set type E to C<undef>:

    sub double :Result(Int, undef) ($n) { Ok($n * 2) }

=back

Note that types require C<check> method that returns true or false. So you can use your favorite type constraint module like
L<Type::Tiny>, L<Moose>, L<Mouse> or L<Data::Checks> etc.

=head2 ENVIRONMENTS

=head3 C<$ENV{RESULT_SIMPLE_CHECK_ENABLED}>

If the C<ENV{RESULT_SIMPLE_CHECK_ENABLED}> environment is truthy before loading this module, it works as an assertion.
Otherwise, if it is falsy, C<:Result(T, E)> attribute does nothing. The default is false.

    sub invalid :Result(Int, undef) { Ok("hello") }

    my ($data, $err) = invalid();
    # => throw exception when check enabled
    # => no exception when check disabled

The following code is an example to enable it:

    BEGIN { $ENV{RESULT_SIMPLE_CHECK_ENABLED} = is_test ? 1 : 0 }
    use Result::Simple;

This option is useful for development and testing mode, and it recommended to set it to false for production.

=head1 NOTE

=head2 Avoiding Ambiguity in Result Handling

Forgetting to call C<Ok> or C<Err> function is a common mistake. Consider the following example:

    sub validate_name :Result(Str, ErrorMessage) ($name) {
        return "Empty name" unless $name; # Oops! Forgot to call `Err` function.
        return Ok($name);
    }

    my ($name, $err) = validate_name('');
    # => throw exception: Invalid result tuple (T, E)

In this case, the function throws an exception because the return value is not a valid result tuple C<($data, undef)> or C<(undef, $err)>.
This is fortunate, as the mistake is detected immediately. The following case is not detected:

    sub foo :Result(Str, ErrorMessage) {
        return (undef, 'apple'); # No use of `Ok` or `Err` function.
    }

    my ($data, $err) = foo;
    # => $err is 'apple'

Here, the function returns a valid failure tuple C<(undef, $err)>. However, it is unclear whether this was intentional or a mistake.
The lack of C<Ok> or C<Err> makes the intent ambiguous.

Conclusively, be sure to use C<Ok> or C<Err> functions to make it clear whether the success or failure is intentional.

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

