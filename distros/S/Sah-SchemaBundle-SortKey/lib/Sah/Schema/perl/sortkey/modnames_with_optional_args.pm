package Sah::Schema::perl::sortkey::modnames_with_optional_args;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'Sah-SchemaBundle-SortKey'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = [array => {
    summary => 'Array of Perl SortKey::* module names without the prefix, with optional args, e.g. ["Num::length", "Num::pattern_count=pattern,foo"]',
    description => <<'_',

Array of Perl SortKey::* module names without the prefix and with optional
args. Each element is of `perl::sortkey::modname` schema, e.g. `Num::length`,
`Num::pattern_count`.

Contains coercion rule that expands wildcard, so you can specify:

    Num::*

and it will be expanded to e.g.:

    ["Num::length", "Num::pattern_count"]

The wildcard syntax supports jokers (`?`, `*`, `**`), brackets (`[abc]`), and
braces (`{one,two}`). See <pm:Module::List::Wildcard> for more details.

_
    of => ["perl::sortkey::modname_with_optional_args", {req=>1}],

    'x.perl.coerce_rules' => [
        ['From_str_or_array::expand_perl_modname_wildcard', {ns_prefix=>'SortKey'}],
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => ['perl_sortkey_modname_with_optional_args'],

}];

1;
# ABSTRACT: Array of Perl SortKey::* module names without the prefix, with optional args, e.g. ["Num::length", "Num::pattern_count=pattern,foo"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::sortkey::modnames_with_optional_args - Array of Perl SortKey::* module names without the prefix, with optional args, e.g. ["Num::length", "Num::pattern_count=pattern,foo"]

=head1 VERSION

This document describes version 0.002 of Sah::Schema::perl::sortkey::modnames_with_optional_args (from Perl distribution Sah-SchemaBundle-SortKey), released on 2024-03-07.

=head1 SAH SCHEMA DEFINITION

 [
   "array",
   {
     "of" => ["perl::sortkey::modname_with_optional_args", { req => 1 }],
     "x.element_completion" => ["perl_sortkey_modname_with_optional_args"],
     "x.perl.coerce_rules" => [
       [
         "From_str_or_array::expand_perl_modname_wildcard",
         { ns_prefix => "SortKey" },
       ],
     ],
   },
 ]

Base type: L<array|Data::Sah::Type::array>

=head1 SYNOPSIS

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::sortkey::modnames_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::sortkey::modnames_with_optional_args", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("perl::sortkey::modnames_with_optional_args", {return_type=>'str_errmsg+val'});
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
     state $validator = gen_validator("perl::sortkey::modnames_with_optional_args*");
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
             schema => ['perl::sortkey::modnames_with_optional_args*'],
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

 % validate-with-sah '"perl::sortkey::modnames_with_optional_args*"' '"data..."'

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
         sah2type('perl::sortkey::modnames_with_optional_args*', name=>'PerlSortkeyModnamesWithOptionalArgs')
     );
 }

 use My::Types qw(PerlSortkeyModnamesWithOptionalArgs);
 PerlSortkeyModnamesWithOptionalArgs->assert_valid($data);

=head1 DESCRIPTION

Array of Perl SortKey::* module names without the prefix and with optional
args. Each element is of C<perl::sortkey::modname> schema, e.g. C<Num::length>,
C<Num::pattern_count>.

Contains coercion rule that expands wildcard, so you can specify:

 Num::*

and it will be expanded to e.g.:

 ["Num::length", "Num::pattern_count"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-SortKey>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-SortKey>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-SortKey>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
