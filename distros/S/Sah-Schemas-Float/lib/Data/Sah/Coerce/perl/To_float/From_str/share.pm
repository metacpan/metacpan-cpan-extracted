package Data::Sah::Coerce::perl::To_float::From_str::share;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.012'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce float from share string',
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]*\\.[0-9]+|[0-9]+(?:\\.[0-9]*)?)(%?)\\z/",
    );

    $res->{expr_coerce} = join(
        '',
        '$2 ? ($1 >= 0 && $1 <= 100 ? [undef, $1/100] : ["Percentage must be between 0%-100%"]) : ',
        '$1 >= 0 && $1 <= 1 ? [undef, $1] : ',
        '$1 > 1 && $1 <= 100 ? [undef, $1/100] : ',
        '["Number must be 0 <= x <= 1, or 1 < x <= 100 (as percent)"]',
    );
    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_float::From_str::share

=head1 VERSION

This document describes version 0.012 of Data::Sah::Coerce::perl::To_float::From_str::share (from Perl distribution Sah-Schemas-Float), released on 2022-09-22.

=head1 DESCRIPTION

This coerce rule is to be used by L<Sah::Schema::share> which accepts float in
one of three forms:

 0.4      # a number between 0 and 1
 10       # a number between 1 (exclusive) and 100, interpreted as percent
 10%      # a percentage string, between 0% and 100%

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

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

This software is copyright (c) 2022, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
