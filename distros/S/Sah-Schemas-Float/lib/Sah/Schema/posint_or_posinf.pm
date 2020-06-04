package Sah::Schema::posint_or_posinf;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.011'; # VERSION

our $schema = [any => {
    of => [
        ['posint', {}, {}],
        ['posinf', {}, {}],
    ],
    summary => 'Positive integer, or Inf',
    description => <<'_',

Can be used to check value for number of items in a (possibly infinite)
sequence.

_
    examples => [
        {value=>0, valid=>0},
        {value=>0.1, valid=>0},
        {value=>1, valid=>1},
        {value=>-0.1, valid=>0},
        {value=>-1, valid=>0},
        {value=>"Inf", valid=>1},
        {value=>"-Inf", valid=>0},
        {value=>"NaN", valid=>0},
    ],
}, {}];

1;
# ABSTRACT: Positive integer, or Inf

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::posint_or_posinf - Positive integer, or Inf

=head1 VERSION

This document describes version 0.011 of Sah::Schema::posint_or_posinf (from Perl distribution Sah-Schemas-Float), released on 2020-06-04.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("posint_or_posinf*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("posint_or_posinf*");
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
             schema => ['posint_or_posinf*'],
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

 0  # INVALID

 0.1  # INVALID

 1  # valid

 -0.1  # INVALID

 -1  # INVALID

 "Inf"  # valid

 "-Inf"  # INVALID

 "NaN"  # INVALID

=head1 DESCRIPTION

Can be used to check value for number of items in a (possibly infinite)
sequence.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
