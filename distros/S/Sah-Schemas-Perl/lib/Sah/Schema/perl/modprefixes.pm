package Sah::Schema::perl::modprefixes;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.034'; # VERSION

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

}, {}];

1;
# ABSTRACT: Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modprefixes - Perl module prefixes, e.g. ["", "Foo::", "Foo::Bar::"]

=head1 VERSION

This document describes version 0.034 of Sah::Schema::perl::modprefixes (from Perl distribution Sah-Schemas-Perl), released on 2020-06-19.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modprefixes*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modprefixes*");
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
