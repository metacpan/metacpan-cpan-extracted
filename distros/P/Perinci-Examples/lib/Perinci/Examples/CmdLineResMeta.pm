package Perinci::Examples::CmdLineResMeta;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

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

This document describes version 0.814 of Perinci::Examples::CmdLineResMeta (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 FUNCTIONS


=head2 default_format

Usage:

 default_format() -> [status, msg, payload, meta]

Set cmdline.default_format json.

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



=head2 exit_code

Usage:

 exit_code() -> [status, msg, payload, meta]

Returns cmdline exit code 7, even though status is 200.

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



=head2 is_palindrome

Usage:

 is_palindrome(%args) -> [status, msg, payload, meta]

Return true if string is palindrome.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 result

Usage:

 result() -> [status, msg, payload, meta]

Returns false, but cmdline.result the string "false".

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



=head2 skip_format

Usage:

 skip_format() -> [status, msg, payload, meta]

Set cmdline.skip_format => 1.

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
