package Perinci::Examples::Coercion;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

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

This document describes version 0.814 of Perinci::Examples::Coercion (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 coerce_to_epoch

Usage:

 coerce_to_epoch(%args) -> [status, msg, payload, meta]

Accept a date (e.g. '2015-11-20', etc), return its Unix epoch.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date>* => I<date>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 coerce_to_secs

Usage:

 coerce_to_secs(%args) -> [status, msg, payload, meta]

Accept a duration (e.g. '2hour', 'P2D'), return number of seconds.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<duration>* => I<duration>

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
