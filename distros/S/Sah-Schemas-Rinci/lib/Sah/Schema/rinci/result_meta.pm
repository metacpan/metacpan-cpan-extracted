package Sah::Schema::rinci::result_meta;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Rinci'; # DIST
our $VERSION = '1.1.98.0'; # VERSION

use 5.010001;
use strict;
use warnings;

use Sah::Schema::rinci::meta;

our $schema = [hash => {
    summary => 'Rinci envelope result metadata',

    # tmp
    _ver => 1.1,
    _prop => {
        %Sah::Schema::rinci::meta::_defhash_props,

        schema => {},
        perm_err => {},
        func => {}, # XXX func.*
        cmdline => {}, # XXX cmdline.*
        logs => {},
        prev => {},
        results => {},
        part_start => {},
        part_len => {},
        len => {},
        stream => {},
        content_type => {},
        location => {},
    },
    _attr => {
        'cmdline.*' => {},
        'func.*' => {},
        'func_content_type.*' => {},
    },

    examples => [
        {value=>{}, valid=>1},
        {
            value=>{stream=>1},
            valid=>1,
        },
        # XXX we have not implemented property & attribute checking
    ],

}, {}];

1;
# ABSTRACT: Rinci envelope result metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::rinci::result_meta - Rinci envelope result metadata

=head1 VERSION

This document describes version 1.1.98.0 of Sah::Schema::rinci::result_meta (from Perl distribution Sah-Schemas-Rinci), released on 2021-07-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("rinci::result_meta*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("rinci::result_meta*");
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
             schema => ['rinci::result_meta*'],
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

Sample data:

 {}  # valid

 {stream=>1}  # valid

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Rinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Rinci>

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
