package Sah::Schema::business::id::nop_pbb;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-10'; # DATE
our $DIST = 'Sah-Schemas-Business-ID-NOPPBB'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => 'Indonesian property tax number (NOP PBB)',
    prefilters => ['Str::remove_nondigit', 'Business::ID::NOPPBB::check_nop_pbb'],
    description => <<'MARKDOWN',

MARKDOWN
    examples => [
        {value=>'', valid=>0, summary=>'Empty string'},
        {value=>'123', valid=>0, summary=>'Too short'},
        {value=>'327311000109900990', valid=>1},
        {value=>'32.73.110.001.099-0099.0', valid=>1, summary=>'Non-digits removed', validated_value=>'327311000109900990'},
    ],
}];

1;

# ABSTRACT: Indonesian property tax number (NOP PBB)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::business::id::nop_pbb - Indonesian property tax number (NOP PBB)

=head1 VERSION

This document describes version 0.001 of Sah::Schema::business::id::nop_pbb (from Perl distribution Sah-Schemas-Business-ID-NOPPBB), released on 2024-01-10.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     prefilters => ["Str::remove_nondigit", "Business::ID::NOPPBB::check_nop_pbb"],
     summary    => "Indonesian property tax number (NOP PBB)",
   },
 ]

Base type: L<str|Data::Sah::Type::str>

Used prefilters: L<Str::remove_nondigit|Data::Sah::Filter::perl::Str::remove_nondigit>, L<Business::ID::NOPPBB::check_nop_pbb|Data::Sah::Filter::perl::Business::ID::NOPPBB::check_nop_pbb>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string)

 123  # INVALID (Too short)

 327311000109900990  # valid

 "32.73.110.001.099-0099.0"  # valid (Non-digits removed), becomes 327311000109900990

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("business::id::nop_pbb*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("business::id::nop_pbb", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 327311000109900990;
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = 123;
 my $errmsg = $validator->($data); # => "Length must be 18 digits"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("business::id::nop_pbb", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 327311000109900990;
 my $res = $validator->($data); # => ["",327311000109900990]
 
 # a sample invalid data
 $data = 123;
 my $res = $validator->($data); # => ["Length must be 18 digits",123]

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
     state $validator = gen_validator("business::id::nop_pbb*");
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
             schema => ['business::id::nop_pbb*'],
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

 % validate-with-sah '"business::id::nop_pbb*"' '"data..."'

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
         sah2type('business::id::nop_pbb*', name=>'BusinessIdNopPbb')
     );
 }

 use My::Types qw(BusinessIdNopPbb);
 BusinessIdNopPbb->assert_valid($data);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Business-ID-NOPPBB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Business-ID-NOPPBB>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Business-ID-NOPPBB>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
