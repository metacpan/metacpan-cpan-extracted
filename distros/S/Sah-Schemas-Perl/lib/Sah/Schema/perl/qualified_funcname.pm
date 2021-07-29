package Sah::Schema::perl::qualified_funcname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.038'; # VERSION

our $schema = [str => {
    summary => 'Perl function name qualified with a package name, e.g. Foo::subname',
    description => <<'_',

Currently function name is restricted to this regex:

    \A[A-Za-z_][A-Za-z_0-9]*\z

and package name is restricted to this regex:

    [A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*

This schema includes syntax validity check only; it does not check whether the
function actually exists.

_
    match => '\A(?:[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*::)[A-Za-z_]([A-Za-z_0-9]+)*\z',

    # TODO: provide convenience by providing list of core function names etc
    #'x.completion' => 'perl_funcname',

}];

1;
# ABSTRACT: Perl function name qualified with a package name, e.g. Foo::subname

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::qualified_funcname - Perl function name qualified with a package name, e.g. Foo::subname

=head1 VERSION

This document describes version 0.038 of Sah::Schema::perl::qualified_funcname (from Perl distribution Sah-Schemas-Perl), released on 2021-07-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::qualified_funcname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::qualified_funcname*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

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
             schema => ['perl::qualified_funcname*'],
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
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head1 DESCRIPTION

Currently function name is restricted to this regex:

 \A[A-Za-z_][A-Za-z_0-9]*\z

and package name is restricted to this regex:

 [A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*

This schema includes syntax validity check only; it does not check whether the
function actually exists.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::perl::funcname>

L<Sah::Schema::perl::unqualified_funcname>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
