package Data::Sah::Value::perl::Perl::this_mod;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-11'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.045'; # VERSION

sub meta {
    +{
        v => 1,
        summary => '"this" Perl module name',
        description => <<'_',

See <pm:App::ThisDist>'s `this_mod()` for more details on how "this module" is
determined. Note that currently `App::ThisDist` is not automatically added as
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
        'do { if (eval { require App::ThisDist; 1 }) { App::ThisDist::this_mod() } else { undef } }',
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Perl::this_mod

=head1 VERSION

This document describes version 0.045 of Data::Sah::Value::perl::Perl::this_mod (from Perl distribution Sah-Schemas-Perl), released on 2022-09-11.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
