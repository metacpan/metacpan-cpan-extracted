package Data::Sah::Coerce::perl::To_int::From_str::convert_id_dow_name_to_num;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Convert Indonesian day-of-week name (e.g. Mg, Sen, Selasa) to number (1-7, 1=Monday/Senin)',
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
        "\$$pkg\::dow_nums ||= {",
        "  sn=>1, sen=>1, senin=>1, ",
        "  sl=>2, sel=>2, selasa=>2, ",
        "  ra=>3, rb=>3, rab=>3, rabu=>3, ",
        "  ka=>4, km=>4, kam=>4, kamis=>4, ",
        "  ju=>5, jm=>5, jum=>5, jumat=>5, 'jum\\'at'=>5, ",
        "  sa=>6, sb=>6, sab=>6, sabtu=>6, ",
        "  mi=>7, mg=>7, min=>7, mgg=>7, minggu=>7, ",
        "}; ",
        "\$$pkg\::dow_nums->{lc $dt} || $dt; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Convert Indonesian day-of-week name (e.g. Mg, Sen, Selasa) to number (1-7, 1=Monday/Senin)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_int::From_str::convert_id_dow_name_to_num - Convert Indonesian day-of-week name (e.g. Mg, Sen, Selasa) to number (1-7, 1=Monday/Senin)

=head1 VERSION

This document describes version 0.007 of Data::Sah::Coerce::perl::To_int::From_str::convert_id_dow_name_to_num (from Perl distribution Sah-Schemas-Date-ID), released on 2021-08-04.

=head1 SYNOPSIS

To use in a Sah schema:

 ["int",{"x.perl.coerce_rules"=>["From_str::convert_id_dow_name_to_num"]}]

=head1 DESCRIPTION

This rule can convert Indonesian day-of-week names like:

 Mg
 SEN
 selasa

to corresponding day-of-week numbers (i.e. 7, 1, 2 in the examples above).
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

Coerce rule L<From_str::convert_en_dow_name_to_num|Data::Sah::Coerce::perl::To_int::From_str::convert_en_dow_name_to_num>

Coerce rule L<From_str::convert_locale_dow_name_to_num|Data::Sah::Coerce::perl::To_int::From_str::convert_locale_dow_name_to_num>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
