package Perinci::Examples::Bin::Any::Multi;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Perinci-Examples-Bin-Any'; # DIST
our $VERSION = '0.072'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Functions to be used by peri-eg-multi-any',
};

$SPEC{add} = {
    v => 1.1,
    summary => 'A function to add to ints',
    description => <<'_',

Just a dummy description. Just a dummy description. Yup, just a dummy
description. Just a dummy description. Just a dummy description. Yeah, just a
dummy description. Just a dummy description.

_
    args => {
        arg1 => {
            schema => 'int*',
            req => 1,
            pos => 0,
            cmdline_aliases => { a=>{} },
        },
        arg2 => {
            schema => 'int*',
            req => 1,
            pos => 1,
            cmdline_aliases => { b=>{} },
        },
    },
};
sub add {
    my %args = @_;

    # we need to do validation ourselves because P::C::Lite currently doesn't do
    # it for us.
    my $a1 = $args{arg1}; defined($a1) or return [400, "Please specify arg1"];
    $a1 =~ /\A[+-]?\d+\z/ or return [400, "Invalid arg1 (not an int)"];
    my $a2 = $args{arg2}; defined($a2) or return [400, "Please specify arg2"];
    $a2 =~ /\A[+-]?\d+\z/ or return [400, "Invalid arg2 (not an int)"];

    [200, "OK", $a1 + $a2];
}

$SPEC{subtract} = {
    v => 1.1,
    summary => 'A function to subtract to ints',
    description => <<'_',

This function also has result_naked and args_as set to array.

_
    args => {
        arg1 => {
            schema => 'int*',
            req => 1,
            pos => 0,
            cmdline_aliases => { a=>{} },
        },
        arg2 => {
            schema => 'int*',
            req => 1,
            pos => 1,
            cmdline_aliases => { b=>{} },
        },
    },
    # not yet supported by P::C::Lite
    #args_as => 'array',
    result_naked => 1,
};
sub subtract {
    my %args = @_;

    # we need to do validation ourselves because P::C::Lite currently doesn't do
    # it for us.
    my $a1 = $args{a1}; defined($a1) or die [400, "Please specify arg1"];
    $a1 =~ /\A[+-]?\d+\z/ or die [400, "Invalid arg1 (not an int)"];
    my $a2 = $args{a2}; defined($a2) or die [400, "Please specify arg2"];
    $a2 =~ /\A[+-]?\d+\z/ or die [400, "Invalid arg2 (not an int)"];

    $a1 - $a2;
}

1;
# ABSTRACT: Functions to be used by peri-eg-multi-any

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Bin::Any::Multi - Functions to be used by peri-eg-multi-any

=head1 VERSION

This document describes version 0.072 of Perinci::Examples::Bin::Any::Multi (from Perl distribution Perinci-Examples-Bin-Any), released on 2022-03-08.

=head1 FUNCTIONS


=head2 add

Usage:

 add(%args) -> [$status_code, $reason, $payload, \%result_meta]

A function to add to ints.

Just a dummy description. Just a dummy description. Yup, just a dummy
description. Just a dummy description. Just a dummy description. Yeah, just a
dummy description. Just a dummy description.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<int>

=item * B<arg2>* => I<int>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 subtract

Usage:

 subtract(%args) -> any

A function to subtract to ints.

This function also has result_naked and args_as set to array.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg1>* => I<int>

=item * B<arg2>* => I<int>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples-Bin-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples-Bin-Any>.

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

This software is copyright (c) 2022, 2020, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples-Bin-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
