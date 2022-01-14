package Data::Sah::Coerce::perl::To_obj::From_str::math_complex;

use 5.010001;
use strict;
use warnings;

use Regexp::Pattern::Float;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-11'; # DATE
our $DIST = 'Sah-Schemas-Math'; # DIST
our $VERSION = '0.003'; # VERSION

my $re_float_decimal =
    $Regexp::Pattern::Float::RE{float_decimal}{pat};
my $re_float_decimal_or_exp =
    $Regexp::Pattern::Float::RE{float_decimal_or_exp}{pat};

sub meta {
    +{
        v => 4,
        summary => 'Coerce complex number from string in the form of "<a> + <b>i"',
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

This document describes version 0.003 of Data::Sah::Coerce::perl::To_obj::From_str::math_complex (from Perl distribution Sah-Schemas-Math), released on 2021-12-11.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Math>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Math>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Math>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
