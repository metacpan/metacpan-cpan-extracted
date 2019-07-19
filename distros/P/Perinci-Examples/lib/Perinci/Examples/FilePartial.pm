package Perinci::Examples::FilePartial;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

use Fcntl qw(:DEFAULT);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples for reading/writing files (demos partial argument/result)',
    description => <<'_',

The functions in this package demoes partial content upload as well as partial
result.

The functions are separated into this module because these functions read/write
files on the filesystem and might potentially be dangerous if
`Perinci::Examples` is exposed to the network by accident.

See also `Perinci::Examples::FileStream` which uses streaming instead of
partial.

_
};

$SPEC{read_file} = {
    v => 1.1,
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
    },
    result => {schema=>'buf*', partial=>1},
};
sub read_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};
    (-f $path) or return [404, "No such file '$path'"];
    my $size = (-s _);
    my $start = $args{-res_part_start} // 0;
    $start = 0     if $start < 0;
    $start = $size if $start > $size;
    my $len   = $args{-res_part_len} // $size;
    $len = $size-$start if $start+$len > $size;
    $len = 0            if $len < 0;

    my $is_partial = $start > 0 || $start+$len < $size;

    open my($fh), "<", $path or return [500, "Can't open '$path': $!"];
    seek $fh, $start, 0;
    my $data;
    read $fh, $data, $len;

    [$is_partial ? 206 : 200,
     $is_partial ? "Partial content" : "OK (whole content)",
     $data,
     {len=>$size, part_start=>$start, part_len=>$len}];
}

$SPEC{write_file} = {
    v => 1.1,
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
        content => {schema=>'buf*', req=>1, pos=>1, partial=>1,
                    cmdline_src=>'stdin_or_files'},
    },
};
sub write_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'content'})) { ((defined($args{'content'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'content'})) ? 1 : (($arg_err //= "Not of type buffer"),0)); if ($arg_err) { return [400, "Invalid argument value for content: $arg_err"] } }if (!exists($args{'content'})) { return [400, "Missing argument: content"] } no warnings ('void');if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};
    my $start = $args{"-arg_part_start"} // 0;
    my $size  = $args{"-arg_len"} // 0;

    sysopen my($fh), $path, O_WRONLY | O_CREAT
        or return [500, "Can't open '$path' for writing: $!"];
    sysseek $fh, $start, 0
        or return [500, "Can't seek to $start: $!"];
    my $written = syswrite $fh, $args{content};
    defined($written) or return [500, "Can't write content to '$path': $!"];

    [200, "Wrote $written byte(s) from position $start"];
}

$SPEC{append_file} = {
    v => 1.1,
    description => <<'_',

This function doesn't actually accept partial content, because by nature it is
already a partial/incremental operation.

_
    args => {
        path => {schema=>'str*', req=>1, pos=>0},
        content => {schema=>'buf*', req=>1, pos=>1,
                    cmdline_src=>'stdin_or_files'},
    },
};
sub append_file {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'content'})) { ((defined($args{'content'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'content'})) ? 1 : (($arg_err //= "Not of type buffer"),0)); if ($arg_err) { return [400, "Invalid argument value for content: $arg_err"] } }if (!exists($args{'content'})) { return [400, "Missing argument: content"] } no warnings ('void');if (exists($args{'path'})) { ((defined($args{'path'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'path'})) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for path: $arg_err"] } }if (!exists($args{'path'})) { return [400, "Missing argument: path"] } # VALIDATE_ARGS

    my $path = $args{path};

    sysopen my($fh), $path, O_WRONLY | O_APPEND | O_CREAT
        or return [500, "Can't open '$path' for appending: $!"];
    my $written = syswrite $fh, $args{content};
    defined($written) or return [500, "Can't append content to '$path': $!"];

    [200, "Appended $written byte(s)"];
}

1;
# ABSTRACT: Examples for reading/writing files (demos partial argument/result)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::FilePartial - Examples for reading/writing files (demos partial argument/result)

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::FilePartial (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION


The functions in this package demoes partial content upload as well as partial
result.

The functions are separated into this module because these functions read/write
files on the filesystem and might potentially be dangerous if
C<Perinci::Examples> is exposed to the network by accident.

See also C<Perinci::Examples::FileStream> which uses streaming instead of
partial.

=head1 FUNCTIONS


=head2 append_file

Usage:

 append_file(%args) -> [status, msg, payload, meta]

This function doesn't actually accept partial content, because by nature it is
already a partial/incremental operation.

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
