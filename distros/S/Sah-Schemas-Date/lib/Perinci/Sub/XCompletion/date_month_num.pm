package Perinci::Sub::XCompletion::date_month_num;

our $DATE = '2020-02-27'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(complete_array_elem);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;

    sub {
        my %cargs = @_;

        complete_array_elem(
            array => [
                1..12,
                "january","february","march","april","may","june","july","august","september","october","november","december",
            ],
            word => $cargs{word},
        );
    };
}

1;
# ABSTRACT: Generate completion for date::month_num

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::date_month_num - Generate completion for date::month_num

=head1 VERSION

This document describes version 0.008 of Perinci::Sub::XCompletion::date_month_num (from Perl distribution Sah-Schemas-Date), released on 2020-02-27.

=head1 CONFIGURATION

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [status, msg, payload, meta]

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

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::date::month_num>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
