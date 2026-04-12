package Sah::Schema::cfbase32_str;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-01-28'; # DATE
our $DIST = 'Sah-SchemaBundle-CrockfordBase32'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => "A Crockford's Base 32-encoded string",
    match => qr/\A[0-9A-HJKMNP-TV-Z]*\Z/,
    'prefilters' => [
        'Str::upcase',
        'CrockfordBase32::normalize',
    ],
    examples => [
        {value=>'', valid=>1},
        {value=>'123', valid=>1},
        {value=>'L23OIabc', valid=>1, validated_value=>'12301ABC'},
        {value=>'1U', valid=>0, 'invalid digit'},
        {value=>'1_', valid=>0, 'invalid digit'},
    ],
}];

1;

# ABSTRACT: A Crockford's Base 32-encoded string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cfbase32_str - A Crockford's Base 32-encoded string

=head1 VERSION

This document describes version 0.001 of Sah::Schema::cfbase32_str (from Perl distribution Sah-SchemaBundle-CrockfordBase32), released on 2026-01-28.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     prefilters => ["Str::upcase", "CrockfordBase32::normalize"],
     match => qr/\A[0-9A-HJKMNP-TV-Z]*\Z/,
   },
 ]

Base type: L<str|Data::Sah::Type::str>

Used prefilters: L<Str::upcase|Data::Sah::Filter::perl::Str::upcase>, L<CrockfordBase32::normalize|Data::Sah::Filter::perl::CrockfordBase32::normalize>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid

 123  # valid

 "L23OIabc"  # valid, becomes "12301ABC"

 "1U"  # INVALID

 "1_"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("cfbase32_str*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("cfbase32_str", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "1_";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A[0-9A-HJKMNP-TV-Z]*\\Z)"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("cfbase32_str", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "";
 my $res = $validator->($data); # => ["",""]
 
 # a sample invalid data
 $data = "1_";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A[0-9A-HJKMNP-TV-Z]*\\Z)","1_"]

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
     state $validator = gen_validator("cfbase32_str*");
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
             schema => ['cfbase32_str*'],
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

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"cfbase32_str*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('cfbase32_str*', name=>'Cfbase32Str')
     );
 }

 use My::Types qw(Cfbase32Str);
 Cfbase32Str->assert_valid($data);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-CrockfordBase32>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-CrockfordBase32>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-CrockfordBase32>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
