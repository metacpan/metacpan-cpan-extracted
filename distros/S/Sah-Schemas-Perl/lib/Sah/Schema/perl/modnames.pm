package Sah::Schema::perl::modnames;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.031'; # VERSION

our $schema = [array => {
    summary => 'Array of Perl module names, e.g. ["Foo::Bar", "Baz"]',
    description => <<'_',

Array of Perl module names, where each element is of `perl::modname` schema,
e.g. `Foo`, `Foo::Bar`.

Contains coercion rule that expands wildcard, so you can specify:

    Module::P*

and it will be expanded to e.g.:

    ["Module::Patch", "Module::Path", "Module::Pluggable"]

The wildcard syntax supports jokers (`?`, `*`, `**`), brackets (`[abc]`), and
braces (`{one,two}`).

_
    of => ["perl::modname", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        'From_str_or_array::expand_perl_modname_wildcard',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => 'perl_modname',

}, {}];

1;
# ABSTRACT: Array of Perl module names, e.g. ["Foo::Bar", "Baz"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modnames - Array of Perl module names, e.g. ["Foo::Bar", "Baz"]

=head1 VERSION

This document describes version 0.031 of Sah::Schema::perl::modnames (from Perl distribution Sah-Schemas-Perl), released on 2020-05-08.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modnames*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modnames*");
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
             schema => ['perl::modnames*'],
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

Array of Perl module names, where each element is of C<perl::modname> schema,
e.g. C<Foo>, C<Foo::Bar>.

Contains coercion rule that expands wildcard, so you can specify:

 Module::P*

and it will be expanded to e.g.:

 ["Module::Patch", "Module::Path", "Module::Pluggable"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
