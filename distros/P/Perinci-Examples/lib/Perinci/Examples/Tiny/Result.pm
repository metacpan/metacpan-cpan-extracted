## no critic: RequireUseStrict
package Perinci::Examples::Tiny::Result;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.822'; # VERSION

our %SPEC;

# this Rinci metadata is already normalized
$SPEC{returns_circular} = {
    v => 1.1,
    summary => "This function returns circular structure",
    description => <<'_',

This is an example of result that needs cleaning if to be displayed as JSON.

_
    args => {
    },
};
sub returns_circular {
    my $circ = [1, 2, 3];
    push @$circ, $circ;
    [200, "OK", $circ];
}

# this Rinci metadata is already normalized
$SPEC{returns_scalar_ref} = {
    v => 1.1,
    summary => "This function returns a scalar reference",
    description => <<'_',

This is an example of result that needs cleaning if to be displayed as JSON.

_
    args => {
    },
};
sub returns_scalar_ref {
    [200, "OK", \10];
}

1;
# ABSTRACT: Tests related to function result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Tiny::Result - Tests related to function result

=head1 VERSION

This document describes version 0.822 of Perinci::Examples::Tiny::Result (from Perl distribution Perinci-Examples), released on 2022-03-08.

=head1 DESCRIPTION

Like the other Perinci::Examples::Tiny::*, this module does not use other
modules and is suitable for testing Perinci::CmdLine::Inline as well as other
Perinci::CmdLine frameworks.

=head1 FUNCTIONS


=head2 returns_circular

Usage:

 returns_circular() -> [$status_code, $reason, $payload, \%result_meta]

This function returns circular structure.

This is an example of result that needs cleaning if to be displayed as JSON.

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



=head2 returns_scalar_ref

Usage:

 returns_scalar_ref() -> [$status_code, $reason, $payload, \%result_meta]

This function returns a scalar reference.

This is an example of result that needs cleaning if to be displayed as JSON.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
