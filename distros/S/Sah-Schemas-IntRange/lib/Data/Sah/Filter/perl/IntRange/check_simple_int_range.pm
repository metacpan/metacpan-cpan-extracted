package Data::Sah::Filter::perl::IntRange::check_simple_int_range;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Sah-Schemas-IntRange'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Check the syntax of simple_int_range',
        might_fail => 1,
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; my (\$m, \$n) = \$tmp =~ /\\A(-?[0-9]+)\\s*-\\s*(-?[0-9]+)\\z/; if (!defined(\$m)) { [\"Invalid range syntax, please use m-n\", \$tmp] } elsif (\$m > \$n) { [\"Start value of range must not be greater than end value: \$tmp\", \$tmp] } else { [undef, \$tmp] } }",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::IntRange::check_simple_int_range

=head1 VERSION

This document describes version 0.004 of Data::Sah::Filter::perl::IntRange::check_simple_int_range (from Perl distribution Sah-Schemas-IntRange), released on 2021-07-17.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-IntRange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-IntRange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-IntRange>

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
