package Sah::Schema::color::ansi256;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-19'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.014'; # VERSION

our $schema = [int => {
    summary => 'ANSI-256 color, an integer number from 0-255',
    min => 0,
    max => 255,
    examples => [
        {value=>  0, valid=>1},
        {value=>255, valid=>1},
        {value=>256, valid=>0},
        {value=>'black'  , valid=>0}, # not supported yet
        {value=>'foo'    , valid=>0},
    ],
}, {}];

1;
# ABSTRACT: ANSI-256 color, an integer number from 0-255

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::ansi256 - ANSI-256 color, an integer number from 0-255

=head1 VERSION

This document describes version 0.014 of Sah::Schema::color::ansi256 (from Perl distribution Sah-Schemas-Color), released on 2021-07-19.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("color::ansi256*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("color::ansi256*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['color::ansi256*'],
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
 package
   main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

Sample data:

 0  # valid

 255  # valid

 256  # INVALID

 "black"  # INVALID

 "foo"  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
