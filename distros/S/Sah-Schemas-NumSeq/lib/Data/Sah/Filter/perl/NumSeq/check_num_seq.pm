package Data::Sah::Filter::perl::NumSeq::check_num_seq;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Sah-Schemas-NumSeq'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Check the syntax of number sequence',
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{"NumSeq::Iter"} //= 0.002;
    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; my \$pres = NumSeq::Iter::numseq_parse(\$tmp); \$pres->[0] == 200 ? [undef, \$tmp] : [\$pres->[1], \$tmp] }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::NumSeq::check_num_seq

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::NumSeq::check_num_seq (from Perl distribution Sah-Schemas-NumSeq), released on 2021-07-17.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-NumSeq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-NumSeq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-NumSeq>

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
