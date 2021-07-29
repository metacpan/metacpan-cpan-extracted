package Sah::Schema::defhash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'Sah-Schemas-DefHash'; # DIST
our $VERSION = '1.0.13.0'; # VERSION

use strict;
use warnings;

use Regexp::Pattern::DefHash;

our $schema = [hash => {
    summary => 'DefHash',
    'allowed_keys_re' => $Regexp::Pattern::DefHash::RE{key}{pat},
    keys => {

        v         => ['float', {req=>1, default=>1}],

        defhash_v => ['int', {req=>1, default=>1}],

        name      => ['str', {
            req=>1,
            clset => [
                {
                    match             => '\A\w+\z',
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should be a word',
                },
                {
                    max_len             => 32,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
            ],
            'clset.op' => 'and',
        }],

        caption   => ['str', {req=>1}],

        summary   => ['str', {
            req => 1,
            clset => [
                {
                    max_len             => 72,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
                {
                    'match'           => qr/\n/,
                    'match.op'        => 'not',
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should only be a single-line text',
                },
            ],
            'clset.op' => 'and',
        }],

        description => ['str', {req => 1}],

        tags => ['array', {
            of => ['any', {
                req => 1,
                of => [
                    ['str', {req=>1}],
                    ['hash', {req=>1}], # XXX defhash
                ],
            }],
        }],

        default_lang => ['str', {
            req => 1,
            match => '\A[a-z]{2}(_[A-Z]{2})?\z',
        }, {}],

        x => ['any', {
        }, {}],
    },
    'keys.restrict' => 0,

    examples => [
        {value=>{}, valid=>1},
        {value=>{foo=>1, bar=>1}, valid=>1},
        {value=>{"foo-bar"=>1}, valid=>0, summary=>"Invalid property syntax, contains dash"},
    ],
}];

# XXX check known attributes (.alt, etc)
# XXX check alt.XXX format (e.g. must be alt\.(lang\.\w+|env_lang\.\w+)
# XXX *.alt.*.X should also be of the same type (e.g. description.alt.lang.foo

1;
# ABSTRACT: DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::defhash - DefHash

=head1 VERSION

This document describes version 1.0.13.0 of Sah::Schema::defhash (from Perl distribution Sah-Schemas-DefHash), released on 2021-07-21.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("defhash*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("defhash*");
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
             schema => ['defhash*'],
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

 {bar=>1,foo=>1}  # valid

 {"foo-bar"=>1}  # INVALID (Invalid property syntax, contains dash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DefHash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DefHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
