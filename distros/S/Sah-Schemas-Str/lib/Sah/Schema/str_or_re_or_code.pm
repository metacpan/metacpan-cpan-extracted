package Sah::Schema::str_or_re_or_code;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-23'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.016'; # VERSION

our $schema = [any => {
    summary => 'String, or regex (if string is of the form `/.../`), or coderef (if string is in the form of `sub { ... }`)',
    description => <<'_',

Either string, Regexp object, or coderef is accepted.

If string is of the form of `/.../` or `qr(...)`, then it will be compiled into
a Regexp object. If the regex pattern inside `/.../` or `qr(...)` is invalid,
value will be rejected. Currently, unlike in normal Perl, for the `qr(...)`
form, only parentheses `(` and `)` are allowed as the delimiter. Currently
modifiers `i`, `m`, and `s` after the second `/` are allowed.

If string matches the regex `qr/\Asub\s*\{.*\}\z/s`, then it will be eval'ed
into a coderef. If the code fails to compile, the value will be rejected. Note
that this means you accept arbitrary code from the user to execute! Please make
sure first and foremost that this is acceptable in your case. Currently string
is eval'ed in the `main` package, without `use strict` or `use warnings`.

This schema is handy if you want to accept string or regex or coderef from the
command-line.

_
    of => [
        ['str'],
        ['re'],
        ['code'],
    ],

    prefilters => [
        'Str::maybe_convert_to_re',
        'Str::maybe_eval',
    ],

    examples => [
        {value=>'', valid=>1},
        {value=>'a', valid=>1},
        {value=>{}, valid=>0, summary=>'Not a string'},

        # re
        {value=>'//', valid=>1, validated_value=>qr//},
        {value=>'/foo', valid=>1, summary=>'Becomes a string'},
        {value=>'qr(foo', valid=>1, summary=>'Becomes a string'},
        {value=>'qr(foo(', valid=>1, summary=>'Becomes a string'},
        {value=>'qr/foo/', valid=>1, summary=>'Becomes a string'},

        {value=>'/foo.*/', valid=>1, validated_value=>qr/foo.*/},
        {value=>'qr(foo.*)', valid=>1, validated_value=>qr/foo.*/},
        {value=>'/foo/is', valid=>1, validated_value=>qr/foo/is},
        {value=>'qr(foo)is', valid=>1, validated_value=>qr/foo/is},

        {value=>'/foo[/', valid=>0, summary=>'Invalid regex'},

        # code
        {value=>'sub {}', valid=>1, code_validate=>sub { ref($_[0]) eq 'CODE' & !defined($_[0]->()) }},
        {value=>'sub{"foo"}', valid=>1, code_validate=>sub { ref($_[0]) eq 'CODE' && $_[0]->() eq 'foo' }},
        {value=>'sub {', valid=>1, summary=>'Becomes a string'},

        {value=>'sub {1=2}', valid=>0, summary=>'Code does not compile'},
    ],

}];

1;
# ABSTRACT: String, or regex (if string is of the form `/.../`), or coderef (if string is in the form of `sub { ... }`)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::str_or_re_or_code - String, or regex (if string is of the form `/.../`), or coderef (if string is in the form of `sub { ... }`)

=head1 VERSION

This document describes version 0.016 of Sah::Schema::str_or_re_or_code (from Perl distribution Sah-Schemas-Str), released on 2023-10-23.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid

 "a"  # valid

 {}  # INVALID (Not a string)

 "//"  # valid, becomes qr()

 "/foo"  # valid (Becomes a string)

 "qr(foo"  # valid (Becomes a string)

 "qr(foo("  # valid (Becomes a string)

 "qr/foo/"  # valid (Becomes a string)

 "/foo.*/"  # valid, becomes qr(foo.*)

 "qr(foo.*)"  # valid, becomes qr(foo.*)

 "/foo/is"  # valid, becomes qr(foo)si

 "qr(foo)is"  # valid, becomes qr(foo)si

 "/foo[/"  # INVALID (Invalid regex)

 "sub {}"  # valid

 "sub{\"foo\"}"  # valid

 "sub {"  # valid (Becomes a string)

 "sub {1=2}"  # INVALID (Code does not compile)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("str_or_re_or_code*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("str_or_re_or_code", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "sub{\"foo\"}";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = {};
 my $errmsg = $validator->($data); # => "Not of type text"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("str_or_re_or_code", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "sub{\"foo\"}";
 my $res = $validator->($data); # => ["",sub{BEGIN {${^WARNING_BITS} = "\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x51\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55\x55"}use strict;no feature;use feature ':5.10';'foo'}]
 
 # a sample invalid data
 $data = {};
 my $res = $validator->($data); # => ["Not of type text",{}]

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
     state $validator = gen_validator("str_or_re_or_code*");
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
             schema => ['str_or_re_or_code*'],
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

 % validate-with-sah '"str_or_re_or_code*"' '"data..."'

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
         sah2type('str_or_re_or_code*', name=>'StrOrReOrCode')
     );
 }

 use My::Types qw(StrOrReOrCode);
 StrOrReOrCode->assert_valid($data);

=head1 DESCRIPTION

Either string, Regexp object, or coderef is accepted.

If string is of the form of C</.../> or C<qr(...)>, then it will be compiled into
a Regexp object. If the regex pattern inside C</.../> or C<qr(...)> is invalid,
value will be rejected. Currently, unlike in normal Perl, for the C<qr(...)>
form, only parentheses C<(> and C<)> are allowed as the delimiter. Currently
modifiers C<i>, C<m>, and C<s> after the second C</> are allowed.

If string matches the regex C<qr/\Asub\s*\{.*\}\z/s>, then it will be eval'ed
into a coderef. If the code fails to compile, the value will be rejected. Note
that this means you accept arbitrary code from the user to execute! Please make
sure first and foremost that this is acceptable in your case. Currently string
is eval'ed in the C<main> package, without C<use strict> or C<use warnings>.

This schema is handy if you want to accept string or regex or coderef from the
command-line.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah::Schema::str_or_re>

L<Sah::Schema::str_or_code>

L<Sah::PSchema::re_from_str>

L<Sah::PSchema::code_from_str>

L<Sah::Schema::re_from_str>

L<Sah::Schema::code_from_str>

L<Regexp::From::String>

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

This software is copyright (c) 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
