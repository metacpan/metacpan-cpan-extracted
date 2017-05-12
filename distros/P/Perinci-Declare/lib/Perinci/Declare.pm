package Perinci::Declare;

use 5.010001;
use strict;
use warnings;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: Some easy shortcuts for Perinci

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Declare - Some easy shortcuts for Perinci

=head1 VERSION

This document describes version 0.01 of Perinci::Declare (from Perl distribution Perinci-Declare), released on 2015-09-03.

=head1 SYNOPSIS

 package YourPackage;
 use Perinci::Declare;

 meta {
     summary 'This package is for doing blah';
     description 'blah blah ...';
 };

 sub sub1 {
     meta {
         summary 'This function is for doing blah';
         description 'blah blah ...';
         arg arg1 => (schema => 'int*', req => 1, pos => 0);
         arg arg2 => (schema => [array => of => 'str*']),
     };
     my ($arg1, $arg2) = @_;
     ...
 }

 sub sub2 {
     meta { ... }
     ...
 }

 ...
 1;

=head1 DESCRIPTION

NOT YET IMPLEMENTED.

EXPERIMENTAL, SYNTAX *WILL* CHANGE.

This module is an experiment to provide some syntactic sugar for declaring
L<Rinci> metadata to your code entities.

As we know, Rinci metadata is put in C<%SPEC> package variables:

 package YourPackage;

 our %SPEC:

 $SPEC{':package'} = {
     summary => 'THis package is for doing blah',
     description => 'Blah blah ...',
 };

 $SPEC{sub1} = {
     v => 1.1,
     summary => "This function is for doing blah",
     description => 'blah blah ...',
     args => {
         arg1 => { schema => 'int*', req => 1, pos => 0 },
         arg2 => { schema => [array => of => 'str'] },
     },
     args_as => "array",
     result_naked => 1,
 };
 sub sub1 {
     my ($arg1, $arg2) = @_;
     ...
 }

 $SPEC{sub2} = { ... }:
 sub sub2 {
     ...
 }

 ...
 1;

This module tries to provide some syntactic sugar.

How does it work? Using L<Devel::Declare>, it will change the meta():

 sub sub1 {
     meta {
         ...
     };
 }

to run in BEGIN block (much like how L<Begin::Declare> works). meta() will check
its caller, if it is inside a sub, it will set subroutine metadata. Otherwise,
it will set package metadata. The other types of metadata will be supported in
the future.

This will not add overhead during runtime, as the BEGIN block will no longer be
evaluated.

=head1 ALTERNATIVE SYNTAXES

=head2 Alternative 1

Instead of accepting a code block, C<meta> can add a hash where you specify the
metadata directly. This is easier and all Rinci properties are supported.

 sub sub1 {
     meta {
         v => 1.1,
         summary => '...',
         ...
     };
 }

=head1 KEYWORDS

=head2 meta

=head2 summary

=head2 description

=head2 arg

=head1 SEE ALSO

L<Perinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Declare>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Declare>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Declare>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
