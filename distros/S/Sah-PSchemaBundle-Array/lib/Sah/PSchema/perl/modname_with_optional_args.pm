package Sah::PSchema::perl::modname_with_optional_args;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'Sah-PSchemaBundle-Array'; # DIST
our $VERSION = '0.010'; # VERSION

sub meta {
    my $class = shift;

    return +{
        v => 1,
        args => {
            ns_prefix => {
                schema => 'perl::modname*',
                default => '',
            },
            ns_prefixes => {
                schema => 'perl::modname*',
            },
            complete_recurse => {
                summary => 'Whether completion should recurse',
                schema => 'bool*',
            },
        },
        args_rels => {
            req_one => [qw/ns_prefix ns_prefixes/],
        },
    };
}

sub get_schema {
    # we follow Sah::Schema::perl::modname_with_optional_args
    require Regexp::Pattern::Perl::Module;

    my ($class, $args, $merge) = @_;


    my $schema_str = [str => {
        match => '\\A(?:' . $Regexp::Pattern::Perl::Module::RE{perl_modname_with_optional_args}{pat} . ')\\z',
        'x.perl.coerce_rules' => [
            ['From_str::normalize_perl_modname', {
                ($args->{ns_prefixes} ? (ns_prefixes => $args->{ns_prefixes}) : (ns_prefix => $args->{ns_prefix})),
            }],
        ],
        'x.completion' => ['perl_modname', {
            ($args->{ns_prefixes} ? (ns_prefixes => $args->{ns_prefixes}) : (ns_prefix => $args->{ns_prefix})),
            recurse=>$args->{complete_recurse},
            recurse_matching=>'all-at-once',
        }],
    }];

    my $schema_ary = [array_from_json => {
        min_len => 1,
        max_len => 2,
        elems => [
            $schema_str,
            ["any", {
                req=>1,
                of=>[
                    ["array",{req=>1}],
                    ["hash",{req=>1}]],
            }],
        ],
    }];

    return ["any", {
        of => [
            $schema_ary,
            $schema_str,
        ],

        'x.completion' => ['perl_modname' => {
            ($args->{ns_prefixes} ? (ns_prefixes => $args->{ns_prefixes}) : (ns_prefix => $args->{ns_prefix})),
            recurse=>$args->{complete_recurse},
            recurse_matching=>'all-at-once',
        }],

        %{ $merge || {} },
    }];
}

1;
# ABSTRACT: Perl module name with optional args (parameterized)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::PSchema::perl::modname_with_optional_args - Perl module name with optional args (parameterized)

=head1 VERSION

This document describes version 0.010 of Sah::PSchema::perl::modname_with_optional_args (from Perl distribution Sah-PSchemaBundle-Array), released on 2024-05-30.

=head1 DESCRIPTION

B<EXPERIMENTAL.>

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemaBundle-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemaBundle-Array>.

=head1 SEE ALSO

L<Sah::Schema::perl::modname_with_optional_args>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-PSchemaBundle-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
