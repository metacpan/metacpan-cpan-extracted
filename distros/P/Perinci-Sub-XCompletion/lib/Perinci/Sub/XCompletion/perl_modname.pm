package Perinci::Sub::XCompletion::perl_modname;

our $DATE = '2019-02-24'; # DATE
our $VERSION = '0.101'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Module qw(complete_module);

our %SPEC;

$SPEC{gen_completion} = {
    v => 1.1,
};
sub gen_completion {
    my %fargs = @_;
    sub {
        my %cargs = @_;
        complete_module(%cargs, %fargs);
    };
}

1;
# ABSTRACT: Generate completion for perl module name

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::XCompletion::perl_modname - Generate completion for perl module name

=head1 VERSION

This document describes version 0.101 of Perinci::Sub::XCompletion::perl_modname (from Perl distribution Perinci-Sub-XCompletion), released on 2019-02-24.

=head1 SYNOPSIS

=head1 DESCRIPTION

This creates a completion from list of installed module names.

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-XCompletion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-XCompletion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-XCompletion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
