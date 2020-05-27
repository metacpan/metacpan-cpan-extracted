package Sah::Schema::perl::modname_with_optional_args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-21'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.032'; # VERSION

our $schema = [str => {
    summary => 'Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)',
    description => <<'_',

Perl module name with optional arguments which will be used as import arguments,
just like the `-MMODULE=ARGS` shortcut that `perl` provides. Examples:

    Foo
    Foo::Bar
    Foo::Bar=arg1,arg2

See also: `perl::modname`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:=.*)?\z',

    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_modname',
    ],

    # XXX also provide completion for arguments
    'x.completion' => 'perl_modname',

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo::Bar', valid=>1},
        {value=>'Foo::Bar=arg1,arg2', valid=>1},
        {value=>'Foo-Bar=arg1,arg2', valid=>1, validated_value=>'Foo::Bar=arg1,arg2'},
    ],

}, {}];

1;
# ABSTRACT: Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modname_with_optional_args - Perl module name (e.g. Foo::Bar) with optional arguments (e.g. Foo::Bar=arg1,arg2)

=head1 VERSION

This document describes version 0.032 of Sah::Schema::perl::modname_with_optional_args (from Perl distribution Sah-Schemas-Perl), released on 2020-05-21.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modname_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modname_with_optional_args*");
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
             schema => ['perl::modname_with_optional_args*'],
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

 "Foo::Bar"  # valid

 "Foo::Bar=arg1,arg2"  # valid

 "Foo-Bar=arg1,arg2"  # valid, becomes "Foo::Bar=arg1,arg2"

=head1 DESCRIPTION

Perl module name with optional arguments which will be used as import arguments,
just like the C<-MMODULE=ARGS> shortcut that C<perl> provides. Examples:

 Foo
 Foo::Bar
 Foo::Bar=arg1,arg2

See also: C<perl::modname>.

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
