package Perinci::Examples::CmdLineSrc;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples for using cmdline_src function property',
};

$SPEC{cmdline_src_unknown} = {
    v => 1.1,
    summary => 'This function has arg with unknown cmdline_src value',
    args => {
        a1 => {schema=>'str*', cmdline_src=>'foo'},
    },
};
sub cmdline_src_unknown {
    my %args = @_;
    [200, "OK", "a1=$args{a1}"];
}

$SPEC{cmdline_src_invalid_arg_type} = {
    v => 1.1,
    summary => 'This function has non-str/non-array arg with cmdline_src',
    args => {
        a1 => {schema=>'int*', cmdline_src=>'stdin'},
    },
};
sub cmdline_src_invalid_arg_type {
    my %args = @_;
    [200, "OK", "a1=$args{a1}"];
}

$SPEC{cmdline_src_stdin_str} = {
    v => 1.1,
    summary => 'This function has arg with cmdline_src=stdin',
    args => {
        a1 => {schema=>'str*', cmdline_src=>'stdin'},
    },
};
sub cmdline_src_stdin_str {
    my %args = @_;
    [200, "OK", "a1=$args{a1}", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_array} = {
    v => 1.1,
    summary => 'This function has arg with cmdline_src=stdin',
    args => {
        a1 => {schema=>'array*', cmdline_src=>'stdin'},
    },
};
sub cmdline_src_stdin_array {
    my %args = @_;
    [200, "OK", "a1=[".join(",",@{ $args{a1} })."]",
     {'func.args'=>\%args}];
}

$SPEC{cmdline_src_file} = {
    v => 1.1,
    summary => 'This function has args with cmdline_src=file',
    args => {
        a1 => {schema=>'str*', req=>1, cmdline_src=>'file'},
        a2 => {schema=>'array*', cmdline_src=>'file'},
    },
};
sub cmdline_src_file {
    my %args = @_;
    [200, "OK", "a1=$args{a1}\na2=[".join(",", @{ $args{a2} // [] })."]",
     {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_or_file_str} = {
    v => 1.1,
    summary => 'This function has str arg with cmdline_src=stdin_or_file',
    args => {
        a1 => {schema=>'str*', cmdline_src=>'stdin_or_file'},
    },
};
sub cmdline_src_stdin_or_file_str {
    my %args = @_;
    [200, "OK", "a1=$args{a1}", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_or_file_array} = {
    v => 1.1,
    summary => 'This function has array arg with cmdline_src=stdin_or_file',
    args => {
        a1 => {schema=>'array*', cmdline_src=>'stdin_or_file'},
    },
};
sub cmdline_src_stdin_or_file_array {
    my %args = @_;
    [200, "OK", "a1=[".join(",",@{ $args{a1} })."]", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_or_files_str} = {
    v => 1.1,
    summary => 'This function has str arg with cmdline_src=stdin_or_files',
    args => {
        a1 => {schema=>'str*', cmdline_src=>'stdin_or_files'},
    },
};
sub cmdline_src_stdin_or_files_str {
    my %args = @_;
    [200, "OK", "a1=$args{a1}", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_or_files_array} = {
    v => 1.1,
    summary => 'This function has array arg with cmdline_src=stdin_or_files',
    args => {
        a1 => {schema=>'array*', cmdline_src=>'stdin_or_files'},
    },
};
sub cmdline_src_stdin_or_files_array {
    my %args = @_;
    [200, "OK", "a1=[".join(",",@{ $args{a1} })."]", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_or_args_array} = {
    v => 1.1,
    summary => 'This function has array arg with cmdline_src=stdin_or_args',
    args => {
        a1 => {schema=>['array*', of=>'str*'], cmdline_src=>'stdin_or_args'},
    },
};
sub cmdline_src_stdin_or_args_array {
    my %args = @_;
    [200, "OK", "a1=[".join(",",@{ $args{a1} // [] })."]", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_multi_stdin} = {
    v => 1.1,
    summary => 'This function has multiple args with cmdline_src stdin/stdin_or_files',
    args => {
        a1 => {schema=>'str*', cmdline_src=>'stdin_or_files'},
        a2 => {schema=>'str*', cmdline_src=>'stdin'},
    },
};
sub cmdline_src_multi_stdin {
    my %args = @_;
    [200, "OK", "a1=$args{a1}\na2=$args{a2}", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_stdin_line} = {
    v => 1.1,
    summary => 'This function has a single stdin_line argument',
    args => {
        a1 => {schema=>'str*', req=>1, cmdline_src=>'stdin_line'},
        a2 => {schema=>'str*', req=>1},
    },
};
sub cmdline_src_stdin_line {
    my %args = @_;
    [200, "OK", "a1=$args{a1}\na2=$args{a2}", {'func.args'=>\%args}];
}

$SPEC{cmdline_src_multi_stdin_line} = {
    v => 1.1,
    summary => 'This function has several stdin_line arguments',
    description => <<'_',

And one also has its is_password property set to true.

_
    args => {
        a1 => {schema=>'str*', req=>1, cmdline_src=>'stdin_line'},
        a2 => {schema=>'str*', req=>1, cmdline_src=>'stdin_line', is_password=>1},
        a3 => {schema=>'str*', req=>1},
    },
};
sub cmdline_src_multi_stdin_line {
    my %args = @_;
    [200, "OK", "a1=$args{a1}\na2=$args{a2}\na3=$args{a3}",
     {'func.args'=>\%args}];
}

$SPEC{test_binary} = {
    v => 1.1,
    summary => "Accept binary in stdin/file",
    description => <<'_',

This function is like the one in <pm:Perinci::Examples> but argument is accepted
via `stdin_or_files`.

_
    args => {
        data => {
            schema  => "buf*",
            pos     => 0,
            default => "\0\0\0",
            cmdline_src => "stdin_or_files",
        },
    },
    result => {
        schema => "buf*",
    },
};
sub test_binary {
    my %args = @_; # NO_VALIDATE_ARGS
    my $data = $args{data} // "\0\0\0";
    return [200, "OK", $data, {'func.args'=>\%args}];
}

1;
# ABSTRACT: Examples for using cmdline_src function property

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::CmdLineSrc - Examples for using cmdline_src function property

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::CmdLineSrc (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 FUNCTIONS


=head2 cmdline_src_file

Usage:

 cmdline_src_file(%args) -> [status, msg, payload, meta]

This function has args with cmdline_src=file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1>* => I<str>

=item * B<a2> => I<array>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_invalid_arg_type

Usage:

 cmdline_src_invalid_arg_type(%args) -> [status, msg, payload, meta]

This function has non-str/non-array arg with cmdline_src.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_multi_stdin

Usage:

 cmdline_src_multi_stdin(%args) -> [status, msg, payload, meta]

This function has multiple args with cmdline_src stdin/stdin_or_files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<str>

=item * B<a2> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_multi_stdin_line

Usage:

 cmdline_src_multi_stdin_line(%args) -> [status, msg, payload, meta]

This function has several stdin_line arguments.

And one also has its is_password property set to true.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1>* => I<str>

=item * B<a2>* => I<str>

=item * B<a3>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_array

Usage:

 cmdline_src_stdin_array(%args) -> [status, msg, payload, meta]

This function has arg with cmdline_src=stdin.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<array>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_line

Usage:

 cmdline_src_stdin_line(%args) -> [status, msg, payload, meta]

This function has a single stdin_line argument.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1>* => I<str>

=item * B<a2>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_or_args_array

Usage:

 cmdline_src_stdin_or_args_array(%args) -> [status, msg, payload, meta]

This function has array arg with cmdline_src=stdin_or_args.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_or_file_array

Usage:

 cmdline_src_stdin_or_file_array(%args) -> [status, msg, payload, meta]

This function has array arg with cmdline_src=stdin_or_file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<array>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_or_file_str

Usage:

 cmdline_src_stdin_or_file_str(%args) -> [status, msg, payload, meta]

This function has str arg with cmdline_src=stdin_or_file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_or_files_array

Usage:

 cmdline_src_stdin_or_files_array(%args) -> [status, msg, payload, meta]

This function has array arg with cmdline_src=stdin_or_files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<array>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_or_files_str

Usage:

 cmdline_src_stdin_or_files_str(%args) -> [status, msg, payload, meta]

This function has str arg with cmdline_src=stdin_or_files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_stdin_str

Usage:

 cmdline_src_stdin_str(%args) -> [status, msg, payload, meta]

This function has arg with cmdline_src=stdin.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cmdline_src_unknown

Usage:

 cmdline_src_unknown(%args) -> [status, msg, payload, meta]

This function has arg with unknown cmdline_src value.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 test_binary

Usage:

 test_binary(%args) -> [status, msg, payload, meta]

Accept binary in stdin/file.

This function is like the one in L<Perinci::Examples> but argument is accepted
via C<stdin_or_files>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<data> => I<buf> (default: "\0\0\0")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (buf)

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
