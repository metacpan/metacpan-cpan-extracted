package Data::Sah::Coerce::perl::To_float::From_str::as_percent;

# AUTHOR
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Interpret number as percent, percent sign optional',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([+-]?(?:[0-9]*\\.[0-9]+|[0-9]+(?:\\.[0-9]*)?))(?:\\s*%)?\\z/",
    );

    $res->{expr_coerce} = join(
        '',
        '$1/100',
    );
    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_float::From_str::as_percent

=head1 VERSION

This document describes version 0.008 of Data::Sah::Coerce::perl::To_float::From_str::as_percent (from Perl distribution Sah-Schemas-Float), released on 2020-03-08.

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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
