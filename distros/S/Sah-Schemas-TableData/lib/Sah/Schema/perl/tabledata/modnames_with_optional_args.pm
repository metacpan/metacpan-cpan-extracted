package Sah::Schema::perl::tabledata::modnames_with_optional_args;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-29'; # DATE
our $DIST = 'Sah-Schemas-TableData'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = [array => {
    summary => 'Array of Perl TableData::* module names without the prefix, with optional args, e.g. ["Locale::US::State", "WordList=wordlist,EN::Enable"]',
    description => <<'_',

Array of Perl TableData::* module names without the prefix and optional args.
Each element is of `perl::tabledata::modname` schema, e.g. `Locale::US::State`,
`WordList=wordlist,EN::Enable`.

Contains coercion rule that expands wildcard, so you can specify:

    Locale::US::*

and it will be expanded to e.g.:

    ["Locale::US::State", "Locale::US::City"]

The wildcard syntax supports jokers (`?`, `*`, `**`), brackets (`[abc]`), and
braces (`{one,two}`). See <pm:Module::List::Wildcard> for more details.

_
    of => ["perl::tabledata::modname_with_optional_args", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        ['From_str_or_array::expand_perl_modname_wildcard', {ns_prefix=>'TableData'}],
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => ['perl_modname', {ns_prefix=>'TableData'}],

}, {}];

1;
# ABSTRACT: Array of Perl TableData::* module names without the prefix, with optional args, e.g. ["Locale::US::State", "WordList=wordlist,EN::Enable"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::tabledata::modnames_with_optional_args - Array of Perl TableData::* module names without the prefix, with optional args, e.g. ["Locale::US::State", "WordList=wordlist,EN::Enable"]

=head1 VERSION

This document describes version 0.002 of Sah::Schema::perl::tabledata::modnames_with_optional_args (from Perl distribution Sah-Schemas-TableData), released on 2021-09-29.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::tabledata::modnames_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::tabledata::modnames_with_optional_args*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['perl::tabledata::modnames_with_optional_args*'],
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
 package main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head1 DESCRIPTION

Array of Perl TableData::* module names without the prefix and optional args.
Each element is of C<perl::tabledata::modname> schema, e.g. C<Locale::US::State>,
C<WordList=wordlist,EN::Enable>.

Contains coercion rule that expands wildcard, so you can specify:

 Locale::US::*

and it will be expanded to e.g.:

 ["Locale::US::State", "Locale::US::City"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-TableData>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
