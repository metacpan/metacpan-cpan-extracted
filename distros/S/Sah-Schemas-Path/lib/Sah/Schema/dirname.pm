package Sah::Schema::dirname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.016'; # VERSION

our $schema = [str => {
    summary => 'Filesystem directory name',
    description => <<'_',

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. `~/foo` into `/home/someuser/foo`. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like `dirname::unix`, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like `foo//bar` into `foo/bar`.

What's the difference between this schema and `filename`? The default completion
rule. This schema's completion by default only includes directories.

_

    min_len => 1,

    'x.completion' => ['dirname'],
    'prefilters' => [
        'Path::expand_tilde_when_on_unix',
        'Path::strip_slashes_when_on_unix',
    ],

    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>1},
        {value=>'foo/bar', valid=>1},
    ],

}, {}];

1;
# ABSTRACT: Filesystem directory name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dirname - Filesystem directory name

=head1 VERSION

This document describes version 0.016 of Sah::Schema::dirname (from Perl distribution Sah-Schemas-Path), released on 2021-07-17.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("dirname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("dirname*");
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
             schema => ['dirname*'],
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

 "foo"  # valid

 "foo/bar"  # valid

=head1 DESCRIPTION

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo> into C</home/someuser/foo>. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<dirname::unix>, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<filename>? The default completion
rule. This schema's completion by default only includes directories.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
