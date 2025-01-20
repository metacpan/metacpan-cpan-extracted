package Sah::Schema::unix::groupname;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-15'; # DATE
our $DIST = 'Sah-SchemaBundle-Unix'; # DIST
our $VERSION = '0.022'; # VERSION

our $schema = [str => {
    summary => 'Unix group name',
    description => <<'MARKDOWN',

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the group name exists (has record
in the user database e.g. `/etc/group`). To do that, use the
`unix::groupname::exists` schema.

MARKDOWN
    prefilters => ['Unix::convert_gid_to_unix_group'],
    'x.completion' => ['unix_group_or_gid'],
    min_len => 1,
    max_len => 32,
    match => qr/(?=\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\z)(?=.*[A-Za-z._-])/,

    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>1},
        {value=>'-andy', valid=>0},
        {value=>'1234', valid=>0},
        {value=>'andy2', valid=>1},
        {value=>'an dy', valid=>0},
        {value=>'an.dy', valid=>1},
        {value=>'a' x 33, valid=>0, summary=>'Too long'},
    ],

}];

1;
# ABSTRACT: Unix group name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::groupname - Unix group name

=head1 VERSION

This document describes version 0.022 of Sah::Schema::unix::groupname (from Perl distribution Sah-SchemaBundle-Unix), released on 2024-11-15.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     "prefilters"   => ["Unix::convert_gid_to_unix_group"],
     "max_len"      => 32,
     "min_len"      => 1,
     "match"        => qr/(?=\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\z)(?=.*[A-Za-z._-])/,
     "x.completion" => ["unix_group_or_gid"],
   },
 ]

Base type: L<str|Data::Sah::Type::str>

Used prefilters: L<Unix::convert_gid_to_unix_group|Data::Sah::Filter::perl::Unix::convert_gid_to_unix_group>

Used completion: L<unix_group_or_gid|Perinci::Sub::XCompletion::unix_group_or_gid>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "foo"  # valid

 "-andy"  # INVALID

 1234  # INVALID

 "andy2"  # valid

 "an dy"  # INVALID

 "an.dy"  # valid

 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  # INVALID (Too long)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("unix::groupname*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("unix::groupname", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "an.dy";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = 1234;
 my $errmsg = $validator->($data); # => "GID 1234 has no associated group name"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("unix::groupname", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "an.dy";
 my $res = $validator->($data); # => ["","an.dy"]
 
 # a sample invalid data
 $data = 1234;
 my $res = $validator->($data); # => ["GID 1234 has no associated group name",1234]

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
     state $validator = gen_validator("unix::groupname*");
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
             schema => ['unix::groupname*'],
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

 % validate-with-sah '"unix::groupname*"' '"data..."'

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
         sah2type('unix::groupname*', name=>'UnixGroupname')
     );
 }

 use My::Types qw(UnixGroupname);
 UnixGroupname->assert_valid($data);

=head1 DESCRIPTION

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the group name exists (has record
in the user database e.g. C</etc/group>). To do that, use the
C<unix::groupname::exists> schema.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Unix>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
