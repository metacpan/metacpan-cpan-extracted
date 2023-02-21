package Sah::Schema::json_or_str;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-15'; # DATE
our $DIST = 'Sah-Schemas-JSON'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = [any => {
    summary => 'A JSON-encoded data or string',
    'prefilters' => ['Str::try_decode_json'],
    description => <<'_',

You can use this schema if you want to accept any data (a data structure or
simple scalar), and if user supplies a defined string e.g. in a command-line
script as command-line argument or option, it will be tried to be JSON-decoded
first. If the string does not contain valid JSON, it will be left as-is as
string.

This schema is convenient on the command-line where you want to accept data
structure via command-line argument or option. But you have to be careful when
you want to pass a string like `null`, `true`, `false`; you have to quote it to
`"null"`, `"true"`, `"false"` to prevent it being decoded into undef or
boolean values.

See also related schema: `json_str`, `str::encoded_json`, `str::escaped_json`.

_
    examples => [
        {value=>'', valid=>1, summary=>'Empty string, left as-is as string'},
        {value=>'1', valid=>1},
        {value=>'null', valid=>1, validated_value=>undef, summary=>"JSON-decoded and becomes undef"},
        {value=>'"null"', valid=>1, validated_value=>"null", summary=>"JSON-decoded into string"},
        {value=>'[1,2,3,{}]', valid=>1, validated_value=>[1,2,3,{}], summary=>"JSON-decoded into array"},
        {value=>'[1,2', valid=>1, summary=>'Left as-is as string since it is invalid JSON (missing closing square bracket)'},
        {value=>'[1,2,]', valid=>1, summary=>'Left as-is as string since it is invalid JSON (dangling comma)'},
        {value=>[1,2], valid=>1, summary=>'Not coerced, already an array'},
        {value=>{}, valid=>1, summary=>'Not coerced, already a hash'},
        {value=>undef, valid=>1, summary=>'Not coerced, already an undef'},
    ],

}];

1;
# ABSTRACT: A JSON-encoded data or string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::json_or_str - A JSON-encoded data or string

=head1 VERSION

This document describes version 0.007 of Sah::Schema::json_or_str (from Perl distribution Sah-Schemas-JSON), released on 2022-11-15.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid (Empty string, left as-is as string)

 1  # valid

 "null"  # valid (JSON-decoded and becomes undef), becomes undef

 "\"null\""  # valid (JSON-decoded into string), becomes "null"

 "[1,2,3,{}]"  # valid (JSON-decoded into array), becomes [1,2,3,{}]

 "[1,2"  # valid (Left as-is as string since it is invalid JSON (missing closing square bracket))

 "[1,2,]"  # valid (Left as-is as string since it is invalid JSON (dangling comma))

 [1,2]  # valid (Not coerced, already an array)

 {}  # valid (Not coerced, already a hash)

 undef  # valid (Not coerced, already an undef)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("json_or_str*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("json_or_str", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = undef;
 my $errmsg = $validator->($data); # => ""

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("json_or_str", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = undef;
 my $res = $validator->($data); # => ["",undef]

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
     state $validator = gen_validator("json_or_str*");
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
             schema => ['json_or_str*'],
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


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema:

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('$sch_name*', name=>'JsonOrStr')
     );
 }

 use My::Types qw(JsonOrStr);
 JsonOrStr->assert_valid($data);

=head1 DESCRIPTION

You can use this schema if you want to accept any data (a data structure or
simple scalar), and if user supplies a defined string e.g. in a command-line
script as command-line argument or option, it will be tried to be JSON-decoded
first. If the string does not contain valid JSON, it will be left as-is as
string.

This schema is convenient on the command-line where you want to accept data
structure via command-line argument or option. But you have to be careful when
you want to pass a string like C<null>, C<true>, C<false>; you have to quote it to
C<"null">, C<"true">, C<"false"> to prevent it being decoded into undef or
boolean values.

See also related schema: C<json_str>, C<str::encoded_json>, C<str::escaped_json>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-JSON>.

=head1 SEE ALSO

L<Sah::Schema::json_str>

L<Sah::Schema::str::encoded_json>

L<Sah::Schema::str::escaped_json>

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
