package Perinci::Sub::XCompletion::regexppattern_name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-RegexpPattern'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    require Complete::Regexp::Pattern;

    my %fargs = @_;

    sub {
        my %cargs = @_;
        my $word    = $cargs{word} // '';

        Complete::Regexp::Pattern::complete_regexp_pattern_pattern(
            word => $word,
        );
    },
}

1;
# ABSTRACT: Generate completion for Regexp::Pattern pattern name

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::regexppattern_name - Generate completion for Regexp::Pattern pattern name

=head1 VERSION

This document describes version 0.002 of Perinci::Sub::XCompletion::regexppattern_name (from Perl distribution Sah-Schemas-RegexpPattern), released on 2020-05-27.

=head1 ARGUMENTS

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

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-RegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-RegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-RegexpPattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
