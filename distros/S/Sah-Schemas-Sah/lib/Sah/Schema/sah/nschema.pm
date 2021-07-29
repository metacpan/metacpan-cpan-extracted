package Sah::Schema::sah::nschema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Sah-Schemas-Sah'; # DIST
our $VERSION = '0.9.50.0'; # VERSION

our $schema = ['array' => {
    summary => 'Normalized Sah schema',
    min_len => 2,
    max_len => 2,
    elems => [
        ['sah::type_name', {req=>1}],
        ['sah::clause_set', {}],
    ],
    # XXX: check that all schemas specified in clauses are also normalized, e.g.
    # 'of' and 'elems' clause in 'array', etc.

    examples => [
        {value=>'int', valid=>0, summary=>'Not array'},
        {value=>'int*', valid=>0, summary=>'Not array'},
        {value=>[], valid=>0, summary=>'Lacks type name and clause set'},
        {value=>['int'], valid=>0, summary=>'Lacks clause set'},
        {value=>['int', {}], valid=>1},
        {value=>['int', {min=>1, max=>1}], valid=>1},
        {value=>['int', {}, {}], valid=>0, summary=>'This schema no longer accepts extras'},
    ],

}];

1;
# ABSTRACT: Sah schema (normalized form)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::sah::nschema - Sah schema (normalized form)

=head1 VERSION

This document describes version 0.9.50.0 of Sah::Schema::sah::nschema (from Perl distribution Sah-Schemas-Sah), released on 2021-07-23.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("sah::nschema*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("sah::nschema*");
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
             schema => ['sah::nschema*'],
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

Sample data:

 "int"  # INVALID (Not array)

 "int*"  # INVALID (Not array)

 []  # INVALID (Lacks type name and clause set)

 ["int"]  # INVALID (Lacks clause set)

 ["int",{}]  # valid

 ["int",{max=>1,min=>1}]  # valid

 ["int",{},{}]  # INVALID (This schema no longer accepts extras)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
