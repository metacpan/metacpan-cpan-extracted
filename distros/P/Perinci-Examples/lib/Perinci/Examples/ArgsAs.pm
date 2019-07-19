package Perinci::Examples::ArgsAs;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010001;
use strict;
use warnings;

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

This document describes version 0.814 of Perinci::Examples::ArgsAs (from Perl distribution Perinci-Examples), released on 2019-06-29.

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

 args_as_array($arg1, $arg2, $arg3) -> [status, msg, payload, meta]

Regular perl subs use this.

Examples:

=over

=item * Without the optional arg3:

 args_as_array("abc", 10); # -> ["abc", 10]

=item * With the optional arg3:

 args_as_array("def", 20, 0.5); # -> ["def", 20, 0.5]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$arg1>* => I<str>

=item * B<$arg2>* => I<int>

=item * B<$arg3> => I<float>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 args_as_arrayref

Usage:

 args_as_arrayref([$arg1, $arg2, $arg3]) -> [status, msg, payload, meta]

Alternative to `array` to avoid copying.

Examples:

=over

=item * Without the optional arg3:

 args_as_arrayref(["abc", 10]); # -> [["abc", 10]]

=item * With the optional arg3:

 args_as_arrayref(["def", 20, 0.5]); # -> [["def", 20, 0.5]]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$arg1>* => I<str>

=item * B<$arg2>* => I<int>

=item * B<$arg3> => I<float>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 args_as_hash

Usage:

 args_as_hash(%args) -> [status, msg, payload, meta]

This is the default.

Examples:

=over

=item * Without the optional arg3:

 args_as_hash(arg1 => "abc", arg2 => 10); # -> ["arg1", "abc", "arg2", 10]

=item * With the optional arg3:

 args_as_hash(arg1 => "def", arg2 => 20, arg3 => 0.5); # -> ["arg3", 0.5, "arg1", "def", "arg2", 20]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<str>

=item * B<arg2>* => I<int>

=item * B<arg3> => I<float>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 args_as_hashref

Usage:

 args_as_hashref(\%args) -> [status, msg, payload, meta]

Alternative to `hash` to avoid copying.

Examples:

=over

=item * Without the optional arg3:

 args_as_hashref({ arg1 => "abc", arg2 => 10 }); # -> [{ arg1 => "abc", arg2 => 10 }]

=item * With the optional arg3:

 args_as_hashref({ arg1 => "def", arg2 => 20, arg3 => 0.5 });

Result:

 [{ arg1 => "def", arg2 => 20, arg3 => 0.5 }]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<str>

=item * B<arg2>* => I<int>

=item * B<arg3> => I<float>

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
