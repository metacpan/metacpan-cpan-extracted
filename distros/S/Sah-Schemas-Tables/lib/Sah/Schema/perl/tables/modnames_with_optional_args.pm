package Sah::Schema::perl::tables::modnames_with_optional_args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'Sah-Schemas-Tables'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [array => {
    summary => 'Array of Perl Tables::* module names without the prefix, with optional args, e.g. ["Sample::DeNiro", "Test::Dynamic=random,1"]',
    description => <<'_',

Array of Perl Tables::* module names, where each element is of
`perl::tables::modname_with_optional_args` schema, e.g. `Sample::DeNiro`,
`Test::Dynamic=random,1`.

Contains coercion rule that expands wildcard, so you can specify:

    Sample::*

and it will be expanded to e.g.:

    ["Sample::DeNiro", "Sample::CelineDion"]

The wildcard syntax supports jokers (`?`, `*`, `**`), brackets (`[abc]`), and
braces (`{one,two}`). See <pm:Module::List::Wildcard> for more details.

_
    of => ["perl::tables::modname_with_optional_args", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        ['From_str_or_array::expand_perl_modname_wildcard', {ns_prefix=>'Tables'}],
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => ['perl_modname', {ns_prefix=>'Tables'}],

}, {}];

1;
# ABSTRACT: Array of Perl Tables::* module names without the prefix, with optional args, e.g. ["Sample::DeNiro", "Test::Dynamic=random,1"]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::tables::modnames_with_optional_args - Array of Perl Tables::* module names without the prefix, with optional args, e.g. ["Sample::DeNiro", "Test::Dynamic=random,1"]

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::tables::modnames_with_optional_args (from Perl distribution Sah-Schemas-Tables), released on 2020-11-10.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::tables::modnames_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::tables::modnames_with_optional_args*");
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
             schema => ['perl::tables::modnames_with_optional_args*'],
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

Array of Perl Tables::* module names, where each element is of
C<perl::tables::modname_with_optional_args> schema, e.g. C<Sample::DeNiro>,
C<Test::Dynamic=random,1>.

Contains coercion rule that expands wildcard, so you can specify:

 Sample::*

and it will be expanded to e.g.:

 ["Sample::DeNiro", "Sample::CelineDion"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Tables>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Tables>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Tables>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
