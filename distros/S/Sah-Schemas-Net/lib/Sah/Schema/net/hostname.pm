package Sah::Schema::net::hostname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-19'; # DATE
our $DIST = 'Sah-Schemas-Net'; # DIST
our $VERSION = '0.010'; # VERSION

our $schema = [str => {
    summary => 'Hostname',
    match => '\\A(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\\z', # as per RFC 1123

    examples => [
        {value=>'', valid=>0},
        {value=>'example', valid=>1},
        {value=>'example.com', valid=>1},
        {value=>'www.example.com', valid=>1},
        {value=>'12.34.56.78', valid=>1},
        #{value=>'12.34.56.789', valid=>0}, # should invalid ipv4 be allowed?
        {value=>'www_new.example.com', valid=>0, summary=>'Underscore not allowed'},
        {value=>'www.example-two.com', valid=>1},
        {value=>'www.example--two.com', valid=>1},
        {value=>'www.example-.com', valid=>0, summary=>'Word ending in dash not allowed'},
        {value=>'www.-example.com', valid=>0, summary=>'Word starting in dash not allowed'},
        {value=>'www.-example.com', valid=>0, summary=>'Word starting in dash not allowed'},
    ],

}, {}];

1;
# ABSTRACT: Hostname

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::hostname - Hostname

=head1 VERSION

This document describes version 0.010 of Sah::Schema::net::hostname (from Perl distribution Sah-Schemas-Net), released on 2021-07-19.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("net::hostname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("net::hostname*");
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
             schema => ['net::hostname*'],
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

 ""  # INVALID

 "example"  # valid

 "example.com"  # valid

 "www.example.com"  # valid

 "12.34.56.78"  # valid

 "www_new.example.com"  # INVALID (Underscore not allowed)

 "www.example-two.com"  # valid

 "www.example--two.com"  # valid

 "www.example-.com"  # INVALID (Word ending in dash not allowed)

 "www.-example.com"  # INVALID (Word starting in dash not allowed)

 "www.-example.com"  # INVALID (Word starting in dash not allowed)

=head1 DESCRIPTION

Hostname is checked using a regex as per RFC 1123.

Ref: L<https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address>

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
