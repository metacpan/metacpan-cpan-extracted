package Sah::Schema::int_range;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Sah-Schemas-IntRange'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [str => {
    summary => 'Integer range (sequence of ints/simple ranges), e.g. 1 / -5-7 / 1,10 / 1,5-7,10',
    match => qr/\A
                (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                (
                    \s*,\s*
                    (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                )*\z/x,
    prefilters => ['IntRange::check_int_range'],
    examples => [
        {data=>'', valid=>0, summary=>'Empty string'},

        # single int

        {data=>'1', valid=>1},
        {data=>'-2', valid=>1},

        {data=>'1.5', valid=>0, summary=>'Float'},

        # simple int range

        {data=>'1-1', valid=>1},
        {data=>'1-2', valid=>1},
        {data=>'1 - 2', valid=>1},
        {data=>'0-100', valid=>1},
        {data=>'-1-2', valid=>1},
        {data=>'-10--1', valid=>1},

        {data=>'1-', valid=>0, summary=>'Missing end value'},
        {data=>'1-1.5', valid=>0, sumary=>'Float'},
        {data=>'9-2', valid=>0, summary=>'start value cannot be larger than end value'},
        {data=>'1-2-3', valid=>0, summary=>'Invalid simple int range syntax'},
        {data=>' 1-2 ', valid=>0, summary=>'Leading and trailing whitespace is currently not allowed'},

        # simple int seq

        {data=>'1,2', valid=>1},
        {data=>'1 , 2', valid=>1},
        {data=>'1,2,-3,4', valid=>1},

        {data=>'1,2,-3,4.5', valid=>0, summary=>'Float'},
        {data=>'1,', valid=>0, summary=>'Dangling comma is currently not allowed'},
        {data=>'1,,2', valid=>0, summary=>'Multiple commas are currently not allowed'},

        # seq of ints/simple int ranges

        {data=>'1,2-5', valid=>1},
        {data=>'-1,-2-5,7,9-9', valid=>1},

        {data=>'1,9-2', valid=>0, summary=>'start value cannot be larger than end value'},

    ],
}, {}];

1;
# ABSTRACT: Integer range (sequence of ints/simple ranges), e.g. 1 / -5-7 / 1,10 / 1,5-7,10

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::int_range - Integer range (sequence of ints/simple ranges), e.g. 1 / -5-7 / 1,10 / 1,5-7,10

=head1 VERSION

This document describes version 0.004 of Sah::Schema::int_range (from Perl distribution Sah-Schemas-IntRange), released on 2021-07-17.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("int_range*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("int_range*");
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
             schema => ['int_range*'],
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

 ""  # INVALID (Empty string)

 1  # valid

 -2  # valid

 1.5  # INVALID (Float)

 "1-1"  # valid

 "1-2"  # valid

 "1 - 2"  # valid

 "0-100"  # valid

 "-1-2"  # valid

 "-10--1"  # valid

 "1-"  # INVALID (Missing end value)

 "1-1.5"  # INVALID

 "9-2"  # INVALID (start value cannot be larger than end value)

 "1-2-3"  # INVALID (Invalid simple int range syntax)

 " 1-2 "  # INVALID (Leading and trailing whitespace is currently not allowed)

 "1,2"  # valid

 "1 , 2"  # valid

 "1,2,-3,4"  # valid

 "1,2,-3,4.5"  # INVALID (Float)

 "1,"  # INVALID (Dangling comma is currently not allowed)

 "1,,2"  # INVALID (Multiple commas are currently not allowed)

 "1,2-5"  # valid

 "-1,-2-5,7,9-9"  # valid

 "1,9-2"  # INVALID (start value cannot be larger than end value)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-IntRange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-IntRange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-IntRange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
