package Sah::Schema::physical::unit;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-04'; # DATE
our $DIST = 'Sah-Schemas-PhysicalQuantity'; # DIST
our $VERSION = '0.002'; # VERSION

use Physics::Unit ();

our $schema = [str => {
    summary => 'A physical unit',
    description => <<'_',

All units recognized by <pm:Physics::Unit> are valid.

_
    in => [Physics::Unit::ListUnits()],
    examples => [
        {value=>"", valid=>0},
        {value=>"kg", valid=>1},
        {value=>"foo", valid=>0},
    ],
}, {}];

1;
# ABSTRACT: A physical unit

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::physical::unit - A physical unit

=head1 VERSION

This document describes version 0.002 of Sah::Schema::physical::unit (from Perl distribution Sah-Schemas-PhysicalQuantity), released on 2020-04-04.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("physical::unit*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used in L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['physical::unit*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 undef  # INVALID

 undef  # valid

 undef  # INVALID

=head1 DESCRIPTION

All units recognized by L<Physics::Unit> are valid.

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
