package Data::Sah::Filter::perl::Array::check_elems_numeric_monotonically_decreasing;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'Sah-Schemas-Array'; # DIST
our $VERSION = '0.003'; # VERSION

sub meta {
    +{
        v => 1,
        might_fail => 1,
        summary => "Check that elements of array are monotonically decreasing numerically",
        examples => [
            {value=>{}, valid=>0, summary=>"Not an array"},
            {value=>[], valid=>1},
            {value=>[1, 3, 2], valid=>0, summary=>"Not monotonically decreasing"},
            {value=>[2, 2, 1], valid=>0, summary=>"Not monotonically decreasing"},
            {value=>[3, 2.9, 1], valid=>1},
        ],
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = join(
        "",
        "do { ", (
            "my \$ary = $dt; my \$prev; my \$res = [undef, \$ary]; ",
            "my \$ref = ref \$ary; ",
            "if (\$ref ne 'ARRAY') { \$res->[0] = 'Not an array' } else { for my \$i (0 .. \$#{\$ary}) { if (\$i > 0) { if (\$prev <= \$ary->[\$i]) { \$res->[0] = qq(Elements not monotonically increasing (check element[\$i]) ); last } } \$prev = \$ary->[\$i] } } ",
            "\$res ",
        ), "}",
    );

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Array::check_elems_numeric_monotonically_decreasing

=head1 VERSION

This document describes version 0.003 of Data::Sah::Filter::perl::Array::check_elems_numeric_monotonically_decreasing (from Perl distribution Sah-Schemas-Array), released on 2023-02-03.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Array>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
