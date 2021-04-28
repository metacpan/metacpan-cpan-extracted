package Perinci::Examples::rimetadb::ExcludedPackage;

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Example of excluded package',
    description => <<'_',

This package (and its contents) should not be imported to database because of
this attribute:

    x.app.rimetadb.exclude => 1

_
    'x.app.rimetadb.exclude' => 1,
};

our $Var1;
$SPEC{'$Var1'} = {
    v => 1.1,
    summary => 'A sample variable',
    description => <<'_',

Even though this variable metadata does not have this attribute:

    x.app.rimetadb.exclude => 1

but because the package is excluded, all the contents including this are also
excluded.

_
};

$SPEC{'func1'} = {
    v => 1.1,
    summary => 'A sample function',
    description => <<'_',

Even though this function metadata does not have this attribute:

    x.app.rimetadb.exclude => 1

but because the package is excluded, all the contents including this are also
excluded.

_
};
sub func1 { [200] }

1;
# ABSTRACT: Example of excluded package

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::rimetadb::ExcludedPackage - Example of excluded package

=head1 VERSION

This document describes version 0.821 of Perinci::Examples::rimetadb::ExcludedPackage (from Perl distribution Perinci-Examples), released on 2021-01-30.

=head1 DESCRIPTION


This package (and its contents) should not be imported to database because of
this attribute:

 x.app.rimetadb.exclude => 1

=head1 FUNCTIONS


=head2 func1

Usage:

 func1() -> [status, msg, payload, meta]

A sample function.

Even though this function metadata does not have this attribute:

 x.app.rimetadb.exclude => 1

but because the package is excluded, all the contents including this are also
excluded.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
