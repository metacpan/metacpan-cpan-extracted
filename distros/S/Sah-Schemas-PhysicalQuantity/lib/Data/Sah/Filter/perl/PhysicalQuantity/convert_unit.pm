package Data::Sah::Filter::perl::PhysicalQuantity::convert_unit;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-04'; # DATE
our $DIST = 'Sah-Schemas-PhysicalQuantity'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

sub meta {
    +{
        v => 1,
        summary => 'Convert quantity to another unit',
        # might_fail => 1, # we'll let Physics::Unit die on its own
        args => {
            to => {
                schema => 'str*', # XXX physical::unit
                req => 1,
            },
        },
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};
    my $gen_args = $args{args} // {};

    my $res = {};

    $res->{modules}{"Physics::Unit"} = 0;
    $res->{expr_filter} = join(
        "",
        "Physics::Unit->new( $dt->convert(".dmp($gen_args->{to}).") . ' ' . ".dmp($gen_args->{to})." )",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::PhysicalQuantity::convert_unit

=head1 VERSION

This document describes version 0.002 of Data::Sah::Filter::perl::PhysicalQuantity::convert_unit (from Perl distribution Sah-Schemas-PhysicalQuantity), released on 2020-04-04.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-PhysicalQuantity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-PhysicalQuantity>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-PhysicalQuantity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
