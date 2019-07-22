package Data::Sah::Coerce::perl::int::str_convert_id_month_name_to_num;

our $DATE = '2019-06-28'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
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
        "  jan=>1, januari=>1, ",
        "  feb=>2, peb=>2, februari=>2, pebruari=>2, ",
        "  mar=>3, maret=>3, ",
        "  apr=>4, april=>4, ",
        "  mei=>5, ",
        "  jun=>6, juni=>6, ",
        "  jul=>7, juli=>7, ",
        "  agu=>8, agt=>8, agustus=>8, ",
        "  sep=>9, sept=>9, september=>9, ",
        "  okt=>10, oktober=>10, ",
        "  nov=>11, nop=>11, november=>11, nopember=>11, ",
        "  des=>12, desember=>12, ",
        "}; ",
        "\$$pkg\::month_nums->{lc $dt} || $dt; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Convert Indonesian month name (e.g. Des, april) to number (1-12)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::int::str_convert_id_month_name_to_num - Convert Indonesian month name (e.g. Des, april) to number (1-12)

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::int::str_convert_id_month_name_to_num (from Perl distribution Sah-Schemas-Date-ID), released on 2019-06-28.

=head1 DESCRIPTION

This rule can convert Indonesian month names like:

 Mei
 juli
 Agu

to corresponding month numbers (i.e. 5, 7, 8 in the examples above).
Unrecognized strings will just be passed as-is.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<str_convert_en_month_name_to_num|Data::Sah::Coerce::perl::int::str_convert_en_month_name_to_num>

L<str_convert_locale_month_name_to_num|Data::Sah::Coerce::perl::int::str_convert_locale_month_name_to_num>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
