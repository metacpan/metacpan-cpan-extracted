package Data::Sah::Coerce::perl::float::str_suffix_filesize;

our $DATE = '2019-01-16'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Size::Suffix::Filesize;
use Data::Dmp;

sub meta {
    +{
        v => 3,
        enable_by_default => 0,
        prio => 50,
        precludes => [qr/\Astr_suffix_(\w+)\z/],
    };
}

my $re = '(\+?[0-9]+(?:\.[0-9]+)?)\s*('.join("|", sort {length($b)<=>length($a)} sort keys %Data::Size::Suffix::Filesize::suffixes).')'; $re = qr/\A$re\z/i;

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "$dt =~ ".dmp($re);
    $res->{modules}{"Data::Size::Suffix::Filesize"} = 0;
    $res->{expr_coerce} = join(
        "",
        "\$1 * \$Data::Size::Suffix::Filesize::suffixes{(lc \$2)}",
    );

    $res;
}

1;
# ABSTRACT: Parse number from string containing size suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::float::str_suffix_filesize - Parse number from string containing size suffixes

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::float::str_suffix_filesize (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2019-01-16.

=head1 DESCRIPTION

This rule accepts strings containing number with size suffixes, and return a
number with the number multiplied by the suffix multiplier, e.g.:

 2KB    -> 20248
 3.5mb  -> 3670016
 3.5Mib -> 3500000

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["float", "x.perl.coerce_rules"=>["str_suffix_filesize"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

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
