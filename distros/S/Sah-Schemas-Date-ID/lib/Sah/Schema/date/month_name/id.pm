package Sah::Schema::date::month_name::id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [cistr => {
    summary => 'Month name (abbreviated or full, in Indonesian)',
    in => [
        qw/jan feb mar apr mei jun jul agu sep okt nov des/,
        qw/januari februari maret april juni juli agustus september oktober november desember/,
    ],
    examples => [
        {value=>'', valid=>0},
        {value=>'jan', valid=>1},
        {value=>'FEBRUARI', valid=>1},
        {value=>'march', valid=>0, summary=>'English'},
        {value=>0, valid=>0},
        {value=>1, valid=>0},
        {value=>12, valid=>0},
        {value=>13, valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Month name (abbreviated or full, in Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::month_name::id - Month name (abbreviated or full, in Indonesian)

=head1 VERSION

This document describes version 0.005 of Sah::Schema::date::month_name::id (from Perl distribution Sah-Schemas-Date-ID), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("date::month_name::id*");
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
             schema => ['date::month_name::id*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 ""  # INVALID

 "jan"  # valid

 "FEBRUARI"  # valid

 "march"  # INVALID (English)

 0  # INVALID

 1  # INVALID

 12  # INVALID

 13  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
