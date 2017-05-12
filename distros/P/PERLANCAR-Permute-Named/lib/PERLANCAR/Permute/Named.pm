package PERLANCAR::Permute::Named;

our $DATE = '2016-09-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
our @EXPORT = qw(
                    permute_named
            );

sub permute_named {
    die "Please supply a non-empty list of key-specification pairs" unless @_;
    die "Please supply an even-sized list" unless @_ % 2 == 0;

    my @keys;
    my @values;
    while (my ($key, $values) = splice @_, 0, 2) {
        push @keys, $key;
        $values = [$values] unless ref($values) eq 'ARRAY';
        die "$key cannot contain empty values" unless @$values;
        push @values, $values;
    }
    my @res;
    my $code = '{ my @j;';
    for my $i (0..$#keys) {
        $code .= " local \$main::_j$i;";
    }
    for my $i (0..$#keys) {
        $code .= " for \$main::_j$i (0..". $#{$values[$i]} . ") {";
    }
    $code .= " my \$h = {}; for my \$k (0..". $#keys . ") { \$h->{\$keys[\$k]} = \$values[\$k][ \${\"main::_j\$k\"} ]; } push \@res, \$h;";
    for my $i (0..$#keys) {
        $code .= ' }';
    }
    $code .= " }";
    #say $code;
    eval $code; if ($@) { warn "$code\n"; die }
    wantarray ? @res : \@res;
}

1;
# ABSTRACT: Permute multiple-valued key-value pairs

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Permute::Named - Permute multiple-valued key-value pairs

=head1 VERSION

This document describes version 0.03 of PERLANCAR::Permute::Named (from Perl distribution PERLANCAR-Permute-Named), released on 2016-09-25.

=head1 SYNOPSIS

 use PERLANCAR::Permute::Named;

 my @p = permute_named(bool => [ 0, 1 ], x => [qw(foo bar baz)]);
 for (@p) {
     some_setup() if $_->{bool};
     other_setup($_->{x});
     # ... now maybe do some tests ...
 }

=head1 DESCRIPTION

This module is like L<Permute::Named>, except that it uses a different
technique: dynamically generates nested loop Perl code, evals that, and avoids
repetitive deep cloning. It can be faster than Permute::Named as the number of
keys and values increase.

=head1 FUNCTIONS

=head2 permute_named(@list) => @list | $arrayref

Takes a list of key-specification pairs where the specifications can be single
values or references to arrays of possible actual values. It then permutes all
key-specification combinations and returns the resulting list (or arrayref) of
permutations, depending on context.

The function expects the pairs as an even-sized list. Each specification can be
a scalar or a reference to an array of possible values.

Example 1:

 permute_named(bool => [ 0, 1 ], x => [qw(foo bar baz)])

returns:

 [ { bool => 0, x => 'foo' },
   { bool => 0, x => 'bar' },
   { bool => 0, x => 'baz' },
   { bool => 1, x => 'foo' },
   { bool => 1, x => 'bar' },
   { bool => 1, x => 'baz' }, ]

Example 2:

 permute_named(bool => 1, x => 'foo')

just returns the one permutation:

 {bool => 1, x => 'foo'}

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Permute-Named>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Permute-Named>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Permute-Named>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Permute::Named>, L<Permute::Named::Iter> and CLI <permute-named>

L<Set::CrossProduct> and L<cross>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
