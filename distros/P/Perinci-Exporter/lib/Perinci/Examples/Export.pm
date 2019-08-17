## no critic: Modules::ProhibitAutomaticExportation

package Perinci::Examples::Export;

our $DATE = '2019-08-15'; # DATE
our $VERSION = '0.080'; # VERSION

# be lean
#use strict;
#use warnings;

use Perinci::Exporter;

our %SPEC;

our @EXPORT_OK = qw(f7);
our @EXPORT = qw(f1 f2);

$SPEC{f1} = { v => 1.1, tags => [qw/a b export:default/] };
sub   f1 { [200, "OK", "f1"] }

$SPEC{f2} = { v => 1.1, tags => [qw/b export:default/] };
sub   f2 { [200, "OK", "f2"] }

$SPEC{f3} = { v => 1.1, tags => [qw/a export:default/] };
sub   f3 { [200, "OK", "f3"] }

$SPEC{f4} = { v => 1.1, tags => [qw/export:default/] };
sub   f4 { [200, "OK", "f4"] }

$SPEC{f5} = { v => 1.1, tags => [qw/a b/] };
sub   f5 { [200, "OK", "f5"] }

$SPEC{f6} = { v => 1.1, tags => [qw/a/] };
sub   f6 { [200, "OK", "f6"] }

$SPEC{f7} = { v => 1.1, tags => [qw/b/] };
sub   f7 { [200, "OK", "f7"] }

$SPEC{f8} = { v => 1.1, tags => [qw//] };
sub   f8 { [200, "OK", "f8"] }

$SPEC{f9} = { v => 1.1, tags => [qw/a b export:never/] };
sub   f9 { [200, "OK", "f9"] }

1;
# ABSTRACT: Examples for exporting

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Export - Examples for exporting

=head1 VERSION

This document describes version 0.080 of Perinci::Examples::Export (from Perl distribution Perinci-Exporter), released on 2019-08-15.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 f1

Usage:

 f1() -> [status, msg, payload, meta]

This function is exported by default.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 f2

Usage:

 f2() -> [status, msg, payload, meta]

This function is exported by default.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 f3

Usage:

 f3() -> [status, msg, payload, meta]

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



=head2 f4

Usage:

 f4() -> [status, msg, payload, meta]

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



=head2 f5

Usage:

 f5() -> [status, msg, payload, meta]

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



=head2 f6

Usage:

 f6() -> [status, msg, payload, meta]

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



=head2 f7

Usage:

 f7() -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 f8

Usage:

 f8() -> [status, msg, payload, meta]

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



=head2 f9

Usage:

 f9() -> [status, msg, payload, meta]

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Exporter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Exporter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Exporter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
