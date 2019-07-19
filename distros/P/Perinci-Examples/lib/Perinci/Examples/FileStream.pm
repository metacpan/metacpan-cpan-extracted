package Perinci::Examples::FileStream;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

use Fcntl qw(:DEFAULT);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples for reading/writing files (using streaming result)',
    description => <<'_',

The functions in this package demonstrate byte streaming of input and output.

The functions are separated into this module because these functions read/write
files on the filesystem and might potentially be dangerous if
<pm:Perinci::Examples> is exposed to the network by accident.

See also <pm:Perinci::Examples::FilePartial> which uses partial technique
instead of streaming.

_
};

$SPEC{read_file} = {
    v => 1.1,
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
    },
    result => {schema=>'buf*', stream=>1},
    description => <<'_',

This function demonstrate output streaming of bytes.

To do output streaming, on the function side, you just return a coderef which
can be called by caller (e.g. CLI framework <pm:Perinci::CmdLine>) to read data
from. Code must return data or undef to signify exhaustion.

This works over remote (HTTP) too, because output streaming is supported by
<pod:Riap::HTTP> (version 1.2) and <pm:Perinci::Access::HTTP::Client>. Streams
are translated into HTTP chunks.

_
};
sub read_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};
    (-f $path) or return [404, "No such file '$path'"];

    open my($fh), "<", $path or return [500, "Can't open '$path': $!"];

    [200, "OK", sub { ~~<$fh> }, {stream=>1}];
}

$SPEC{write_file} = {
    v => 1.1,
    description => <<'_',

This function demonstrates input streaming of bytes.

To do input streaming, on the function side, you just specify one your args with
the `stream` property set to true (`stream => 1`). In this example, the
`content` argument is set to streaming.

If you run the function through <pm:Perinci::CmdLine>, you'll get a coderef
instead of the actual value. You can then repeatedly call the code to read data.
This currently works for local functions only. As of this writing,
<pod:Riap::HTTP> protocol does not support input streaming. It supports partial
input though (see the documentation on how this works) and theoretically
streaming can be emulated by client library using partial input. However, client
like <pm:Perinci::Access::HTTP::Client> does not yet support this.

Note that the argument's schema is still `buf*`, not `code*`.

Note: This function overwrites existing file.

_
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
        content => {schema=>'buf*', req=>1, pos=>1, stream=>1,
                    cmdline_src=>'stdin_or_files',
                },
    },
};
sub write_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'content'})) { ((defined($args{'content'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'content'})) ? 1 : (($arg_err //= "Not of type buffer"),0)); if ($arg_err) { return [400, "Invalid argument value for content: $arg_err"] } }if (!exists($args{'content'})) { return [400, "Missing argument: content"] } no warnings ('void');if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};

    open my($fh), ">", $path
        or return [500, "Can't open '$path' for writing: $!"];
    my $content = $args{content};
    my $written = 0;
    if (ref($content)) {
        local $_;
        while (defined($_ = $content->())) {
            print $fh $_; $written += length($_);
        }
    } else {
        print $fh $content;
        $written += length($content);
    }

    [200, "Wrote $written byte(s)"];
}

$SPEC{append_file} = {
    v => 1.1,
    description => <<'_',

This is like `write_file()` except that it appends instead of overwrites
existing file.

_
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
        content => {schema=>'buf*', req=>1, pos=>1, stream=>1,
                    cmdline_src=>'stdin_or_files'},
    },
};
sub append_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'content'})) { ((defined($args{'content'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'content'})) ? 1 : (($arg_err //= "Not of type buffer"),0)); if ($arg_err) { return [400, "Invalid argument value for content: $arg_err"] } }if (!exists($args{'content'})) { return [400, "Missing argument: content"] } no warnings ('void');if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};

    open my($fh), ">>", $path
        or return [500, "Can't open '$path' for writing: $!"];
    my $content = $args{content};
    my $written = 0;
    if (ref($content)) {
        local $_;
        while (defined($_ = $content->())) {
            print $fh $_; $written += length($_);
        }
    } else {
        print $fh $content;
        $written += length($content);
    }

    [200, "Appended $written byte(s)"];
}

1;
# ABSTRACT: Examples for reading/writing files (using streaming result)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::FileStream - Examples for reading/writing files (using streaming result)

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::FileStream (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION


The functions in this package demonstrate byte streaming of input and output.

The functions are separated into this module because these functions read/write
files on the filesystem and might potentially be dangerous if
L<Perinci::Examples> is exposed to the network by accident.

See also L<Perinci::Examples::FilePartial> which uses partial technique
instead of streaming.

=head1 FUNCTIONS


=head2 append_file

Usage:

 append_file(%args) -> [status, msg, payload, meta]

This is like C<write_file()> except that it appends instead of overwrites
existing file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content>* => I<buf>

=item * B<path>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 read_file

Usage:

 read_file(%args) -> [status, msg, payload, meta]

This function demonstrate output streaming of bytes.

To do output streaming, on the function side, you just return a coderef which
can be called by caller (e.g. CLI framework L<Perinci::CmdLine>) to read data
from. Code must return data or undef to signify exhaustion.

This works over remote (HTTP) too, because output streaming is supported by
L<Riap::HTTP> (version 1.2) and L<Perinci::Access::HTTP::Client>. Streams
are translated into HTTP chunks.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (buf)



=head2 write_file

Usage:

 write_file(%args) -> [status, msg, payload, meta]

This function demonstrates input streaming of bytes.

To do input streaming, on the function side, you just specify one your args with
the C<stream> property set to true (C<< stream =E<gt> 1 >>). In this example, the
C<content> argument is set to streaming.

If you run the function through L<Perinci::CmdLine>, you'll get a coderef
instead of the actual value. You can then repeatedly call the code to read data.
This currently works for local functions only. As of this writing,
L<Riap::HTTP> protocol does not support input streaming. It supports partial
input though (see the documentation on how this works) and theoretically
streaming can be emulated by client library using partial input. However, client
like L<Perinci::Access::HTTP::Client> does not yet support this.

Note that the argument's schema is still C<buf*>, not C<code*>.

Note: This function overwrites existing file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content>* => I<buf>

=item * B<path>* => I<str>

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
