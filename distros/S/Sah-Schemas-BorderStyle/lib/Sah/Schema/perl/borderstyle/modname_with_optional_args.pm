package Sah::Schema::perl::borderstyle::modname_with_optional_args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-02'; # DATE
our $DIST = 'Sah-Schemas-BorderStyle'; # DIST
our $VERSION = '0.002'; # VERSION

use Sah::PSchema 'get_schema';
use Sah::PSchema::perl::modname_with_optional_args; # not yet detected automatically by a dzil plugin

our $schema = get_schema(
    'perl::modname_with_optional_args',
    {ns_prefix=>'BorderStyle', complete_recurse=>1},
    {
        summary => 'Perl module in the BorderStyle::* namespace, without the namespace prefix, with optional args e.g. "Test::CustomChar=char,x"',
    }
);

1;
# ABSTRACT: Perl module in the BorderStyle::* namespace, without the namespace prefix, with optional args e.g. "Test::CustomChar=char,x"

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::borderstyle::modname_with_optional_args - Perl module in the BorderStyle::* namespace, without the namespace prefix, with optional args e.g. "Test::CustomChar=char,x"

=head1 VERSION

This document describes version 0.002 of Sah::Schema::perl::borderstyle::modname_with_optional_args (from Perl distribution Sah-Schemas-BorderStyle), released on 2021-02-02.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::borderstyle::modname_with_optional_args*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::borderstyle::modname_with_optional_args*");
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
             schema => ['perl::borderstyle::modname_with_optional_args*'],
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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-BorderStyle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-BorderStyle/issues>

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
