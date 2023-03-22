package Sah::Schema::perl::wordlist::modname_with_optional_args;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Sah-Schemas-WordList'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'Perl WordList::* module name without the prefix (e.g. EN::Enable) with optional arguments (e.g. MetaSyntactic::Any=theme,dangdut)',
    description => <<'_',

Perl WordList::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the `-MMODULE=ARGS` shortcut that
`perl` provides. Examples:

    EN::Enable
    MetaSyntactic::Any=theme,dangdut

See also: `perl::wordlist::modname`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\z',

    'prefilters' => [
        'Perl::normalize_perl_modname',
    ],

    # XXX also provide completion for arguments
    'x.completion' => ['perl_wordlist_modname_with_optional_args'],

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo/Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar=a,1,b,2', valid=>1, validated_value=>'Foo::Bar=a,1,b,2'},
        {value=>'Foo bar', valid=>0},
    ],

}];

1;
# ABSTRACT: Perl WordList::* module name without the prefix (e.g. EN::Enable) with optional arguments (e.g. MetaSyntactic::Any=theme,dangdut)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::wordlist::modname_with_optional_args - Perl WordList::* module name without the prefix (e.g. EN::Enable) with optional arguments (e.g. MetaSyntactic::Any=theme,dangdut)

=head1 VERSION

This document describes version 0.005 of Sah::Schema::perl::wordlist::modname_with_optional_args (from Perl distribution Sah-Schemas-WordList), released on 2023-01-19.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "Foo/Bar"  # valid, becomes "Foo::Bar"

 "Foo/Bar=a,1,b,2"  # valid, becomes "Foo::Bar=a,1,b,2"

 "Foo bar"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::wordlist::modname_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::wordlist::modname_with_optional_args", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "Foo/Bar";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "Foo bar";
 my $errmsg = $validator->($data); # => "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\\z"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("perl::wordlist::modname_with_optional_args", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "Foo/Bar";
 my $res = $validator->($data); # => ["","Foo::Bar"]
 
 # a sample invalid data
 $data = "Foo bar";
 my $res = $validator->($data); # => ["Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\\z","Foo bar"]

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
     state $validator = gen_validator("perl::wordlist::modname_with_optional_args*");
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
             schema => ['perl::wordlist::modname_with_optional_args*'],
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
         sah2type('$sch_name*', name=>'PerlWordlistModnameWithOptionalArgs')
     );
 }

 use My::Types qw(PerlWordlistModnameWithOptionalArgs);
 PerlWordlistModnameWithOptionalArgs->assert_valid($data);

=head1 DESCRIPTION

Perl WordList::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the C<-MMODULE=ARGS> shortcut that
C<perl> provides. Examples:

 EN::Enable
 MetaSyntactic::Any=theme,dangdut

See also: C<perl::wordlist::modname>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-WordList>.

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

This software is copyright (c) 2023, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
