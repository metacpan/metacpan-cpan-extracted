package Sah::Schema::net::hostname;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-03'; # DATE
our $DIST = 'Sah-Schemas-Net'; # DIST
our $VERSION = '0.011'; # VERSION

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

}];

1;
# ABSTRACT: Hostname

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::net::hostname - Hostname

=head1 VERSION

This document describes version 0.011 of Sah::Schema::net::hostname (from Perl distribution Sah-Schemas-Net), released on 2022-05-03.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

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

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("net::hostname*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean value (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("net::hostname", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "www.example--two.com";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "www_new.example.com";
 my $errmsg = $validator->($data); # => "Must match regex pattern \\A(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])\\z"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("net::hostname", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "www.example--two.com";
 my $res = $validator->($data); # => ["","www.example--two.com"]
 
 # a sample invalid data
 $data = "www_new.example.com";
 my $res = $validator->($data); # => ["Must match regex pattern \\A(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])\\z","www_new.example.com"]

Data::Sah can also create validator that returns a hash of detaild error
message. Data::Sah can even create validator that targets other language, like
JavaScript, from the same schema. Other things Data::Sah can do: show source
code for validator, generate a validator code with debug comments and/or log
statements, generate human text from schema. See its documentation for more
details.

=head2 Using with Params::Sah

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("net::hostname*");
     $validator->(\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

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
 Perinci::CmdLine::Any->new(url=>'/MyApp/myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head1 DESCRIPTION

Hostname is checked using a regex as per RFC 1123.

Ref: L<https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Net>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Net>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Net>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
