package Sah::Schema::any_from_json;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-15'; # DATE
our $DIST = 'Sah-Schemas-JSON'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = [any => {
    summary => 'A data structure, coerced from JSON string',
    'prefilters' => ['JSON::decode_str'],
    description => <<'_',

You can use this schema if you want to accept any data (a data structure or
simple scalar), but if user supplies a defined string e.g. in a command-line
script as command-line argument or option, the string will be assumed to be a
JSON-encoded value and decoded. Data will not be valid if the string does not
contain valid JSON.

Thus, if you want to supply a string, you have to JSON-encode it.

_
    examples => [
        {value=>'', valid=>0, summary=>'Empty string is not a valid JSON'},
        {value=>'1', valid=>1, summary=>"A number"},
        {value=>'null', valid=>1, validated_value=>undef},
        {value=>'foo', valid=>0, summary=>'Not a valid JSON literal, you have to encode string in JSON'},
        {value=>'"foo"', valid=>1, validated_value=>'foo', summary=>'If you want to pass a string, it must be in JSON-encoded form'},
        {value=>'[1,2,3,{}]', valid=>1, validated_value=>[1,2,3,{}]},
        {value=>'[1,2', valid=>0, summary=>'Missing closing square bracket'},
        {value=>'[1,2,]', valid=>0, summary=>'Dangling comma'},
        {value=>[1,2], valid=>1, summary=>'Not coerced, already an array'},
        {value=>{}, valid=>1, summary=>'Not coerced, already a hash'},
        {value=>undef, valid=>1, summary=>'Not coerced, already an undef'},
    ],

}];

1;
# ABSTRACT: A data structure, coerced from JSON string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::any_from_json - A data structure, coerced from JSON string

=head1 VERSION

This document describes version 0.007 of Sah::Schema::any_from_json (from Perl distribution Sah-Schemas-JSON), released on 2022-11-15.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string is not a valid JSON)

 1  # valid (A number)

 "null"  # valid, becomes undef

 "foo"  # INVALID (Not a valid JSON literal, you have to encode string in JSON)

 "\"foo\""  # valid (If you want to pass a string, it must be in JSON-encoded form), becomes "foo"

 "[1,2,3,{}]"  # valid, becomes [1,2,3,{}]

 "[1,2"  # INVALID (Missing closing square bracket)

 "[1,2,]"  # INVALID (Dangling comma)

 [1,2]  # valid (Not coerced, already an array)

 {}  # valid (Not coerced, already a hash)

 undef  # valid (Not coerced, already an undef)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("any_from_json*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("any_from_json", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = [1,2];
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "[1,2";
 my $errmsg = $validator->($data); # => "String is not a valid JSON: , or ] expected while parsing array, at character offset 4 (before \"(end of string)\") at (eval 2418) line 13.\n"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("any_from_json", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = [1,2];
 my $res = $validator->($data); # => ["",[1,2]]
 
 # a sample invalid data
 $data = "[1,2";
 my $res = $validator->($data); # => ["String is not a valid JSON: , or ] expected while parsing array, at character offset 4 (before \"(end of string)\") at (eval 2424) line 13.\n","[1,2"]

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
     state $validator = gen_validator("any_from_json*");
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
             schema => ['any_from_json*'],
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
         sah2type('$sch_name*', name=>'AnyFromJson')
     );
 }

 use My::Types qw(AnyFromJson);
 AnyFromJson->assert_valid($data);

=head1 DESCRIPTION

You can use this schema if you want to accept any data (a data structure or
simple scalar), but if user supplies a defined string e.g. in a command-line
script as command-line argument or option, the string will be assumed to be a
JSON-encoded value and decoded. Data will not be valid if the string does not
contain valid JSON.

Thus, if you want to supply a string, you have to JSON-encode it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-JSON>.

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
