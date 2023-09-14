package Perinci::Examples::ArgsAs;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.824'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Demonstrate various values of `args_as` '.
        'function metadata property',
    description => <<'_',

The functions in this package can test:

- argument passing;
- whether module POD is rendered correctly;
- whether examples (in module POD or CLI help) are rendered correctly;

_
};

my $args = {
    arg1 => {schema=>'str*', req=>1, pos=>0},
    arg2 => {schema=>'int*', req=>1, pos=>1},
    arg3 => {schema=>['float*', between=>[0,1]], pos=>2},
};

my $examples = [
    {
        summary => 'Without the optional arg3',
        args    => {arg1=>"abc", arg2=>10},
    },
    {
        summary => 'With the optional arg3',
        args    => {arg1=>"def", arg2=>20, arg3=>0.5},
    },
];

$SPEC{args_as_hash} = {
    v => 1.1,
    summary => 'This is the default',
    args => $args,
    args_as => 'hash',
    examples => $examples,
};
sub args_as_hash {
    [200,"OK",\@_];
}

$SPEC{args_as_hashref} = {
    v => 1.1,
    summary => 'Alternative to `hash` to avoid copying',
    args => $args,
    args_as => 'hashref',
    examples => $examples,
};
sub args_as_hashref {
    [200,"OK",\@_];
}

$SPEC{args_as_array} = {
    v => 1.1,
    summary => 'Regular perl subs use this',
    args => $args,
    args_as => 'array',
    examples => $examples,
};
sub args_as_array {
    [200,"OK",\@_];
}

$SPEC{args_as_arrayref} = {
    v => 1.1,
    summary => 'Alternative to `array` to avoid copying',
    args => $args,
    args_as => 'arrayref',
    examples => $examples,
};
sub args_as_arrayref {
    [200,"OK",\@_];
}

1;
# ABSTRACT: Demonstrate various values of `args_as` function metadata property

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::ArgsAs - Demonstrate various values of `args_as` function metadata property

=head1 VERSION

This document describes version 0.824 of Perinci::Examples::ArgsAs (from Perl distribution Perinci-Examples), released on 2023-07-09.

=head1 DESCRIPTION


The functions in this package can test:

=over

=item * argument passing;

=item * whether module POD is rendered correctly;

=item * whether examples (in module POD or CLI help) are rendered correctly;

=back

=head1 FUNCTIONS


=head2 args_as_array

Usage:

 args_as_array($arg1, $arg2, $arg3) -> [$status_code, $reason, $payload, \%result_meta]

Regular perl subs use this.

Examples:

=over

=item * Without the optional arg3:

 args_as_array("abc", 10); # -> [200, "OK", ["abc", 10], {}]

=item * With the optional arg3:

 args_as_array("def", 20, 0.5); # -> [200, "OK", ["def", 20, 0.5], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$arg1>* => I<str>

(No description)

=item * B<$arg2>* => I<int>

(No description)

=item * B<$arg3> => I<float>

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



=head2 args_as_arrayref

Usage:

 args_as_arrayref([$arg1, $arg2, $arg3]) -> [$status_code, $reason, $payload, \%result_meta]

Alternative to `array` to avoid copying.

Examples:

=over

=item * Without the optional arg3:

 args_as_arrayref(["abc", 10]); # -> [200, "OK", [["abc", 10]], {}]

=item * With the optional arg3:

 args_as_arrayref(["def", 20, 0.5]); # -> [200, "OK", [["def", 20, 0.5]], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$arg1>* => I<str>

(No description)

=item * B<$arg2>* => I<int>

(No description)

=item * B<$arg3> => I<float>

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



=head2 args_as_hash

Usage:

 args_as_hash(%args) -> [$status_code, $reason, $payload, \%result_meta]

This is the default.

Examples:

=over

=item * Without the optional arg3:

 args_as_hash(arg1 => "abc", arg2 => 10); # -> [200, "OK", ["arg1", "abc", "arg2", 10], {}]

=item * With the optional arg3:

 args_as_hash(arg1 => "def", arg2 => 20, arg3 => 0.5);

Result:

 [200, "OK", ["arg3", 0.5, "arg1", "def", "arg2", 20], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<str>

(No description)

=item * B<arg2>* => I<int>

(No description)

=item * B<arg3> => I<float>

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



=head2 args_as_hashref

Usage:

 args_as_hashref(\%args) -> [$status_code, $reason, $payload, \%result_meta]

Alternative to `hash` to avoid copying.

Examples:

=over

=item * Without the optional arg3:

 args_as_hashref({ arg1 => "abc", arg2 => 10 }); # -> [200, "OK", [{ arg1 => "abc", arg2 => 10 }], {}]

=item * With the optional arg3:

 args_as_hashref({ arg1 => "def", arg2 => 20, arg3 => 0.5 });

Result:

 [200, "OK", [{ arg1 => "def", arg2 => 20, arg3 => 0.5 }], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<str>

(No description)

=item * B<arg2>* => I<int>

(No description)

=item * B<arg3> => I<float>

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

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
