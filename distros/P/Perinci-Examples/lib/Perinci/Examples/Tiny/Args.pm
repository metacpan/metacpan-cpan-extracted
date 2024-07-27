## no critic: RequireUseStrict
package Perinci::Examples::Tiny::Args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.825'; # VERSION

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

This document describes version 0.825 of Perinci::Examples::Tiny::Args (from Perl distribution Perinci-Examples), released on 2024-07-17.

=head1 DESCRIPTION

Like the other Perinci::Examples::Tiny::*, this module does not use other
modules and is suitable for testing Perinci::CmdLine::Inline as well as other
Perinci::CmdLine frameworks.

=head1 FUNCTIONS


=head2 as_is

Usage:

 as_is(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function returns the argument as-is.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg> => I<any>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 has_date_and_duration_args

Usage:

 has_date_and_duration_args(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function contains a date and a duration argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

(No description)

=item * B<duration>* => I<duration>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 has_date_arg

Usage:

 has_date_arg(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function contains a date argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 has_dot_args

Usage:

 has_dot_args(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function contains arguments with dot in their names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a.number>* => I<int>

(No description)

=item * B<another.number>* => I<float>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value: Return the two numbers multiplied (any)



=head2 has_duration_arg

Usage:

 has_duration_arg(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function contains a duration argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
