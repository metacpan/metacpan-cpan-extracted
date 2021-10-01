package Sah::PSchema::perl::modname;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-29'; # DATE
our $DIST = 'Sah-PSchemas-Perl'; # DIST
our $VERSION = '0.009'; # VERSION

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
            choose_one => [qw/ns_prefix ns_prefixes/],
        },
    };
}

sub get_schema {
    require Sah::Schema::perl::modname; # for scan_prereqs

    my ($class, $args, $merge) = @_;

    return ['perl::modname', {
        'x.completion' => ['perl_modname' => {
            ($args->{ns_prefixes} ? (ns_prefixes => $args->{ns_prefixes}) : (ns_prefix => $args->{ns_prefix})),
            recurse=>$args->{complete_recurse},
            recurse_matching=>'all-at-once',
        }],
        %{ $merge || {} },
    }, {}];
}

1;
# ABSTRACT: Perl module name (parameterized)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::PSchema::perl::modname - Perl module name (parameterized)

=head1 VERSION

This document describes version 0.009 of Sah::PSchema::perl::modname (from Perl distribution Sah-PSchemas-Perl), released on 2021-09-29.

=head1 DESCRIPTION

B<EXPERIMENTAL.>

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemas-Perl>.

=head1 SEE ALSO

L<Sah::Schema::perl::modname>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-PSchemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
