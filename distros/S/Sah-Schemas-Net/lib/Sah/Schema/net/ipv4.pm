package Sah::Schema::net::ipv4;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-Net'; # DIST
our $VERSION = '0.009'; # VERSION

use NetAddr::IP ();

our $schema = [obj => {
    summary => 'IPv4 address',
    isa => 'NetAddr::IP',
    'x.perl.coerce_rules' => [
        'From_str::net_ipv4',
    ],

    examples => [
        {value=>'', valid=>0},
        #{value=>'12.34.56.78', valid=>1, validated_value=>NetAddr::IP->new("12.34.56.78")}, # commented for now, is_deeply() fails
        {value=>'12.345.67.89', valid=>0},
    ],

}, {}];

1;
# ABSTRACT: IPv4 address

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::ipv4 - IPv4 address

=head1 VERSION

This document describes version 0.009 of Sah::Schema::net::ipv4 (from Perl distribution Sah-Schemas-Net), released on 2020-05-27.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("net::ipv4*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("net::ipv4*");
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
             schema => ['net::ipv4*'],
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

 "12.345.67.89"  # INVALID

=head1 DESCRIPTION

Currently using L<NetAddr::IP> object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
