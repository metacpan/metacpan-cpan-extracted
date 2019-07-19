package Perinci::Examples::Tiny::Args;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

our %SPEC;

# this Rinci metadata is already normalized
$SPEC{as_is} = {
    v => 1.1,
    summary => "This function returns the argument as-is",
    args => {
        'arg' => {
            schema => ['any',{},{}],
        },
    },
};
sub as_is {
    my %args = @_;
    [200, "OK", $args{arg}];
}

# this Rinci metadata is already normalized
$SPEC{has_dot_args} = {
    v => 1.1,
    summary => "This function contains arguments with dot in their names",
    args => {
        'a.number' => {
            schema => ['int' => {req=>1}, {}],
            pos => 0,
            req => 1,
        },
        'another.number' => {
            schema => ['float' => {req=>1}, {}],
            pos => 1,
            req => 1,
        },
    },
    result => {
        summary => 'Return the two numbers multiplied',
    },
};
sub has_dot_args {
    my %args = @_;
    [200, "OK", $args{'a.number'} * $args{'another.number'}];
}

# this Rinci metadata is already normalized
$SPEC{has_date_arg} = {
    v => 1.1,
    summary => "This function contains a date argument",
    args => {
        'date' => {
            schema => ['date', {req=>1}, {}],
            pos => 0,
            req => 1,
        },
    },
};
sub has_date_arg {
    my %args = @_;
    my $date = $args{date};
    [200, "OK", {
        "ref(value)" => ref($date),
        "value (stringified)" => "$date",
    }];
}

# this Rinci metadata is already normalized
$SPEC{has_duration_arg} = {
    v => 1.1,
    summary => "This function contains a duration argument",
    args => {
        'duration' => {
            schema => ['duration', {req=>1}, {}],
            pos => 0,
            req => 1,
        },
    },
};
sub has_duration_arg {
    my %args = @_;
    my $duration = $args{duration};
    [200, "OK", {
        "ref(value)" => ref($duration),
        "value (stringified)" => "$duration",
    }];
}

# this Rinci metadata is already normalized
$SPEC{has_date_and_duration_args} = {
    v => 1.1,
    summary => "This function contains a date and a duration argument",
    args => {
        'date' => {
            schema => ['date', {req=>1}, {}],
            pos => 0,
            req => 1,
        },
        'duration' => {
            schema => ['duration', {req=>1}, {}],
            pos => 1,
            req => 1,
        },
    },
};
sub has_date_and_duration_args {
    my %args = @_;
    my $date = $args{date};
    my $duration = $args{duration};
    [200, "OK", {
        "ref(date)" => ref($date),
        "date (stringified)" => "$date",
        "ref(duration)" => ref($duration),
        "duration (stringified)" => "$duration",
    }];
}

1;
# ABSTRACT: Tests related to function arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Tiny::Args - Tests related to function arguments

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::Tiny::Args (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION

Like the other Perinci::Examples::Tiny::*, this module does not use other
modules and is suitable for testing Perinci::CmdLine::Inline as well as other
Perinci::CmdLine frameworks.

=head1 FUNCTIONS


=head2 as_is

Usage:

 as_is(%args) -> [status, msg, payload, meta]

This function returns the argument as-is.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg> => I<any>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 has_date_and_duration_args

Usage:

 has_date_and_duration_args(%args) -> [status, msg, payload, meta]

This function contains a date and a duration argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

=item * B<duration>* => I<duration>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 has_date_arg

Usage:

 has_date_arg(%args) -> [status, msg, payload, meta]

This function contains a date argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 has_dot_args

Usage:

 has_dot_args(%args) -> [status, msg, payload, meta]

This function contains arguments with dot in their names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a.number>* => I<int>

=item * B<another.number>* => I<float>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: Return the two numbers multiplied (any)



=head2 has_duration_arg

Usage:

 has_duration_arg(%args) -> [status, msg, payload, meta]

This function contains a duration argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

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
