package Sah::Schema::sah::str_schema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Sah-Schemas-Sah'; # DIST
our $VERSION = '0.9.49.1'; # VERSION

use 5.010001;
use strict;
use warnings;

our $schema = ['str' => {
    match => '\A[A-Za-z][A-Za-z0-9_]*(::[A-Za-z][A-Za-z0-9_]*)*\*?\z',
}, {}];

1;
# ABSTRACT: Sah schema (string form)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::sah::str_schema - Sah schema (string form)

=head1 VERSION

This document describes version 0.9.49.1 of Sah::Schema::sah::str_schema (from Perl distribution Sah-Schemas-Sah), released on 2020-05-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("sah::str_schema*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['sah::str_schema*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
