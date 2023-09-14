package Perinci::Examples::Coercion;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Perinci-Examples'; # DIST
our $VERSION = '0.824'; # VERSION

our %SPEC;

$SPEC{coerce_to_epoch} = {
    v => 1.1,
    summary => "Accept a date (e.g. '2015-11-20', etc), return its Unix epoch",
    args => {
        date => {
            schema => ['date*', {
                'x.perl.coerce_to' => 'float(epoch)',
            }],
            req => 1,
            pos => 0,
        },
    },
};
sub coerce_to_epoch {
    my %args = @_;
    [200, "OK", $args{date}];
}

$SPEC{coerce_to_secs} = {
    v => 1.1,
    summary => "Accept a duration (e.g. '2hour', 'P2D'), return number of seconds",
    args => {
        duration => {
            schema => ['duration*', {
                'x.perl.coerce_to' => 'float(secs)',
            }],
            req => 1,
            pos => 0,
        },
    },
};
sub coerce_to_secs {
    my %args = @_;
    [200, "OK", $args{duration}];
}

1;
# ABSTRACT: Coercion examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Coercion - Coercion examples

=head1 VERSION

This document describes version 0.824 of Perinci::Examples::Coercion (from Perl distribution Perinci-Examples), released on 2023-07-09.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 coerce_to_epoch

Usage:

 coerce_to_epoch(%args) -> [$status_code, $reason, $payload, \%result_meta]

Accept a date (e.g. '2015-11-20', etc), return its Unix epoch.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

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



=head2 coerce_to_secs

Usage:

 coerce_to_secs(%args) -> [$status_code, $reason, $payload, \%result_meta]

Accept a duration (e.g. '2hour', 'P2D'), return number of seconds.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
