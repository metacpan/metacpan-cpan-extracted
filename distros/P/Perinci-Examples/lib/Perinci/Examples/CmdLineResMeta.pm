package Perinci::Examples::CmdLineResMeta;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.824'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Functions in this package contains cmdline.* result metadata',
};

$SPEC{exit_code} = {
    v => 1.1,
    summary => 'Returns cmdline exit code 7, even though status is 200',
    args => {
    },
};
sub exit_code {
    my %args = @_;
    [200, "OK", undef, {'cmdline.exit_code'=>7}];
}

$SPEC{result} = {
    v => 1.1,
    summary => 'Returns false, but cmdline.result the string "false"',
    args => {
    },
};
sub result {
    my %args = @_;
    [200, "OK", 0, {'cmdline.result'=>'false'}];
}

$SPEC{is_palindrome} = {
    v => 1.1,
    summary => 'Return true if string is palindrome',
    args => {
        str => {schema=>'str*', req=>1, pos=>0},
    },
};
sub is_palindrome {
    my %args = @_;
    my $str = $args{str};
    my $res = $str eq reverse($str);
    [200, "OK", $res, {'cmdline.result'=>$res ?
                           'Is palindrome' : 'Not palindrome'}];
}

$SPEC{default_format} = {
    v => 1.1,
    summary => 'Set cmdline.default_format json',
    args => {
    },
};
sub default_format {
    my %args = @_;
    [200, "OK", undef, {'cmdline.default_format'=>'json'}];
}

$SPEC{skip_format} = {
    v => 1.1,
    summary => 'Set cmdline.skip_format => 1',
    args => {
    },
};
sub skip_format {
    my %args = @_;
    [200, "OK", [], {'cmdline.skip_format'=>1}];
}

1;
# ABSTRACT: Functions in this package contains cmdline.* result metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::CmdLineResMeta - Functions in this package contains cmdline.* result metadata

=head1 VERSION

This document describes version 0.824 of Perinci::Examples::CmdLineResMeta (from Perl distribution Perinci-Examples), released on 2023-07-09.

=head1 FUNCTIONS


=head2 default_format

Usage:

 default_format() -> [$status_code, $reason, $payload, \%result_meta]

Set cmdline.default_format json.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 exit_code

Usage:

 exit_code() -> [$status_code, $reason, $payload, \%result_meta]

Returns cmdline exit code 7, even though status is 200.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_palindrome

Usage:

 is_palindrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return true if string is palindrome.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str>* => I<str>

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



=head2 result

Usage:

 result() -> [$status_code, $reason, $payload, \%result_meta]

Returns false, but cmdline.result the string "false".

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 skip_format

Usage:

 skip_format() -> [$status_code, $reason, $payload, \%result_meta]

Set cmdline.skip_format =E<gt> 1.

This function is not exported.

No arguments.

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
