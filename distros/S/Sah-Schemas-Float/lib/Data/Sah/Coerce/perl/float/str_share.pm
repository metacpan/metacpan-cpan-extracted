package Data::Sah::Coerce::perl::float::str_share;

our $DATE = '2019-04-08'; # DATE
our $VERSION = '0.003'; # VERSION

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

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]*\\.[0-9]+|[0-9]+(?:\\.[0-9]*)?)(%?)\\z/",
    );

    $res->{expr_coerce} = join(
        '',
        '$2 ? ($1 >= 0 && $1 <= 100 ? [undef, $1/100] : ["Percentage must be between 0%-100%"]) : ',
        '$1 >= 0 && $1 <= 1 ? [undef, $1] : ',
        '$1 > 1 && $1 <= 100 ? [undef, $1/100] : ',
        '["Number must be 0 <= x <= 1, or 1 < x <= 100 (as percent)"]',
    );
    $res;
}

1;
# ABSTRACT: Coerce float from share string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::float::str_share - Coerce float from share string

=head1 VERSION

This document describes version 0.003 of Data::Sah::Coerce::perl::float::str_share (from Perl distribution Sah-Schemas-Float), released on 2019-04-08.

=head1 DESCRIPTION

This coerce rule is to be used by L<Sah::Schema::share> which accepts float in
one of three forms:

 0.4      # a number between 0 and 1
 10       # a number between 1 (exclusive) and 100, interpreted as percent
 10%      # a percentage string, between 0% and 100%

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
