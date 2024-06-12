package Sah::Schema::color::ansi16;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-08'; # DATE
our $DIST = 'Sah-SchemaBundle-Color'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc',
    match => qr/\A(?:0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|
                    (?:(bold|bright) \s )?(black|red|green|yellow|blue|magenta|cyan|white))\z/ix,
    examples => [
        {value=> 0, valid=>1},
        {value=>15, valid=>1},
        {value=>16, valid=>0},
        {value=>'black'  , valid=>1, validated_value=>'black'},
        {value=>'foo'    , valid=>0},
    ],
}];

1;
# ABSTRACT: ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::ansi16 - ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc

=head1 VERSION

This document describes version 0.015 of Sah::Schema::color::ansi16 (from Perl distribution Sah-SchemaBundle-Color), released on 2024-06-08.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     match => qr/\A(?:0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|
                         (?:(bold|bright) \s )?(black|red|green|yellow|blue|magenta|cyan|white))\z/ix,
   },
 ]

Base type: L<str|Data::Sah::Type::str>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 0  # valid

 15  # valid

 16  # INVALID

 "black"  # valid, becomes "black"

 "foo"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("color::ansi16*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("color::ansi16", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 15;
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = 16;
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A(?:0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|\n                    (?:(bold|bright) \\s )?(black|red|green|yellow|blue|magenta|cyan|white))\\z)ix"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("color::ansi16", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 15;
 my $res = $validator->($data); # => ["",15]
 
 # a sample invalid data
 $data = 16;
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A(?:0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|\n                    (?:(bold|bright) \\s )?(black|red|green|yellow|blue|magenta|cyan|white))\\z)ix",16]

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
     state $validator = gen_validator("color::ansi16*");
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
             schema => ['color::ansi16*'],
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

 % validate-with-sah '"color::ansi16*"' '"data..."'

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
         sah2type('color::ansi16*', name=>'ColorAnsi16')
     );
 }

 use My::Types qw(ColorAnsi16);
 ColorAnsi16->assert_valid($data);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Color>.

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
