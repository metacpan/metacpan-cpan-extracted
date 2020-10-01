package Sah::Schema::rinci::function_meta;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-23'; # DATE
our $DIST = 'Sah-Schemas-Rinci'; # DIST
our $VERSION = '1.1.94.0'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Sah::Normalize ();
use Sah::Schema::rinci::meta ();

our $schema = [hash => {
    summary => 'Rinci function metadata',

    # tmp
    _ver => 1.1,
    _prop => {
        %Sah::Schema::rinci::meta::_dh_props,

        # from common rinci metadata
        entity_v => {},
        entity_date => {},
        links => {},

        is_func => {},
        is_meth => {},
        is_class_meth => {},
        args => {
            _value_prop => {
                %Sah::Schema::rinci::meta::_dh_props,

                # common rinci metadata
                links => {},

                schema => {},
                filters => {},
                default => {},
                req => {},
                pos => {},
                slurpy => {},
                greedy => {}, # old alias for slurpy, will be removed in Rinci 1.2
                partial => {},
                stream => {},
                is_password => {},
                cmdline_aliases => {
                    _value_prop => {
                        summary => {},
                        description => {},
                        schema => {},
                        code => {},
                        is_flag => {},
                    },
                },
                cmdline_on_getopt => {},
                cmdline_prompt => {},
                completion => {},
                index_completion => {},
                element_completion => {},
                cmdline_src => {},
                meta => 'fix',
                element_meta => 'fix',
                deps => {
                    _keys => {
                        arg => {},
                        all => {},
                        any => {},
                        none => {},
                    },
                },
                examples => {},
            },
        },
        args_as => {},
        args_rels => {},
        result => {
            _prop => {
                %Sah::Schema::rinci::meta::_dh_props,

                schema => {},
                statuses => {
                    _value_prop => {
                        # from defhash
                        summary => {},
                        description => {},
                        schema => {},
                    },
                },
                partial => {},
                stream => {},
            },
        },
        result_naked => {},
        examples => {
            _elem_prop => {
                %Sah::Schema::rinci::meta::_dh_props,

                args => {},
                argv => {},
                src => {},
                src_plang => {},
                status => {},
                result => {},
                naked_result => {},
                env_result => {},
                test => {},
            },
        },
        features => {
            _keys => {
                reverse => {},
                tx => {},
                dry_run => {},
                pure => {},
                immutable => {},
                idempotent => {},
                check_arg => {},
            },
        },
        deps => {
            _keys => {
                all => {},
                any => {},
                none => {},
                env => {},
                prog => {},
                pkg => {},
                func => {},
                code => {},
                tmp_dir => {},
                trash_dir => {},
            },
        },
    },

    examples => [
        {value=>{}, valid=>1},
        {
            value=>{v=>1.1, summary=>"Some function", args=>{a1=>{}, a2=>{}}},
            valid=>1,
        },
        # XXX we have not implemented property & attribute checking
    ],

}, {}];

$schema->[1]{_prop}{args}{_value_prop}{meta} = $schema->[1];
$schema->[1]{_prop}{args}{_value_prop}{element_meta} = $schema->[1];

# just so the dzil plugin won't complain about schema not being normalized.
# because this is a circular structure and normalizing creates a shallow copy.

$schema = Data::Sah::Normalize::normalize_schema($schema);

1;
# ABSTRACT: Rinci function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::rinci::function_meta - Rinci function metadata

=head1 VERSION

This document describes version 1.1.94.0 of Sah::Schema::rinci::function_meta (from Perl distribution Sah-Schemas-Rinci), released on 2020-09-23.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("rinci::function_meta*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("rinci::function_meta*");
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
             schema => ['rinci::function_meta*'],
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

 {}  # valid

 {args=>{a1=>{},a2=>{}},summary=>"Some function",v=>1.1}  # valid

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

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
