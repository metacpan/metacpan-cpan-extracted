package Perinci::Examples::Table;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010;
use strict;
use warnings;

our %SPEC;

$SPEC{aoaos} = {
    v => 1.1,
    summary => "Return an array of array-of-scalar (aoaos) data",
    args => {
    },
};
sub aoaos {
    my %args = @_;

    return [
        200, "OK",
        [[qw/ujang 25 laborer/],
         [qw/tini 33 nurse/],
         [qw/deden 27 actor/],],
        {
            'table.fields' => [qw/name age occupation/],
            'table.field_units' => [undef, 'year'],
        },
    ];
}

$SPEC{aohos} = {
    v => 1.1,
    summary => "Return an array of hash-of-scalar (aohos) data",
    args => {
    },
};
sub aohos {
    my %args = @_;

    return [
        200, "OK",
        [{name=>'ujang', age=>25, occupation=>'laborer', note=>'x'},
         {name=>'tini', age=>33, occupation=>'nurse', note=>'x'},
         {name=>'deden', age=>27, occupation=>'actor', note=>'x'},],
        {
            'table.fields' => [qw/name age occupation/],
            'table.field_units' => [undef, 'year'],
            'table.hide_unknown_fields' => 1,
        },
    ];
}
1;
# ABSTRACT: Table examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::Table - Table examples

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::Table (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION

The examples in this module return table data.

=head1 FUNCTIONS


=head2 aoaos

Usage:

 aoaos() -> [status, msg, payload, meta]

Return an array of array-of-scalar (aoaos) data.

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



=head2 aohos

Usage:

 aohos() -> [status, msg, payload, meta]

Return an array of hash-of-scalar (aohos) data.

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

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
