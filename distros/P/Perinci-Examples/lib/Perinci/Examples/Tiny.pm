package Perinci::Examples::Tiny;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

our %SPEC;

# this Rinci metadata is already normalized
$SPEC{noop} = {
    v => 1.1,
    summary => "Do nothing",
};
sub noop {
    [200];
}

# this Rinci metadata is already normalized
$SPEC{hello_naked} = {
    v => 1.1,
    summary => "Hello world",
    result_naked => 1,
};
sub hello_naked {
    "Hello, world";
}

# this Rinci metadata is already normalized
$SPEC{odd_even} = {
    v => 1.1,
    summary => "Return 'odd' or 'even' depending on the number",
    args => {
        number => {
            summary => 'Number to test',
            schema => ['int' => {req=>1}, {}],
            pos => 0,
            req => 1,
        },
    },
    result => {
        schema => ['str', {}, {}],
    },
};
sub odd_even {
    my %args = @_;
    [200, "OK", $args{number} % 2 == 0 ? "even" : "odd"];
}

# this Rinci metadata is already normalized
$SPEC{foo1} = {
    v => 1.1,
    summary => "Return the string 'foo1'",
    args => {},
};
sub foo1 { [200, "OK", "foo1"] }

# this Rinci metadata is already normalized
$SPEC{foo2} = {
    v => 1.1,
    summary => "Return the string 'foo1'",
    args => {},
};
sub foo2 { [200, "OK", "foo2"] }

# this Rinci metadata is already normalized
$SPEC{foo3} = {
    v => 1.1,
    summary => "Return the string 'foo1'",
    args => {},
};
sub foo3 { [200, "OK", "foo3"] }

# this Rinci metadata is already normalized
$SPEC{foo4} = {
    v => 1.1,
    summary => "Return the string 'foo1'",
    args => {},
};
sub foo4 { [200, "OK", "foo4"] }

# this Rinci metadata is already normalized
$SPEC{sum} = {
    v => 1.1,
    summary => "Sum numbers in array",
    description => <<'_',

This function can be used to test passing nonscalar (array) arguments.

_
    args => {
        array => {
            summary => 'Array',
            schema  => ['array', {req=>1, of => ['float', {req=>1}, {}]}, {}],
            req     => 1,
            pos     => 0,
            slurpy  => 1,
        },
        round => {
            summary => 'Whether to round result to integer',
            schema  => [bool => {default => 0}, {}],
        },
    },
};
sub sum {
    my %args = @_;

    my $sum = 0;
    for (@{$args{array}}) {
        $sum += $_ if defined && /\A(?:\d+(?:\.\d*)?|\.\d+)\z/;
    }
    $sum = int($sum) if $args{round};
    [200, "OK", $sum];
}

$SPEC{noop2} = {
    v => 1.1,
    summary => "Just like noop, but accepts several arguments",
    description => <<'_',

Will return arguments passed to it.

This function is also marked as `pure`, meaning it will not cause any side
effects. Pure functions are safe to call directly in a transaction (without
going through the transaction manager) or during dry-run mode.

_
    args => {
        a => {
            summary => 'Argument',
            schema => ['any', {}, {}],
            pos => 0,
        },
        b => {
            summary => 'Argument',
            schema => ['any', {}, {}],
            pos => 1,
        },
        c => {
            summary => 'Argument',
            schema => ['any', {}, {}],
            pos => 2,
        },
        d => {
            summary => 'Argument',
            schema => ['any', {}, {}],
            pos => 3,
        },
        e => {
            summary => 'Argument',
            schema => ['any', {}, {}],
            pos => 4,
        },
    },
    features => {pure => 1},
};

sub noop2 {
    my %args = @_;
    [200, "OK", "a=$args{a}\nb=$args{b}\nc=$args{c}\nd=$args{d}\ne=$args{e}"];
}

1;
# ABSTRACT: Small examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Tiny - Small examples

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::Tiny (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION

This module only has a couple of examples and very lightweight. Used e.g. for
benchmarking startup overhead of L<Perinci::CmdLine::Inline>-generated scripts.

=head1 FUNCTIONS


=head2 foo1

Usage:

 foo1() -> [status, msg, payload, meta]

Return the string 'foo1'.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 foo2

Usage:

 foo2() -> [status, msg, payload, meta]

Return the string 'foo1'.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 foo3

Usage:

 foo3() -> [status, msg, payload, meta]

Return the string 'foo1'.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 foo4

Usage:

 foo4() -> [status, msg, payload, meta]

Return the string 'foo1'.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 hello_naked

Usage:

 hello_naked() -> any

Hello world.

This function is not exported.

No arguments.

Return value:  (any)



=head2 noop

Usage:

 noop() -> [status, msg, payload, meta]

Do nothing.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 noop2

Usage:

 noop2(%args) -> [status, msg, payload, meta]

Just like noop, but accepts several arguments.

Will return arguments passed to it.

This function is also marked as C<pure>, meaning it will not cause any side
effects. Pure functions are safe to call directly in a transaction (without
going through the transaction manager) or during dry-run mode.

This function is not exported.

This function is pure (produce no side effects).


Arguments ('*' denotes required arguments):

=over 4

=item * B<a> => I<any>

Argument.

=item * B<b> => I<any>

Argument.

=item * B<c> => I<any>

Argument.

=item * B<d> => I<any>

Argument.

=item * B<e> => I<any>

Argument.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 odd_even

Usage:

 odd_even(%args) -> [status, msg, payload, meta]

Return 'odd' or 'even' depending on the number.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<number>* => I<int>

Number to test.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 sum

Usage:

 sum(%args) -> [status, msg, payload, meta]

Sum numbers in array.

This function can be used to test passing nonscalar (array) arguments.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array>* => I<array[float]>

Array.

=item * B<round> => I<bool> (default: 0)

Whether to round result to integer.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
