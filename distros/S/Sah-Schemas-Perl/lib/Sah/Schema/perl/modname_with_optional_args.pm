package Sah::Schema::perl::modname_with_optional_args;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.048'; # VERSION

use Regexp::Pattern::Perl::Module ();

our @examples_str = (
    {value=>'', valid=>0},
    {value=>'Foo::Bar', valid=>1},
    {value=>'Foo::Bar=arg1,arg2', valid=>1},
    {value=>'Foo-Bar=arg1,arg2', valid=>1, validated_value=>'Foo::Bar=arg1,arg2'},
    #{value=>'Foo::Bar=arg1,arg2 foo', valid=>0}, # XXX why fail?
);

our @examples_array = (
    {value=>[], valid=>0, summary=>"No module name"},
    {value=>["Foo"], valid=>1},
    {value=>["Foo Bar"], valid=>0, summary=>"Invalid module name"},
    {value=>["Foo","arg"], valid=>0, summary=>"Args must be arrayref or hashref"},
    {value=>["Foo",{arg1=>1, arg2=>2}], valid=>1},
    {value=>["Foo",["arg1","arg2"]], valid=>1},
    {value=>["Foo",["arg1","arg2"],{}], valid=>0, summary=>"Too many elements"},
);

our $schema_str = [str => {
    summary => 'Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)',
    description => <<'_',

Perl module name with optional arguments which will be used as import arguments,
just like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:

    Foo
    Foo::Bar
    Foo::Bar=arg1,arg2

See also: `perl::modname`.

_
    match => '\\A(?:' . $Regexp::Pattern::Perl::Module::RE{perl_modname_with_optional_args}{pat} . ')\\z',

    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_modname',
    ],

    # XXX also provide completion for arguments
    'x.completion' => 'perl_modname',

    examples => \@examples_str,
}];

our $schema_array = [array_from_json => {
    summary => 'A 1- or 2-element array containing Perl module name (e.g. ["Foo::Bar"]) with optional arguments (e.g. ["Foo::Bar", ["arg1","arg2"]])',
    description => <<'_',

These are valid values for this schema:

    ["Foo"]                                      # just the module name
    ["Foo::Bar", ["arg1","arg2"]]                # with import arguments (array)
    ["Foo::Bar", {"arg1"=>"val","arg2"=>"val"}]  # with import arguments (hash)

_
    min_len => 1,
    max_len => 2,
    elems => [
        ["perl::modname",{req=>1}],
        ["any", {
            req=>1,
            of=>[
                ["array",{req=>1}],
                ["hash",{req=>1}]],
        }],
    ],
    examples => \@examples_array,
}];

our $schema = [any => {
    summary => 'Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)',
    description => <<'_',

Perl module name with optional arguments which will be used as import arguments,
just like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:

    Foo
    Foo::Bar
    Foo::Bar=arg1,arg2

See also: `perl::modname`.
A two-element array from (coercible from JSON string) is also allowed:

    ["Foo::Bar", \@args]

_
    of => [
        $schema_array,
        $schema_str,
    ],

    # XXX also provide completion for arguments
    'x.completion' => 'perl_modname',

    examples => [
        @examples_str,
        @examples_array,
    ],
}];

1;
# ABSTRACT: Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modname_with_optional_args - Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)

=head1 VERSION

This document describes version 0.048 of Sah::Schema::perl::modname_with_optional_args (from Perl distribution Sah-Schemas-Perl), released on 2023-01-19.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "Foo::Bar"  # valid

 "Foo::Bar=arg1,arg2"  # valid

 "Foo-Bar=arg1,arg2"  # valid, becomes "Foo::Bar=arg1,arg2"

 []  # INVALID (No module name)

 ["Foo"]  # valid

 ["Foo Bar"]  # INVALID (Invalid module name)

 ["Foo","arg"]  # INVALID (Args must be arrayref or hashref)

 ["Foo",{arg1=>1,arg2=>2}]  # valid

 ["Foo",["arg1","arg2"]]  # valid

 ["Foo",["arg1","arg2"],{}]  # INVALID (Too many elements)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modname_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::modname_with_optional_args", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "Foo::Bar";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = ["Foo",["arg1","arg2"],{}];
 my $errmsg = $validator->($data); # => "String is not a valid JSON: malformed JSON string, neither tag, array, object, number, string or atom, at character offset 0 (before \"Foo::Bar\") at (eval 3149) line 29.\n"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("perl::modname_with_optional_args", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "Foo::Bar";
 my $res = $validator->($data); # => ["","Foo::Bar"]
 
 # a sample invalid data
 $data = ["Foo",["arg1","arg2"],{}];
 my $res = $validator->($data); # => ["String is not a valid JSON: malformed JSON string, neither tag, array, object, number, string or atom, at character offset 0 (before \"Foo::Bar\") at (eval 3169) line 29.\n",["Foo",["arg1","arg2"],{}]]

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
     state $validator = gen_validator("perl::modname_with_optional_args*");
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
             schema => ['perl::modname_with_optional_args*'],
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
         sah2type('$sch_name*', name=>'PerlModnameWithOptionalArgs')
     );
 }

 use My::Types qw(PerlModnameWithOptionalArgs);
 PerlModnameWithOptionalArgs->assert_valid($data);

=head1 DESCRIPTION

Perl module name with optional arguments which will be used as import arguments,
just like the C<-MMODULE=ARGS> shortcut that C<perl> provides. Examples:

 Foo
 Foo::Bar
 Foo::Bar=arg1,arg2

See also: C<perl::modname>.
A two-element array from (coercible from JSON string) is also allowed:

 ["Foo::Bar", \@args]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
