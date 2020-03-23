package Data::Sah::Filter::perl::PhysicalQuantity::check_type;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Sah-Schemas-PhysicalQuantity'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

sub meta {
    +{
        v => 1,
        summary => "Check that physical quantity if of certain type(s)",
        might_fail => 1,
        args => {
            is => {
                schema => 'str*',
            },
            in => {
                schema => ['array*', of=>'str*'],
            },
        },
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};
    my $gen_args = $args{args} // {};

    my @check_exprs;
    if (defined $gen_args->{is}) {
        push @check_exprs, (@check_exprs ? "elsif" : "if") .
            " (\$pqtype ne ".dmp($gen_args->{is}).qq|) { ["Physical quantity type must be " . |.dmp($gen_args->{is}).qq|, \$tmp] } |;
    }
    if (defined $gen_args->{in}) {
        push @check_exprs, (@check_exprs ? "elsif" : "if") .
            " (!grep { \$pqtype eq \$_ } \@{ ".dmp($gen_args->{in}).qq| }) { ["Physical quantity type must be one of " . join(", ", \@{|.dmp($gen_args->{in}).qq|}), \$tmp] } |;
    }
    unless (@check_exprs) {
        push @check_exprs, qq(if (0) { } );
    }
    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do {",
        "    my \$tmp = $dt; ",
        "    my \$pqtype = \$tmp->type; ",
        @check_exprs,
        "    else { [undef, \$tmp] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::PhysicalQuantity::check_type

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::PhysicalQuantity::check_type (from Perl distribution Sah-Schemas-PhysicalQuantity), released on 2020-03-11.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
