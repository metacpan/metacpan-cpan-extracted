package Data::Sah::Coerce::perl::To_obj::From_str::math_complex;

# AUTHOR
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-Math'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Regexp::Pattern::Float;

my $re_float_decimal =
    $Regexp::Pattern::Float::RE{float_decimal}{pat};
my $re_float_decimal_or_exp =
    $Regexp::Pattern::Float::RE{float_decimal_or_exp}{pat};

sub meta {
    +{
        v => 4,
        summary => 'Coerce complex number from string in the form of "a + bi"',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    # TODO: allow a, or bi in addition to a + bi
    $res->{expr_match} = "$dt =~ m(\\A($re_float_decimal_or_exp)\\s*\\+\\s*($re_float_decimal)*?i\\z)";
    $res->{module}{"Math::Complex"} //= 0;
    $res->{expr_coerce} = join(
        '',
        'Math::Complex->make($1, $2)',
    );
    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_obj::From_str::math_complex

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::To_obj::From_str::math_complex (from Perl distribution Sah-Schemas-Math), released on 2020-05-27.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Math>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Math>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Math>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
