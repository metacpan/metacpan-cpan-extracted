package Perinci::Examples::ResultNaked;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Demonstrate `result_naked` property',
    description => <<'_',

The functions in this package can test:

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

$SPEC{result_not_naked} = {
    v => 1.1,
    summary => 'This is the default',
    args => $args,
    examples => $examples,
    result_naked => 0,
};
sub result_not_naked {
    [200,"OK",\@_];
}

$SPEC{result_naked} = {
    v => 1.1,
    summary => 'This function does not return enveloped result',
    args => $args,
    examples => $examples,
    result_naked => 1,
};
sub result_naked {
    \@_;
}

1;
# ABSTRACT: Demonstrate `result_naked` property

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::ResultNaked - Demonstrate `result_naked` property

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::ResultNaked (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION


The functions in this package can test:

=over

=item * whether module POD is rendered correctly;

=item * whether examples (in module POD or CLI help) are rendered correctly;

=back

=head1 FUNCTIONS


=head2 result_naked

Usage:

 result_naked(%args) -> any

This function does not return enveloped result.

Examples:

=over

=item * Without the optional arg3:

 result_naked(arg1 => "abc", arg2 => 10); # -> [200, "OK", ["arg2", 10, "arg1", "abc"]]

=item * With the optional arg3:

 result_naked(arg1 => "def", arg2 => 20, arg3 => 0.5);

Result:

 [200, "OK", ["arg2", 20, "arg1", "def", "arg3", 0.5]]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<str>

=item * B<arg2>* => I<int>

=item * B<arg3> => I<float>

=back

Return value:  (any)



=head2 result_not_naked

Usage:

 result_not_naked(%args) -> [status, msg, payload, meta]

This is the default.

Examples:

=over

=item * Without the optional arg3:

 result_not_naked(arg1 => "abc", arg2 => 10); # -> ["arg1", "abc", "arg2", 10]

=item * With the optional arg3:

 result_not_naked(arg1 => "def", arg2 => 20, arg3 => 0.5); # -> ["arg3", 0.5, "arg2", 20, "arg1", "def"]

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
