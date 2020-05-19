package Perinci::Examples::SahSchemas;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-14'; # DATE
our $DIST = 'Perinci-Examples-SahSchemas'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

# package metadata
$SPEC{':package'} = {
    v => 1.1,
    summary => 'Example for using various schemas',
};

$SPEC{schema_perl_modname} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'perl::modname*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_perl_modname {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_perl_distname} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'perl::distname*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_perl_distname {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_filename} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_filename {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_dirname} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'dirname*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_dirname {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_pathname} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'pathname*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_pathname {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_date} = {
    v => 1.1,
    args => {
        datetime => {
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
        },
        epoch => {
            schema => ['date*', 'x.perl.coerce_to' => 'float(epoch)'],
        },
        time_moment => {
            schema => ['date*', 'x.perl.coerce_to' => 'Time::Moment'],
        },
    },
};
sub schema_date {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_filesize} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'filesize*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_filesize {
    my %args = @_;
    [200, "OK", \%args];
}

$SPEC{schema_bandwidth} = {
    v => 1.1,
    args => {
        mod => {
            schema => 'bandwidth*',
            req => 1,
            pos => 0,
        },
    },
};
sub schema_bandwidth {
    my %args = @_;
    [200, "OK", \%args];
}

1;
# ABSTRACT: Example for using various schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::SahSchemas - Example for using various schemas

=head1 VERSION

This document describes version 0.003 of Perinci::Examples::SahSchemas (from Perl distribution Perinci-Examples-SahSchemas), released on 2020-03-14.

=head1 FUNCTIONS


=head2 schema_bandwidth

Usage:

 schema_bandwidth(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<bandwidth>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_date

Usage:

 schema_date(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<datetime> => I<date>

=item * B<epoch> => I<date>

=item * B<time_moment> => I<date>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_dirname

Usage:

 schema_dirname(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<dirname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_filename

Usage:

 schema_filename(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<filename>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_filesize

Usage:

 schema_filesize(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<filesize>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_pathname

Usage:

 schema_pathname(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<pathname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_perl_distname

Usage:

 schema_perl_distname(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<perl::distname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 schema_perl_modname

Usage:

 schema_perl_modname(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<mod>* => I<perl::modname>


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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples-SahSchemas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples-SahSchemas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples-SahSchemas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
