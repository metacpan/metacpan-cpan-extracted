package Perinci::Examples::rimetadb::IncludedPackage;

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Example of included package',
    description => <<'_',

This package should be imported to database because of there is no attribute:

    x.app.rimetadb.exclude => 1

_
};

our $Var1;
$SPEC{'$Var1'} = {
    v => 1.1,
    summary => 'A sample variable',
    description => <<'_',

This variable is included because the metadata does not have this attribute:

    x.app.rimetadb.exclude => 1

_
};

our $Var2;
$SPEC{'$Var2'} = {
    v => 1.1,
    summary => 'A sample variable',
    description => <<'_',

This variable is excluded because the metadata has this attribute:

    x.app.rimetadb.exclude => 1

_
    'x.app.rimetadb.exclude' => 1,
};

$SPEC{'func1'} = {
    v => 1.1,
    summary => 'A sample function',
    description => <<'_',

This function is included because the metadata does not have this attribute:

    x.app.rimetadb.exclude => 1

_
};
sub func1 { [200] }

$SPEC{'func2'} = {
    v => 1.1,
    summary => 'A sample function',
    description => <<'_',

This function is excluded because the metadata has this attribute:

    x.app.rimetadb.exclude => 1

_
    'x.app.rimetadb.exclude' => 1,
};
sub func2 { [200] }

$SPEC{'func3'} = {
    v => 1.1,
    summary => 'A sample function',
    description => <<'_',

This function is included because the metadata does not have this attribute:

    x.app.rimetadb.exclude => 1

but some of its arguments are excluded because the argument specification has
the abovementioned attribute.

_
    args => {
        arg1 => {
            schema => 'int',
            summary => 'This argument is included',
            req => 1,
            pos => 0,
        },
        arg2 => {
            schema => 'int',
            summary => 'This argument is EXCLUDED and will not show up in the database',
            'x.app.rimetadb.exclude' => 1,
            pos => 1,
        },
        arg3 => {
            schema => 'int',
            summary => 'This argument is included',
            'x.app.rimetadb.exclude' => 0,
        },
    },
};
sub func3 { [200] }

1;
# ABSTRACT: Example of included package

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::rimetadb::IncludedPackage - Example of included package

=head1 VERSION

This document describes version 0.821 of Perinci::Examples::rimetadb::IncludedPackage (from Perl distribution Perinci-Examples), released on 2021-01-30.

=head1 DESCRIPTION


This package should be imported to database because of there is no attribute:

 x.app.rimetadb.exclude => 1

=head1 FUNCTIONS


=head2 func1

Usage:

 func1() -> [status, msg, payload, meta]

A sample function.

This function is included because the metadata does not have this attribute:

 x.app.rimetadb.exclude => 1

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



=head2 func2

Usage:

 func2() -> [status, msg, payload, meta]

A sample function.

This function is excluded because the metadata has this attribute:

 x.app.rimetadb.exclude => 1

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



=head2 func3

Usage:

 func3(%args) -> [status, msg, payload, meta]

A sample function.

This function is included because the metadata does not have this attribute:

 x.app.rimetadb.exclude => 1

but some of its arguments are excluded because the argument specification has
the abovementioned attribute.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<int>

This argument is included.

=item * B<arg2> => I<int>

This argument is EXCLUDED and will not show up in the database.

=item * B<arg3> => I<int>

This argument is included.


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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
