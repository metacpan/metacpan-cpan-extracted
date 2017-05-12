package Perinci::Sub::Property::arg::form;

our $DATE = '2016-05-11'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'args/*/form',
    type => 'function',
    schema => ['hash*'],
);

1;
# ABSTRACT: Specify form-related information in argument specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::arg::form - Specify form-related information in argument specification

=head1 VERSION

This document describes version 0.03 of Perinci::Sub::Property::arg::form (from Perl distribution Perinci-Sub-Property-arg-form), released on 2016-05-11.

=head1 SYNOPSIS

In function L<Rinci> metadata:

 args => {
     arg1 => {
         ...,
         'form.widget' => ...,
     },
 }

=head1 DESCRIPTION

This property is to allow form-related attributes in argument specification.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-arg-form>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-arg-form>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-arg-form>

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
