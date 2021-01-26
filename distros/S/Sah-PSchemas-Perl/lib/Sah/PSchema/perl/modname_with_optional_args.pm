package Sah::PSchema::perl::modname_with_optional_args;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-26'; # DATE
our $DIST = 'Sah-PSchemas-Perl'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

sub meta {
    my $class = shift;

    return +{
        v => 1,
        args => {
            ns_prefix => {
                schema => 'perl::modname*',
                default => '',
            },
        },
    };
}

sub get_schema {
    my ($class, $args, $merge) = @_;

    return ["perl::modname_with_optional_args" => {
        'x.perl.coerce_rules' => [
            ['From_str::normalize_perl_modname' => {ns_prefix=>$args->{ns_prefix}}],
        ],

        'x.completion' => ['perl_modname' => {ns_prefix=>$args->{ns_prefix}}],
        %{ $merge || {} },
    }, {}];
}

1;
# ABSTRACT: Perl module name with optional args (parameterized)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::PSchema::perl::modname_with_optional_args - Perl module name with optional args (parameterized)

=head1 VERSION

This document describes version 0.005 of Sah::PSchema::perl::modname_with_optional_args (from Perl distribution Sah-PSchemas-Perl), released on 2021-01-26.

=head1 DESCRIPTION

B<EXPERIMENTAL.>

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-PSchemas-Perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::perl::modname_with_optional_args>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
