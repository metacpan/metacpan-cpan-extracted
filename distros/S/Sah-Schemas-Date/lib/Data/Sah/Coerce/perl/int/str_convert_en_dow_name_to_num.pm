package Data::Sah::Coerce::perl::int::str_convert_en_dow_name_to_num;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.003'; # VERSION

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
        "\$$pkg\::dow_nums ||= {",
        "  mo=>1, mon=>1, monday=>1, ",
        "  tu=>2, tue=>2, tuesday=>2, ",
        "  we=>3, wed=>3, wednesday=>3, ",
        "  th=>4, thu=>4, thursday=>4, ",
        "  fr=>5, fri=>5, friday=>5, ",
        "  sa=>6, sat=>6, saturday=>6, ",
        "  su=>7, sun=>7, sunday=>7, ",
        "}; ",
        "\$$pkg\::dow_nums->{lc $dt} || $dt; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Convert English day-of-week name (e.g. su, MON, Tuesday) to number (1-7, 1=Monday)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::int::str_convert_en_dow_name_to_num - Convert English day-of-week name (e.g. su, MON, Tuesday) to number (1-7, 1=Monday)

=head1 VERSION

This document describes version 0.003 of Data::Sah::Coerce::perl::int::str_convert_en_dow_name_to_num (from Perl distribution Sah-Schemas-Date), released on 2019-06-20.

=head1 DESCRIPTION

This rule can convert English day-of-week names like:

 su
 MON
 Tuesday

to corresponding day-of-week numbers (i.e. 7, 1, 2 in the examples above).
Unrecognized strings will just be passed as-is.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
