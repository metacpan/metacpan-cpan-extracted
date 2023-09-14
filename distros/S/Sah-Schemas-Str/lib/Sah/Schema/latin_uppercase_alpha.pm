package Sah::Schema::latin_uppercase_alpha;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-03'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'String containing only zero or more uppercase Latin letters, i.e. A-Z',
    'x.perl.coerce_rules' => ['From_str::to_upper'],
    match => qr/\A[A-Z]*\z/,

    description => <<'_',

Uppercase letters will be coerced to lowercase.

_
    examples => [
        {value=>'', valid=>1},
        {value=>'Abz', valid=>1, validated_value=>'ABZ'},
        {value=>'foo123', valid=>0, summary=>'Contains numbers'},
    ],

}];

1;
# ABSTRACT: String containing only zero or more uppercase Latin letters, i.e. A-Z

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::latin_uppercase_alpha - String containing only zero or more uppercase Latin letters, i.e. A-Z

=head1 VERSION

This document describes version 0.015 of Sah::Schema::latin_uppercase_alpha (from Perl distribution Sah-Schemas-Str), released on 2023-09-03.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid

 "Abz"  # valid, becomes "ABZ"

 "foo123"  # INVALID (Contains numbers)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("latin_uppercase_alpha*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("latin_uppercase_alpha", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "Abz";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "foo123";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A[A-Z]*\\z)"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("latin_uppercase_alpha", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "Abz";
 my $res = $validator->($data); # => ["","ABZ"]
 
 # a sample invalid data
 $data = "foo123";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A[A-Z]*\\z)","FOO123"]

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
     state $validator = gen_validator("latin_uppercase_alpha*");
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
             schema => ['latin_uppercase_alpha*'],
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

 % validate-with-sah '"latin_uppercase_alpha*"' '"data..."'

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
         sah2type('latin_uppercase_alpha*', name=>'LatinUppercaseAlpha')
     );
 }

 use My::Types qw(LatinUppercaseAlpha);
 LatinUppercaseAlpha->assert_valid($data);

=head1 DESCRIPTION

Uppercase letters will be coerced to lowercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah::Schema::latin_alpha>

L<Sah::Schema::latin_lowercase_alpha>

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

This software is copyright (c) 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
