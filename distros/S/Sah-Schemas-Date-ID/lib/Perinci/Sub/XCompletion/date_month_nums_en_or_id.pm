package Perinci::Sub::XCompletion::date_month_nums_en_or_id;

our $DATE = '2021-08-04'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(complete_comma_sep);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;

    sub {
        my %cargs = @_;

        complete_comma_sep(
            elems => [
                1..12,
                # english
                "january","february","march","april","may","june","july","august","september","october","november","december",
                # indonesian
                "januari","februari","maret","april","mei","juni","juli","agustus","september","oktober","november","desember",
            ],
            word => $cargs{word},
        );
    };
}

1;
# ABSTRACT: Generate completion for date::month_nums

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::date_month_nums_en_or_id - Generate completion for date::month_nums

=head1 VERSION

This document describes version 0.007 of Perinci::Sub::XCompletion::date_month_nums_en_or_id (from Perl distribution Sah-Schemas-Date-ID), released on 2021-08-04.

=head1 CONFIGURATION

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [$status_code, $reason, $payload, \%result_meta]

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

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::date::month_nums>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
