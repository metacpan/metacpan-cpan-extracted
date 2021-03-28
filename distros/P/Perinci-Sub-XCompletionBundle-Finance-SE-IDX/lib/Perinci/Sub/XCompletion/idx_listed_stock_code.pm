package Perinci::Sub::XCompletion::idx_listed_stock_code;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-18'; # DATE
our $DIST = 'Perinci-Sub-XCompletionBundle-Finance-SE-IDX'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    require Complete::Finance::SE::IDX;

    my %fargs = @_;

    sub {
        my %cargs = @_;
        my $word    = $cargs{word} // '';
        #my $cmdline = $cargs{cmdline};
        #my $r       = $cargs{r};

        Complete::Finance::SE::IDX::complete_idx_listed_stock_code(word=>$word);
    };
}

1;
# ABSTRACT: Generate completion for listed stock code in the Indonesian Stock Exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::idx_listed_stock_code - Generate completion for listed stock code in the Indonesian Stock Exchange

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::XCompletion::idx_listed_stock_code (from Perl distribution Perinci-Sub-XCompletionBundle-Finance-SE-IDX), released on 2021-01-18.

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletionBundle-Finance-SE-IDX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-Finance-SE-IDX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Sub-XCompletionBundle-Finance-SE-IDX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
