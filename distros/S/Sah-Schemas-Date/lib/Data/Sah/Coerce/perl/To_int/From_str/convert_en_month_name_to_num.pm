package Data::Sah::Coerce::perl::To_int::From_str::convert_en_month_name_to_num;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-09'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.019'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Convert English month name (e.g. Dec, april) to number (1-12)',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    my $pkg = __PACKAGE__;

    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        "do { ",

        # since this is a small translation table we put it inline, but for
        # larger translation table we should move it to a separate perl module
        "\$$pkg\::month_nums ||= {",
        "  jan=>1, january=>1, ",
        "  feb=>2, february=>2, ",
        "  mar=>3, march=>3, ",
        "  apr=>4, april=>4, ",
        "  may=>5, ",
        "  jun=>6, june=>6, ",
        "  jul=>7, july=>7, ",
        "  aug=>8, august=>8, ",
        "  sep=>9, sept=>9, september=>9, ",
        "  oct=>10, october=>10, ",
        "  nov=>11, november=>11, ",
        "  dec=>12, december=>12, ",
        "}; ",
        "\$$pkg\::month_nums->{lc $dt} || $dt; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Convert English month name (e.g. Dec, april) to number (1-12)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_int::From_str::convert_en_month_name_to_num - Convert English month name (e.g. Dec, april) to number (1-12)

=head1 VERSION

This document describes version 0.019 of Data::Sah::Coerce::perl::To_int::From_str::convert_en_month_name_to_num (from Perl distribution Sah-Schemas-Date), released on 2023-12-09.

=head1 SYNOPSIS

To use in a Sah schema:

 ["int",{"x.perl.coerce_rules"=>["From_str::convert_en_month_name_to_num"]}]

=head1 DESCRIPTION

This rule can convert English month names like:

 Jan
 april
 JUN

to corresponding month numbers (i.e. 1, 4, 6 in the examples above).
Unrecognized strings will just be passed as-is.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

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

This software is copyright (c) 2023, 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
