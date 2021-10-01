package Sah::Schema::hash_from_json;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-29'; # DATE
our $DIST = 'Sah-Schemas-JSON'; # DIST
our $VERSION = '0.003'; # VERSION

our $schema = [hash => {
    summary => 'Hash, coerced from JSON string',
    'prefilters' => ['JSON::decode_str'],
    examples => [
        {value=>'', valid=>0, summary=>'Empty string is not a valid JSON'},
        {value=>'1', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>'[]', valid=>0, summary=>'Valid JSON but not a hash'},
        {value=>{}, valid=>1, summary=>'Already a hash'},
        {value=>[], valid=>0, summary=>'Not a hash'},
        {value=>'foo', valid=>0, summary=>'Not a valid JSON literal'},
        {value=>'{}', valid=>1, validated_value=>{}},
        {value=>'{"a":1,"b":2}', valid=>1, validated_value=>{a=>1,b=>2}},
        {value=>'{"a":1,"b":2', valid=>0, summary=>"Missing closing curly bracket"},
    ],

}];

1;
# ABSTRACT: Hash, coerced from JSON string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hash_from_json - Hash, coerced from JSON string

=head1 VERSION

This document describes version 0.003 of Sah::Schema::hash_from_json (from Perl distribution Sah-Schemas-JSON), released on 2021-09-29.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("hash_from_json*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("hash_from_json*");
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
             schema => ['hash_from_json*'],
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

 ""  # INVALID (Empty string is not a valid JSON)

 1  # INVALID (Valid JSON but not a hash)

 "[]"  # INVALID (Valid JSON but not a hash)

 {}  # valid

 []  # INVALID (Not a hash)

 "foo"  # INVALID (Not a valid JSON literal)

 "{}"  # valid, becomes {}

 "{\"a\":1,\"b\":2}"  # valid, becomes {a=>1,b=>2}

 "{\"a\":1,\"b\":2"  # INVALID (Missing closing curly bracket)

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
