package Sah::Schema::perl::cellfunc::modname;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-10'; # DATE
our $DIST = 'Sah-SchemaBundle-CellFunc'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = ['str' => {
    summary => 'Perl CellFunc::* module name without the prefix, e.g. File/stat_row',
    description => <<'MARKDOWN',

Contains coercion rule so you can also input `Foo-Bar`, `Foo/Bar`, `Foo/Bar.pm`
or even 'Foo.Bar' and it will be normalized into `Foo::Bar`.

MARKDOWN
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z',

    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_modname',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.completion' => ['perl_modname', {ns_prefix=>'CellFunc'}],

    examples => [
        {value=>'', valid=>0},
        {value=>'File/stat_row', valid=>1, validated_value=>'File::stat_row'},
        {value=>'pattern count', valid=>0},
    ],

}];

1;
# ABSTRACT: Perl CellFunc::* module name without the prefix, e.g. File/stat_row

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::cellfunc::modname - Perl CellFunc::* module name without the prefix, e.g. File/stat_row

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::cellfunc::modname (from Perl distribution Sah-SchemaBundle-CellFunc), released on 2024-12-10.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     "match" => "\\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z",
     "x.completion" => ["perl_modname", { ns_prefix => "CellFunc" }],
     "x.perl.coerce_rules" => ["From_str::normalize_perl_modname"],
   },
 ]

Base type: L<str|Data::Sah::Type::str>

Used completion: L<perl_modname|Perinci::Sub::XCompletion::perl_modname>, L<HASH(0x55df1ccec5a8)|Perinci::Sub::XCompletion::HASH(0x55df1ccec5a8)>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "File/stat_row"  # valid, becomes "File::stat_row"

 "pattern count"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::cellfunc::modname*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::cellfunc::modname", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "File/stat_row";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "pattern count";
 my $errmsg = $validator->($data); # => "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("perl::cellfunc::modname", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "File/stat_row";
 my $res = $validator->($data); # => ["","File::stat_row"]
 
 # a sample invalid data
 $data = "pattern count";
 my $res = $validator->($data); # => ["Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z","pattern count"]

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
     state $validator = gen_validator("perl::cellfunc::modname*");
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
             schema => ['perl::cellfunc::modname*'],
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

 % validate-with-sah '"perl::cellfunc::modname*"' '"data..."'

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
         sah2type('perl::cellfunc::modname*', name=>'PerlCellfuncModname')
     );
 }

 use My::Types qw(PerlCellfuncModname);
 PerlCellfuncModname->assert_valid($data);

=head1 DESCRIPTION

Contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-CellFunc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-CellFunc>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-CellFunc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
