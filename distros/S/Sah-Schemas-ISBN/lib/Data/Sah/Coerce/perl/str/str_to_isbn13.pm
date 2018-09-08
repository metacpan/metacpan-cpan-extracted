package Data::Sah::Coerce::perl::str::str_to_isbn13;

our $DATE = '2018-09-08'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 0,
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
    $res->{modules}{"Algorithm::CheckDigits::M11_001"} = 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$digits = $dt; \$digits =~ s/[^0-9Xx]//g; ",
        "my \$res; ",
        "{ ",
        "  if (length \$digits == 10) { \$digits = Algorithm::CheckDigits::CheckDigits('ean')->complete('978' . substr(\$digits, 0, 9)); \$res = [undef, \$digits]; last } ", # convert from ISBN 10
        "  if (length \$digits != 13) { \$res = ['ISBN 13 must have 13 digits']; last } ",
        "  unless (Algorithm::CheckDigits::CheckDigits('ean')->is_valid(\$digits)) { \$res = ['Invalid checksum digit']; last } ",
        "  \$res = [undef, \$digits]; ",
        "} ",
        "\$res }",
    );

    $res;
}

1;
# ABSTRACT: Check and format ISBN 13 number from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_to_isbn13 - Check and format ISBN 13 number from string

=head1 VERSION

This document describes version 0.004 of Data::Sah::Coerce::perl::str::str_to_isbn13 (from Perl distribution Sah-Schemas-ISBN), released on 2018-09-08.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["str", "x.perl.coerce_rules"=>["str_to_isbn13"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-ISBN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-ISBN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-ISBN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
