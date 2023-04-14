package Data::Sah::Coerce::perl::To_str::From_str::to_ean13;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-27'; # DATE
our $DIST = 'Sah-Schemas-EAN'; # DIST
our $VERSION = '0.009'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Check and format EAN-13 number from string',
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"Algorithm::CheckDigits"} = 0;
    $res->{modules}{"Algorithm::CheckDigits::M10_004"} = 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$digits = $dt; \$digits =~ s/[^0-9]//g; ",
        "my \$res; ",
        "{ ",
        "  if (length \$digits != 13) { \$res = ['EAN-13 must have 13 digits']; last } ",
        "  unless (Algorithm::CheckDigits::CheckDigits('ean')->is_valid(\$digits)) { \$res = ['Invalid checksum digit']; last } ",
        "  \$res = [undef, \$digits]; ",
        "} ",
        "\$res }",
    );

    $res;
}

1;
# ABSTRACT: Check and format EAN-13 number from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::to_ean13 - Check and format EAN-13 number from string

=head1 VERSION

This document describes version 0.009 of Data::Sah::Coerce::perl::To_str::From_str::to_ean13 (from Perl distribution Sah-Schemas-EAN), released on 2023-01-27.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_str::to_ean13"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

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

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
