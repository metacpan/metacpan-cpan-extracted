package Sah::Schema::hexstr;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-09'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.011'; # VERSION

our $schema = [str => {
    summary => 'String of bytes in hexadecimal',
    match => qr/\A(?:[0-9A-Fa-f]{2})*\z/,

    examples => [
        {value=>'', valid=>1},
        {value=>'a0', valid=>1},
        {value=>'a0f', valid=>0, summary=>'Odd number of digits (3)'},
        {value=>'a0ff', valid=>1},
        {value=>'a0fg', valid=>0, summary=>'Invalid hexdigit (g)'},
        {value=>'a0ff12345678', valid=>1},
    ],

}];

1;
# ABSTRACT: String of bytes in hexadecimal

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hexstr - String of bytes in hexadecimal

=head1 VERSION

This document describes version 0.011 of Sah::Schema::hexstr (from Perl distribution Sah-Schemas-Str), released on 2022-07-09.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid

 "a0"  # valid

 "a0f"  # INVALID (Odd number of digits (3))

 "a0ff"  # valid

 "a0fg"  # INVALID (Invalid hexdigit (g))

 "a0ff12345678"  # valid

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("hexstr*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("hexstr", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "a0ff12345678";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "a0fg";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A(?:[0-9A-Fa-f]{2})*\\z)"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("hexstr", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "a0ff12345678";
 my $res = $validator->($data); # => ["","a0ff12345678"]
 
 # a sample invalid data
 $data = "a0fg";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A(?:[0-9A-Fa-f]{2})*\\z)","a0fg"]

Data::Sah can also create validator that returns a hash of detailed error
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
     state $validator = gen_validator("hexstr*");
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
             schema => ['hexstr*'],
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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
