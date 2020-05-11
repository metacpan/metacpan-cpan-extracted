package Sah::Schema::hohoms;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-08'; # DATE
our $DIST = 'Sah-Schemas-Collection'; # DIST
our $VERSION = '0.008'; # VERSION

our $schema = [hash => {
    summary => 'Hash of (defined-)hash-of-maybe-strings',
    description => <<'_',

_
    of => ['homs', {req=>1}, {}],
    examples => [
        {value=>'a', valid=>0},
        {value=>[], valid=>0},
        {value=>{}, valid=>1},
        {value=>{k=>undef}, valid=>0},
        {value=>{k=>'a'}, valid=>0},
        {value=>{k=>[]}, valid=>0},
        {value=>{k=>{}}, valid=>1},
        {value=>{k=>{}, k2=>{k=>'a'}}, valid=>1},
        {value=>{k=>{}, k2=>{k=>[]}}, valid=>0},
        {value=>{k=>{}, k2=>{k=>{}}}, valid=>0},
        {value=>{k=>{}, k2=>{k=>undef}}, valid=>1},
    ],
}, {}];

1;
# ABSTRACT: Hash of (defined-)hash-of-maybe-strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hohoms - Hash of (defined-)hash-of-maybe-strings

=head1 VERSION

This document describes version 0.008 of Sah::Schema::hohoms (from Perl distribution Sah-Schemas-Collection), released on 2020-05-08.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("hohoms*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("hohoms*");
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
             schema => ['hohoms*'],
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

 "a"  # INVALID

 []  # INVALID

 {}  # valid

 {k=>undef}  # INVALID

 {k=>"a"}  # INVALID

 {k=>[]}  # INVALID

 {k=>{}}  # valid

 {k=>{},k2=>{k=>"a"}}  # valid

 {k=>{},k2=>{k=>[]}}  # INVALID

 {k=>{},k2=>{k=>{}}}  # INVALID

 {k=>{},k2=>{k=>undef}}  # valid

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::hohos> (hash of (defined-)hashes-of-(defined-)-strings).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
