package Sah::Schema::perl::modprefixes;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-11'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.045'; # VERSION

our $schema = [array => {
    summary => 'Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"]',
    description => <<'_',

Array of Perl module prefixes, where each element is of `perl::modprefix`
schema, e.g. `Foo::`, `Foo::Bar::`.

Contains coercion rule that expands wildcard, so you can specify:

    Module::C*

and it will be expanded to e.g.:

    ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

The wildcard syntax supports jokers (`?`, '*`) and brackets (`[abc]`). See the
`unix` type of wildcard in <pm:Regexp::Wildcards>, which this coercion rule
uses.

_
    of => ["perl::modprefix", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        'From_str_or_array::expand_perl_modprefix_wildcard',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => 'perl_modprefix',

}];

1;
# ABSTRACT: Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modprefixes - Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"]

=head1 VERSION

This document describes version 0.045 of Sah::Schema::perl::modprefixes (from Perl distribution Sah-Schemas-Perl), released on 2022-09-11.

=head1 SYNOPSIS

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modprefixes*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::modprefixes", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("perl::modprefixes", {return_type=>'str_errmsg+val'});
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
     state $validator = gen_validator("perl::modprefixes*");
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
             schema => ['perl::modprefixes*'],
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

=head1 DESCRIPTION

Array of Perl module prefixes, where each element is of C<perl::modprefix>
schema, e.g. C<Foo::>, C<Foo::Bar::>.

Contains coercion rule that expands wildcard, so you can specify:

 Module::C*

and it will be expanded to e.g.:

 ["Module::CPANTS::", "Module::CPANfile::", "Module::CheckVersion::", "Module::CoreList::"]

The wildcard syntax supports jokers (C<?>, '*C<) and brackets (>[abc]C<). See the
>unix` type of wildcard in L<Regexp::Wildcards>, which this coercion rule
uses.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
