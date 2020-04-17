package Data::Sah::Coerce::perl::To_float::From_str::suffix_datasize;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-03'; # DATE
our $DIST = 'Sah-Schemas-DataSizeSpeed'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Size::Suffix::Datasize;
use Data::Dmp;

sub meta {
    +{
        v => 4,
        summary => 'Parse number from string containing data size suffixes',
        prio => 50,
        precludes => [qr/\AFrom_str::suffix_(\w+)\z/],
    };
}

my $re = '(\+?[0-9]+(?:\.[0-9]+)?)\s*('.join("|", sort {length($b)<=>length($a)} sort keys %Data::Size::Suffix::Datasize::suffixes).')'; $re = qr/\A$re\z/i;

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "$dt =~ ".dmp($re);
    $res->{modules}{"Data::Size::Suffix::Datasize"} = 0;
    $res->{expr_coerce} = join(
        "",
        "\$1 * \$Data::Size::Suffix::Datasize::suffixes{(lc \$2)}",
    );

    $res;
}

1;
# ABSTRACT: Parse number from string containing data size suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_float::From_str::suffix_datasize - Parse number from string containing data size suffixes

=head1 VERSION

This document describes version 0.006 of Data::Sah::Coerce::perl::To_float::From_str::suffix_datasize (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2020-03-03.

=head1 SYNOPSIS

To use in a Sah schema:

 ["float",{"x.perl.coerce_rules"=>["From_str::suffix_datasize"]}]

=head1 DESCRIPTION

This rule accepts strings containing number with data size suffixes, and return
a number with the number multiplied by the suffix multiplier, e.g.:

 2KB    -> 20248
 3.5mb  -> 3670016
 3.5Mib -> 3500000

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
