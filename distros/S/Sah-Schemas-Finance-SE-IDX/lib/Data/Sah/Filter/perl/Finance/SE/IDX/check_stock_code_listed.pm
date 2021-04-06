package Data::Sah::Filter::perl::Finance::SE::IDX::check_stock_code_listed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-18'; # DATE
our $DIST = 'Sah-Schemas-Finance-SE-IDX'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Check that a stock code is listed',
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{"Finance::SE::IDX::Static"} //= 0.006;

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = uc($dt); my \$ret; ",

        # since we are performed early before other clauses like len=4, we might
        # as well check the syntax of stock code here and provide a more
        # meaningful error message
        "  if (length \$tmp != 4 || \$tmp !~ /\\A[A-Z]{4}\\z/) { \$ret = [\"Stock code must be 4 letters\", \$tmp]; goto RETURN_RET } ",

        "  for my \$rec (\@{ \$Finance::SE::IDX::Static::data_stock }) { ",
        "    if (\$rec->[0] eq \$tmp) { \$ret=[undef, \$tmp]; last } ",
        "  } ",
        "\$ret ||= [\"Stock code \$tmp is not listed\", \$tmp]; ",
        "RETURN_RET: \$ret }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Finance::SE::IDX::check_stock_code_listed

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::Finance::SE::IDX::check_stock_code_listed (from Perl distribution Sah-Schemas-Finance-SE-IDX), released on 2021-01-18.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Finance-SE-IDX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Finance-SE-IDX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-Finance-SE-IDX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
