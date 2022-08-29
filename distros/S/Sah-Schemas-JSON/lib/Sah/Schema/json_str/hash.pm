package Sah::Schema::json_str::hash;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-26'; # DATE
our $DIST = 'Sah-Schemas-JSON'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = [str => {
    summary => 'A string that contains valid JSON and the JSON encodes a hash (JavaScript object)',
    'prefilters' => ['JSON::check_decode_hash'],
    description => <<'_',

This schema is like the `json_str` schema: it accepts a string that contains
valid JSON. The JSON string will not be decoded but you know that the string
contains a valid JSON. In addition to that, the JSON must encode a hash
(JavaScript object). Data will not be valid if it is not a valid JSON or if the
JSON is not a hash.

Note that unlike the `hash_from_json` schema, a hash data is not accepted by
this schema. Data must be a string.

_
    examples => [
        {value=>'', valid=>0, summary=>'Empty string is not a valid JSON'},
        {value=>'1', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>'true', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>'foo', valid=>0, summary=>'Not a valid JSON literal'},
        {value=>'"foo"', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>'[]', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>'{"a":1,"b":2}', valid=>1},
        {value=>'{"a":1', valid=>0, summary=>'Invalid JSON: missing closing curly bracket'},
        {value=>'{"a":1,}', valid=>0, summary=>'Invalid JSON: dangling comma'},
    ],

}];

1;
# ABSTRACT: A string that contains valid JSON and the JSON encodes a hash (JavaScript object)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::json_str::hash - A string that contains valid JSON and the JSON encodes a hash (JavaScript object)

=head1 VERSION

This document describes version 0.006 of Sah::Schema::json_str::hash (from Perl distribution Sah-Schemas-JSON), released on 2022-08-26.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string is not a valid JSON)

 1  # INVALID (Valid JSON but not a hash)

 "true"  # INVALID (Valid JSON but not a hash)

 "foo"  # INVALID (Not a valid JSON literal)

 "\"foo\""  # INVALID (Valid JSON but not a hash)

 "[]"  # INVALID (Valid JSON but not a hash)

 "{\"a\":1,\"b\":2}"  # valid

 "{\"a\":1"  # INVALID (Invalid JSON: missing closing curly bracket)

 "{\"a\":1,}"  # INVALID (Invalid JSON: dangling comma)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("json_str::hash*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("json_str::hash", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "{\"a\":1,\"b\":2}";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "true";
 my $errmsg = $validator->($data); # => "String is a valid JSON but not an encoded hash"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("json_str::hash", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "{\"a\":1,\"b\":2}";
 my $res = $validator->($data); # => ["","{\"a\":1,\"b\":2}"]
 
 # a sample invalid data
 $data = "true";
 my $res = $validator->($data); # => ["String is a valid JSON but not an encoded hash","true"]

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
     state $validator = gen_validator("json_str::hash*");
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
             schema => ['json_str::hash*'],
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

This schema is like the C<json_str> schema: it accepts a string that contains
valid JSON. The JSON string will not be decoded but you know that the string
contains a valid JSON. In addition to that, the JSON must encode a hash
(JavaScript object). Data will not be valid if it is not a valid JSON or if the
JSON is not a hash.

Note that unlike the C<hash_from_json> schema, a hash data is not accepted by
this schema. Data must be a string.

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
