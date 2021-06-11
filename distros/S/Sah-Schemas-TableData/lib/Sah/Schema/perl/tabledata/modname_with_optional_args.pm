package Sah::Schema::perl::tabledata::modname_with_optional_args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-11'; # DATE
our $DIST = 'Sah-Schemas-TableData'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [str => {
    summary => 'Perl TableData::* module name without the prefix (e.g. Locale::US::State) with optional arguments (e.g. WordList=wordlist,EN::Enable)',
    description => <<'_',

Perl TableData::* module name without the prefix, with optional arguments which
will be used as instantiation arguments, just like the `-MMODULE=ARGS` shortcut
that `perl` provides. Examples:

    Locale::US::State
    WordList=wordlist,EN::Enable

See also: `perl::tabledata::modname`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\z',

    'x.perl.coerce_rules' => [
        ['From_str::normalize_perl_modname', {ns_prefix=>'TableData'}],
    ],

    # XXX also provide completion for arguments
    'x.completion' => ['perl_modname', {ns_prefix=>'TableData'}],


    examples => [
        {value=>'', valid=>0},
        {value=>'Foo/Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar=a,1,b,2', valid=>1, validated_value=>'Foo::Bar=a,1,b,2'},
        {value=>'Foo bar', valid=>0},
    ],

}, {}];

1;
# ABSTRACT: Perl TableData::* module name without the prefix (e.g. Locale::US::State) with optional arguments (e.g. WordList=wordlist,EN::Enable)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::tabledata::modname_with_optional_args - Perl TableData::* module name without the prefix (e.g. Locale::US::State) with optional arguments (e.g. WordList=wordlist,EN::Enable)

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::tabledata::modname_with_optional_args (from Perl distribution Sah-Schemas-TableData), released on 2021-06-11.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::tabledata::modname_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::tabledata::modname_with_optional_args*");
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
             schema => ['perl::tabledata::modname_with_optional_args*'],
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

Sample data:

 ""  # INVALID

 "Foo/Bar"  # valid, becomes "Foo::Bar"

 "Foo/Bar=a,1,b,2"  # valid, becomes "Foo::Bar=a,1,b,2"

 "Foo bar"  # INVALID

=head1 DESCRIPTION

Perl TableData::* module name without the prefix, with optional arguments which
will be used as instantiation arguments, just like the C<-MMODULE=ARGS> shortcut
that C<perl> provides. Examples:

 Locale::US::State
 WordList=wordlist,EN::Enable

See also: C<perl::tabledata::modname>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
