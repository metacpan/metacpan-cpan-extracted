package Sah::Schema::perl::identifier::unqualified_unicode;

use strict;
use utf8;
use warnings;
no warnings 'experimental::regex_sets';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Sah-SchemaBundle-Perl'; # DIST
our $VERSION = '0.050'; # VERSION

our $schema = [str => {
    summary => 'Unqualified identifier in Perl, with "use utf8" in effect',
    description => <<'_',

_
    match => qr/\A
                (?[ ( \p{Word} & \p{XID_Start} ) + [_] ])
                (?[ ( \p{Word} & \p{XID_Continue} ) ])*
                \z/x,

    examples => [
        {value=>'', valid=>0, summary=>'Empty'},

        # ascii
        {value=>'foo', valid=>1},
        {value=>'_foo', valid=>1},
        {value=>'0foo', valid=>0, summary=>'Cannot start with a digit'},
        {value=>'foo0', valid=>1},
        {value=>'foo-bar', valid=>0, summary=>'Invalid character (dash)'},
        {value=>'foo::bar', valid=>0, summary=>'Qualified name not accepted'},
        {value=>'$foo', valid=>0, summary=>'Sigil not accepted'},

        # unicode
        {value=>'bébé', valid=>1},
    ],

}];

1;
# ABSTRACT: Unqualified identifier in Perl, with "use utf8" in effect

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::identifier::unqualified_unicode - Unqualified identifier in Perl, with "use utf8" in effect

=head1 VERSION

This document describes version 0.050 of Sah::Schema::perl::identifier::unqualified_unicode (from Perl distribution Sah-SchemaBundle-Perl), released on 2024-02-16.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     summary => "Unqualified identifier in Perl, with \"use utf8\" in effect",
     match   => qr/\A
                                (?[ ( \p{Word} & \p{XID_Start} ) + [_] ])
                                (?[ ( \p{Word} & \p{XID_Continue} ) ])*
                                \z/x,
   },
 ]

Base type: L<str|Data::Sah::Type::str>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty)

 "foo"  # valid

 "_foo"  # valid

 "0foo"  # INVALID (Cannot start with a digit)

 "foo0"  # valid

 "foo-bar"  # INVALID (Invalid character (dash))

 "foo::bar"  # INVALID (Qualified name not accepted)

 "\$foo"  # INVALID (Sigil not accepted)

 "b\xE9b\xE9"  # valid

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::identifier::unqualified_unicode*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::identifier::unqualified_unicode", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "_foo";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "foo::bar";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A\n                (?[ ( \\p{Word} & \\p{XID_Start} ) + [_] ])\n                (?[ ( \\p{Word} & \\p{XID_Continue} ) ])*\n                \\z)x"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("perl::identifier::unqualified_unicode", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "_foo";
 my $res = $validator->($data); # => ["","_foo"]
 
 # a sample invalid data
 $data = "foo::bar";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A\n                (?[ ( \\p{Word} & \\p{XID_Start} ) + [_] ])\n                (?[ ( \\p{Word} & \\p{XID_Continue} ) ])*\n                \\z)x","foo::bar"]

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
     state $validator = gen_validator("perl::identifier::unqualified_unicode*");
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
             schema => ['perl::identifier::unqualified_unicode*'],
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

 % validate-with-sah '"perl::identifier::unqualified_unicode*"' '"data..."'

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
         sah2type('perl::identifier::unqualified_unicode*', name=>'PerlIdentifierUnqualifiedUnicode')
     );
 }

 use My::Types qw(PerlIdentifierUnqualifiedUnicode);
 PerlIdentifierUnqualifiedUnicode->assert_valid($data);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Perl>.

=head1 SEE ALSO

L<perldata>

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
