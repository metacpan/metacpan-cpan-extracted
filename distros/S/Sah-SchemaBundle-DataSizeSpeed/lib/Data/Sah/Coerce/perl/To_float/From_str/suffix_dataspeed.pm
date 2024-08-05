package Data::Sah::Coerce::perl::To_float::From_str::suffix_dataspeed;

use 5.010001;
use strict;
use warnings;

use Data::Size::Suffix::Dataspeed;
use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-03'; # DATE
our $DIST = 'Sah-SchemaBundle-DataSizeSpeed'; # DIST
our $VERSION = '0.010'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Parse number from string containing data speed suffixes',
        prio => 50,
        precludes => [qr/\AFrom_str::suffix_(\w+)\z/],
    };
}

my $re = '(\+?[0-9]+(?:\.[0-9]+)?)\s*('.join("|", sort {length($b)<=>length($a)} sort keys %Data::Size::Suffix::Dataspeed::suffixes).')'; $re = qr/\A$re\z/;

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "$dt =~ ".dmp($re);
    $res->{modules}{"Data::Size::Suffix::Dataspeed"} = 0;
    $res->{expr_coerce} = join(
        "",
        "\$1 * \$Data::Size::Suffix::Dataspeed::suffixes{\$2}",
    );

    $res;
}

1;
# ABSTRACT: Parse number from string containing data speed suffixes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_float::From_str::suffix_dataspeed - Parse number from string containing data speed suffixes

=head1 VERSION

This document describes version 0.010 of Data::Sah::Coerce::perl::To_float::From_str::suffix_dataspeed (from Perl distribution Sah-SchemaBundle-DataSizeSpeed), released on 2024-08-03.

=head1 SYNOPSIS

To use in a Sah schema:

 ["float",{"x.perl.coerce_rules"=>["From_str::suffix_dataspeed"]}]

=head1 DESCRIPTION

This rule accepts strings containing number with data speed suffixes, and return
a number with the number multiplied by the suffix multiplier, e.g.:

    1000kbps -> 128000 (kilobits per second, 1024-based)
    2.5 mbit -> 327680 (megabit per second, 1024-based)
    128KB/s  -> 131072 (kilobyte per second, 1024-based)

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-DataSizeSpeed>.

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

This software is copyright (c) 2024, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
