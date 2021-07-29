package Sah::Schema::bencher::dataset;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Sah-Schemas-Bencher'; # DIST
our $VERSION = '1.054.1'; # VERSION

our $schema = ['defhash', {
    summary => 'A benchmark dataset',
    'merge.add.keys' => {
        defhash_v => ['int', {req=>1, is=>1}],
        v => ['int', {req=>1, is=>1}],

        args => ['hash', {req=>1}],
        argv => ['aos', {req=>1}],

        result => ['any', {}],

        include_by_default => ['bool', {req=>1, default=>1}],
        include_participant_tags => ['aos', {req=>1}],
        exclude_participant_tags => ['aos', {req=>1}],
    },
    'keys.restrict' => 1,

    choose_one => ['args', 'argv'],

}];

1;
# ABSTRACT: A benchmark dataset

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::bencher::dataset - A benchmark dataset

=head1 VERSION

This document describes version 1.054.1 of Sah::Schema::bencher::dataset (from Perl distribution Sah-Schemas-Bencher), released on 2021-07-23.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("bencher::dataset*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("bencher::dataset*");
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
             schema => ['bencher::dataset*'],
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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Bencher>

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
