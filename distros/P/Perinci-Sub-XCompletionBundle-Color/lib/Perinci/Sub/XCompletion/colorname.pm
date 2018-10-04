package Perinci::Sub::XCompletion::colorname;

our $DATE = '2018-09-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(complete_hash_key);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;

    sub {
        require Graphics::ColorNames;

        my %cargs = @_;

        my $scheme = $fargs{scheme} // 'X';
        tie my %colors, 'Graphics::ColorNames', $scheme;
        complete_hash_key(hash=>\%colors, word=>$cargs{word});
    };
}

1;
# ABSTRACT: Generate completion for color names (names from Graphics::ColorNames scheme)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::colorname - Generate completion for color names (names from Graphics::ColorNames scheme)

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::XCompletion::colorname (from Perl distribution Perinci-Sub-XCompletionBundle-Color), released on 2018-09-26.

=head1 CONFIGURATION

=head2 scheme

str, default C<X>. Set L<Graphics::ColorNames> scheme to use.

=head1 FUNCTIONS


=head2 gen_completion

Usage:

 gen_completion() -> [status, msg, result, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletionBundle-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Graphics::ColorNames>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
