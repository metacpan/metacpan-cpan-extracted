package Sah::Schema::regexppattern::name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-RegexpPattern'; # DIST
our $VERSION = '0.002'; # VERSION

our $schema = ['str', {
    summary => "Name of pattern, with module prefix but without the 'Regexp::Pattern'",
    match => qr!\A\w+((::|/|\.)\w+)+\z!,
    'x.completion' => ['regexppattern_name'],
    'x.perl.coerce_rules' => ['From_str::normalize_perl_modname'],

    examples => [
        {value=>'', valid=>0},
        {value=>'Float', valid=>0},
        {value=>'Float::float', valid=>1},
        {value=>'Float/float', valid=>1, validated_value=>'Float::float'},
        {value=>'foo bar', valid=>0},
    ],

}, {}];

1;
# ABSTRACT: Name of pattern, with module prefix but without the 'Regexp::Pattern'

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::regexppattern::name - Name of pattern, with module prefix but without the 'Regexp::Pattern'

=head1 VERSION

This document describes version 0.002 of Sah::Schema::regexppattern::name (from Perl distribution Sah-Schemas-RegexpPattern), released on 2020-05-27.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("regexppattern::name*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("regexppattern::name*");
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
             schema => ['regexppattern::name*'],
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

 "Float"  # INVALID

 "Float::float"  # valid

 "Float/float"  # valid, becomes "Float::float"

 "foo bar"  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-RegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-RegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-RegexpPattern>

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
