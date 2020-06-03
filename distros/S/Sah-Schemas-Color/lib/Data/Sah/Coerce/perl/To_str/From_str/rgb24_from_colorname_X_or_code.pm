package Data::Sah::Coerce::perl::To_str::From_str::rgb24_from_colorname_X_or_code;

# AUTHOR
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce RGB24 code or color name (from Graphics::ColorNames::X scheme) to RGB24 code',
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"Graphics::ColorNames"} //= 0;
    $res->{modules}{"Graphics::ColorNames::X"} //= 0;

    $res->{expr_coerce} = join(
        "",
        "do { ", (
            "my \$tmp = lc $dt;",
            "if (\$tmp =~ /\\A\#?([0-9a-f]{6})\\z/) { return [undef, \$1] } ",
            "unless (\%__Sah::colorcodes_X) { tie \%__Sah::colorcodes_X, 'Graphics::ColorNames', 'X' } ",
            "if (exists \$__Sah::colorcodes_X{\$tmp}) { return [undef, \$__Sah::colorcodes_X{\$tmp}] } ",
            "[\"Unknown color name \\'\$tmp\\'\"]", ),
        "}",
    );
    $res;
}

1;
# ABSTRACT: Coerce RGB24 code or color name (from Graphics::ColorNames::X scheme) to RGB24 code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::rgb24_from_colorname_X_or_code - Coerce RGB24 code or color name (from Graphics::ColorNames::X scheme) to RGB24 code

=head1 VERSION

This document describes version 0.012 of Data::Sah::Coerce::perl::To_str::From_str::rgb24_from_colorname_X_or_code (from Perl distribution Sah-Schemas-Color), released on 2020-03-08.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_str::rgb24_from_colorname_X_or_code"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
