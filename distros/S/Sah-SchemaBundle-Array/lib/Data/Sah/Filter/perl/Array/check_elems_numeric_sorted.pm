package Data::Sah::Filter::perl::Array::check_elems_numeric_sorted;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-13'; # DATE
our $DIST = 'Sah-SchemaBundle-Array'; # DIST
our $VERSION = '0.004'; # VERSION

sub meta {
    +{
        v => 1,
        might_fail => 1,
        summary => "Check that elements of array are sorted numerically",
        examples => [
            {value=>{}, valid=>0, summary=>"Not an array"},
            {value=>[], valid=>1},
            {value=>[1, 3, 2], valid=>0, summary=>"Not sorted"},
            {value=>[3, 2, 1], valid=>0, summary=>"Not sorted"},
            {value=>[1, 2, 2], valid=>1},
            {value=>[1, 2.9, 3], valid=>1},
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
            "if (\$ref ne 'ARRAY') { \$res->[0] = 'Not an array' } else { for my \$i (0 .. \$#{\$ary}) { if (\$i > 0) { if (\$prev > \$ary->[\$i]) { \$res->[0] = qq(Elements not numerically sorted (check element[\$i]) ); last } } \$prev = \$ary->[\$i] } } ",
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

Data::Sah::Filter::perl::Array::check_elems_numeric_sorted

=head1 VERSION

This document describes version 0.004 of Data::Sah::Filter::perl::Array::check_elems_numeric_sorted (from Perl distribution Sah-SchemaBundle-Array), released on 2024-02-13.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Array>.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
