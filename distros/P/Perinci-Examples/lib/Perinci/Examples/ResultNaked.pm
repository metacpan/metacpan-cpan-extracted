package Perinci::Examples::ResultNaked;

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

This document describes version 0.824 of Perinci::Examples::ResultNaked (from Perl distribution Perinci-Examples), released on 2023-07-09.

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

 result_naked(arg1 => "abc", arg2 => 10); # -> ["arg2", 10, "arg1", "abc"]

=item * With the optional arg3:

 result_naked(arg1 => "def", arg2 => 20, arg3 => 0.5); # -> ["arg3", 0.5, "arg2", 20, "arg1", "def"]

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

Return value:  (any)



=head2 result_not_naked

Usage:

 result_not_naked(%args) -> [$status_code, $reason, $payload, \%result_meta]

This is the default.

Examples:

=over

=item * Without the optional arg3:

 result_not_naked(arg1 => "abc", arg2 => 10); # -> [200, "OK", ["arg2", 10, "arg1", "abc"], {}]

=item * With the optional arg3:

 result_not_naked(arg1 => "def", arg2 => 20, arg3 => 0.5);

Result:

 [200, "OK", ["arg1", "def", "arg2", 20, "arg3", 0.5], {}]

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
