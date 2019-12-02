package Data::Sah::Coerce::perl::To_int::From_str::convert_en_or_id_dow_name_to_num;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Convert English/Indonesian day-of-week name (e.g. Su, Mg, Mon, Sen, Tuesday, Selasa) to number (1-7, 1=Monday/Senin)',
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
        # english
        "  mo=>1, mon=>1, monday=>1, ",
        "  tu=>2, tue=>2, tuesday=>2, ",
        "  we=>3, wed=>3, wednesday=>3, ",
        "  th=>4, thu=>4, thursday=>4, ",
        "  fr=>5, fri=>5, friday=>5, ",
        "  sa=>6, sat=>6, saturday=>6, ",
        "  su=>7, sun=>7, sunday=>7, ",
        # indonesian
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
# ABSTRACT: Convert English/Indonesian day-of-week name (e.g. Su, Mg, Mon, Sen, Tuesday, Selasa) to number (1-7, 1=Monday/Senin)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_int::From_str::convert_en_or_id_dow_name_to_num - Convert English/Indonesian day-of-week name (e.g. Su, Mg, Mon, Sen, Tuesday, Selasa) to number (1-7, 1=Monday/Senin)

=head1 VERSION

This document describes version 0.003 of Data::Sah::Coerce::perl::To_int::From_str::convert_en_or_id_dow_name_to_num (from Perl distribution Sah-Schemas-Date-ID), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["int",{"x.perl.coerce_rules"=>["From_str::convert_en_or_id_dow_name_to_num"]}]

=head1 DESCRIPTION

This rule can convert English/Indonesian day-of-week names like:

 Su
 Mg

 MON
 SEN

 tuesday
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

Coerce rule L<From_str::convert_id_dow_name_to_num|Data::Sah::Coerce::perl::To_int::From_str::convert_id_dow_name_to_num>

Coerce rule L<From_str::convert_locale_dow_name_to_num|Data::Sah::Coerce::perl::To_int::From_str::convert_locale_dow_name_to_num>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
