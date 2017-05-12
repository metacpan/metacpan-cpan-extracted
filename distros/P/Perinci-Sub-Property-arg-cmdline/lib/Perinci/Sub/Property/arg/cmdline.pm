package Perinci::Sub::Property::arg::cmdline;

our $DATE = '2016-05-11'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'args/*/cmdline',
    type => 'function',
    schema => ['hash*'],
);

1;
# ABSTRACT: Specify command-line-related attributes in argument specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::arg::cmdline - Specify command-line-related attributes in argument specification

=head1 VERSION

This document describes version 0.02 of Perinci::Sub::Property::arg::cmdline (from Perl distribution Perinci-Sub-Property-arg-cmdline), released on 2016-05-11.

=head1 SYNOPSIS

In function L<Rinci> metadata:

 args => {
     arg1 => {
         ...,
         'cmdline.chomp' => ...,
     },
 }

=head1 DESCRIPTION

This property is to allow command-line-related attributes in argument
specification.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-arg-cmdline>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-arg-cmdline>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-arg-cmdline>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
