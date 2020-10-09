package Sah::Schema::math::complex;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-Math'; # DIST
our $VERSION = '0.001'; # VERSION

use Math::Complex ();

our $schema = [obj => {
    summary   => 'Complex number',
   description => <<'_',

See also `posfloat` for floats that are larger than 0.

_
    isa => 'Math::Complex',
    'x.perl.coerce_rules' => ['From_str::math_complex'],

    examples => [
        {value=>'', valid=>0},
        {value=>'abc', valid=>0},
        {value=>Math::Complex->make(5,6), valid=>1},
        {value=>"5 + 6i", valid=>1, validated_value=>Math::Complex->make(5, 6)},
    ],
}, {}];

1;
# ABSTRACT: Complex number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::math::complex - Complex number

=head1 VERSION

This document describes version 0.001 of Sah::Schema::math::complex (from Perl distribution Sah-Schemas-Math), released on 2020-05-27.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("math::complex*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("math::complex*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['math::complex*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }
 1;

 # in myapp.pl
 package main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

Sample data:

 ""  # INVALID

 "abc"  # INVALID

 bless({c_dirty=>0,cartesian=>[5,6],display_format=>{polar_pretty_print=>1,style=>"cartesian"},p_dirty=>1},"Math::Complex")  # valid

 "5 + 6i"  # valid, becomes bless({c_dirty=>0,cartesian=>[5,6],display_format=>{polar_pretty_print=>1,style=>"cartesian"},p_dirty=>1},"Math::Complex")

=head1 DESCRIPTION

See also C<posfloat> for floats that are larger than 0.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Math>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Math>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Math>

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
