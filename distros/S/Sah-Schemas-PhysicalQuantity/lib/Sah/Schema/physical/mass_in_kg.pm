package Sah::Schema::physical::mass_in_kg;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Sah-Schemas-PhysicalQuantity'; # DIST
our $VERSION = '0.001'; # VERSION

use Physics::Unit; # for examples

our $schema = [obj => {
    summary => 'A physical mass quantity, in kg',
    isa => 'Physics::Unit',
    prefilters => [
        'PhysicalQuantity::convert_from_str',
        ['PhysicalQuantity::check_type', {is=>'Mass'}],
        ['PhysicalQuantity::convert_unit', {to=>'kg'}],
    ],
    examples => [
        #{
        #    value   => '10 kg',
        #    valid   => 1,
        #    validated_value => Physics::Unit->new("10 kg"),
        #},
        #{
        #    value   => '1 tonne',
        #    valid   => 1,
        #    validated_value => Physics::Unit->new("1000 kg"),
        #},
        {
            value   => '10 s',
            valid   => 0,
        },
        {
            value   => '10',
            valid   => 0,
        },
    ],
}, {}];

1;
# ABSTRACT: A physical mass quantity, in kg

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::physical::mass_in_kg - A physical mass quantity, in kg

=head1 VERSION

This document describes version 0.001 of Sah::Schema::physical::mass_in_kg (from Perl distribution Sah-Schemas-PhysicalQuantity), released on 2020-03-11.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("physical::mass_in_kg*");
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
             schema => ['physical::mass_in_kg*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "10 s"  # INVALID

 10  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-PhysicalQuantity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-PhysicalQuantity>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-PhysicalQuantity>

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
