package Perinci::Examples::HTML;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-17'; # DATE
our $DIST = 'Perinci-Examples-HTML'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Examples related to HTML form generation',
};

$SPEC{hello1} = {
    v => 1.1,
    summary => "Accept a choice of salutation, an optional name and return a greeting",
    description => <<'_',

The acceptable name is restricted to safe characters only so it is safe when it
needs to be displayed as HTML without any escaping.

_
    args => {
        salutation => {
            schema => ['str*', in=>['Mr', 'Mrs']],
            pos => 0,
        },
        name => {
            schema => ['str*', match=>qr/\A[A-Za-z0-9_ -]+\z/],
            pos => 1,
        },
    },
};
sub hello1 {
    my %args = @_;

    my $salutation = $args{salutation};
    my $name = $args{name};

    if (!$salutation) {
        $name //= "you";
    } else {
        $name //= "unnamed";
    }

    [200, "OK", "Hello, ".($salutation ? "$salutation ":"")."$name!"];
}

1;
# ABSTRACT: Examples related to HTML form generation

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::HTML - Examples related to HTML form generation

=head1 VERSION

This document describes version 0.001 of Perinci::Examples::HTML (from Perl distribution Perinci-Examples-HTML), released on 2022-11-17.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 hello1

Usage:

 hello1(%args) -> [$status_code, $reason, $payload, \%result_meta]

Accept a choice of salutation, an optional name and return a greeting.

The acceptable name is restricted to safe characters only so it is safe when it
needs to be displayed as HTML without any escaping.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name> => I<str>

(No description)

=item * B<salutation> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples-HTML>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
