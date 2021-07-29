package Perinci::Sub::XCompletion::chrome_profile_name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Chrome'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Chrome qw(complete_chrome_profile_name);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;
    sub {
        my %cargs = @_;
        complete_chrome_profile_name(%cargs, %fargs);
    };
}

1;
# ABSTRACT: Generate completion for Chrome profile name

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::chrome_profile_name - Generate completion for Chrome profile name

=head1 VERSION

This document describes version 0.003 of Perinci::Sub::XCompletion::chrome_profile_name (from Perl distribution Sah-Schemas-Chrome), released on 2021-07-20.

=head1 SYNOPSIS

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

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Chrome>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Chrome>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Chrome>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
