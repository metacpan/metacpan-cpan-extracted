package Perinci::Sub::XCompletion::rgb24;

our $DATE = '2018-09-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Util qw(complete_array_elem hashify_answer);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;

    sub {
        my %cargs = @_;
        my $word = $cargs{word};
        my @words;
        my $is_partial = 0;
        if ($word =~ /\A(#?)([0-9A-Fa-f]{0,6})\z/) {
            my $has_pound_sign = $1 ? 1:0;
            my $digits = lc $2;
            if (length $digits == 6) {
                push @words, $digits;
            } else {
                push @words, map {"$digits$_"} 0..9,"a".."f";
                $is_partial = 1;
            }
        }

        my $ans = hashify_answer(
            complete_array_elem(array=>\@words, word=>$word));
        $ans->{is_partial} = $is_partial;
        $ans;
    };
}

1;
# ABSTRACT: Generate digit-by-digit completion for rgb24 color

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::rgb24 - Generate digit-by-digit completion for rgb24 color

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::XCompletion::rgb24 (from Perl distribution Perinci-Sub-XCompletionBundle-Color), released on 2018-09-26.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
