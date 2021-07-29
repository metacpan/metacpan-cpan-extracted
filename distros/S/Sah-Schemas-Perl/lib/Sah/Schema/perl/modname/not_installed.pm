package Sah::Schema::perl::modname::not_installed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.038'; # VERSION

our $schema = ['perl::modname' => {
    summary => 'Name of a Perl module that is not installed locally',
    description => <<'_',

This schema is based on the `perl::modname` schema with an additional check that
the perl module is not installed locally. Checking is done using
<pm:Module::Installed::Tiny>. This check fetches the source code of the module
from filesystem or %INC hooks, but does not actually load/execute the code.

_

    'prefilters' => [
        'Perl::check_module_not_installed',
    ],

    examples => [
    ],

}];

1;
# ABSTRACT: Name of a Perl module that is not installed locally

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modname::not_installed - Name of a Perl module that is not installed locally

=head1 VERSION

This document describes version 0.038 of Sah::Schema::perl::modname::not_installed (from Perl distribution Sah-Schemas-Perl), released on 2021-07-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modname::not_installed*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modname::not_installed*");
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
             schema => ['perl::modname::not_installed*'],
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

This schema is based on the C<perl::modname> schema with an additional check that
the perl module is not installed locally. Checking is done using
L<Module::Installed::Tiny>. This check fetches the source code of the module
from filesystem or %INC hooks, but does not actually load/execute the code.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
