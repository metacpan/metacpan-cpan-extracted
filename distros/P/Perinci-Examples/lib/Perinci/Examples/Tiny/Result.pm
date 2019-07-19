package Perinci::Examples::Tiny::Result;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

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

This document describes version 0.814 of Perinci::Examples::Tiny::Result (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION

Like the other Perinci::Examples::Tiny::*, this module does not use other
modules and is suitable for testing Perinci::CmdLine::Inline as well as other
Perinci::CmdLine frameworks.

=head1 FUNCTIONS


=head2 returns_circular

Usage:

 returns_circular() -> [status, msg, payload, meta]

This function returns circular structure.

This is an example of result that needs cleaning if to be displayed as JSON.

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



=head2 returns_scalar_ref

Usage:

 returns_scalar_ref() -> [status, msg, payload, meta]

This function returns a scalar reference.

This is an example of result that needs cleaning if to be displayed as JSON.

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
