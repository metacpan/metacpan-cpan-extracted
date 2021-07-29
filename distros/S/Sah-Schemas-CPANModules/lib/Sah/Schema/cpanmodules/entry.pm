package Sah::Schema::cpanmodules::entry;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'Sah-Schemas-CPANModules'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = ['defhash', {
    summary => 'A single Acme::CPANModules list entry',
    'merge.add.keys' => {
        defhash_v => ['int', {req=>1, is=>1}],
        v => ['int', {req=>1, is=>1}],

        module => ['perl::modname', {req=>1}],
        rating => ['int', {min=>1, max=>10}],
        alternate_modules => ['perl::modnames', {req=>1}],
        related_modules => ['perl::modnames', {req=>1}],

        # this is actually not yet specified in spec
        script => ['str*', {req=>1}], # XXX program name
        scripts => ['array', {req=>1, of=>['str*', {req=>1}]}], # XXX program names

        # XXX features

        bench_code => ['code', {req=>1}],
        bench_code_template => ['str', {req=>1}],

        # XXX functions
    },
    'keys.restrict' => 1,
}];

1;
# ABSTRACT: A single Acme::CPANModules list entry

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cpanmodules::entry - A single Acme::CPANModules list entry

=head1 VERSION

This document describes version 0.002 of Sah::Schema::cpanmodules::entry (from Perl distribution Sah-Schemas-CPANModules), released on 2021-07-21.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("cpanmodules::entry*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("cpanmodules::entry*");
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
             schema => ['cpanmodules::entry*'],
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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPANModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPANModules>

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
