package Data::Sah::Value::perl::Perl::these_mods;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Sah-SchemaBundle-Perl'; # DIST
our $VERSION = '0.050'; # VERSION

sub meta {
    +{
        v => 1,
        summary => '"these" Perl module names',
        description => <<'_',

See <pm:App::ThisDist>'s `this_mod()` for more details on how "this module" is
determined. Currently this rule returns a 1-element arrayref containing "this
module". Note that currently `App::ThisDist` is not automatically added as
prerequisite.

_
        prio => 50,
        args => {
        },
    };
}

sub value {
    my %cargs = @_;

    my $gen_args = $cargs{args} // {};
    my $res = {};

    # $res->{modules}{"App::ThisDist"} //= 0;

    $res->{expr_value} = join(
        '',
        'do { if (eval { require App::ThisDist; 1 }) { my $thismod = App::ThisDist::this_mod(); defined $thismod ? [$thismod] : undef } else { undef } }',
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Perl::these_mods

=head1 VERSION

This document describes version 0.050 of Data::Sah::Value::perl::Perl::these_mods (from Perl distribution Sah-SchemaBundle-Perl), released on 2024-02-16.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Perl>.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
