package Sah::Schema::code_from_str;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-10'; # DATE
our $DIST = 'Sah-SchemaBundle-Code'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [
    code => {
        summary => 'Coderef from eval\`ed string',
        description => <<'MARKDOWN',

This schema accepts coderef or string which will be eval'ed to coderef. Note
that this means allowing your user to provide arbitrary Perl code for you to
execute! Make sure first and foremost that security-wise this is acceptable in
your case.

By default `eval()` is performed in the `main` namespace and without stricture
or warnings. See the parameterized version <pm:Sah::PSchema::code_from_str> if
you want to customize the `eval()`.

What's the difference between this schema and `str_or_code` (from
<pm:Sah::Schemas::Str>)? Both this schema and `str_or_code` accept string, but
this schema will directly compile any input string while `str_or_code` will only
convert string to code if it is in the form of `sub { ... }`. In other words,
this schema will always produce coderef, while `str_or_code` can produce strings
also.

MARKDOWN

        prefilters => [ ['Code::eval'=>{}] ],

        examples => [
        ],
    },
];

1;
# ABSTRACT: Coderef from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::code_from_str - Coderef from string

=head1 VERSION

This document describes version 0.004 of Sah::Schema::code_from_str (from Perl distribution Sah-SchemaBundle-Code), released on 2024-06-10.

=for Pod::Coverage ^(.+)$

=head1 SAH SCHEMA DEFINITION

 ["code", { prefilters => [["Code::eval", {}]] }]

Base type: L<code|Data::Sah::Type::code>

Used prefilters: L<Code::eval|Data::Sah::Filter::perl::Code::eval>

=head1 SYNOPSIS

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("code_from_str*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("code_from_str", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("code_from_str", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]

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
     state $validator = gen_validator("code_from_str*");
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
             schema => ['code_from_str*'],
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

 % validate-with-sah '"code_from_str*"' '"data..."'

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
         sah2type('code_from_str*', name=>'CodeFromStr')
     );
 }

 use My::Types qw(CodeFromStr);
 CodeFromStr->assert_valid($data);

=head1 DESCRIPTION

This schema accepts coderef or string which will be eval'ed to coderef. Note
that this means allowing your user to provide arbitrary Perl code for you to
execute! Make sure first and foremost that security-wise this is acceptable in
your case.

By default C<eval()> is performed in the C<main> namespace and without stricture
or warnings. See the parameterized version L<Sah::PSchema::code_from_str> if
you want to customize the C<eval()>.

What's the difference between this schema and C<str_or_code> (from
L<Sah::Schemas::Str>)? Both this schema and C<str_or_code> accept string, but
this schema will directly compile any input string while C<str_or_code> will only
convert string to code if it is in the form of C<sub { ... }>. In other words,
this schema will always produce coderef, while C<str_or_code> can produce strings
also.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Code>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Code>.

=head1 SEE ALSO

L<Sah::PSchema::code_from_str> a parameterized version of this schema.

Tangentially related: L<Sah::Schema::re_from_str> which also involves compiling
arbitrary regex from string, albeit with some safety.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Code>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
