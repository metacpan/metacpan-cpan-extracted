package Permute::Named::Iter;

our $DATE = '2016-09-26'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                    permute_named_iter
            );

sub permute_named_iter {
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

    my $state = [(0) x @keys];
    my $state2 = 0; # 0,1,2
    my $iter = sub {
        if (!$state2) { # starting the first time, don't increment state yet
            $state2 = 1;
            goto L2;
        } elsif ($state2 == 2) { # all permutation exhausted
            return undef;
        }
        my $i = $#{$state};
      L1:
        while ($i >= 0) {
            if ($state->[$i] >= $#{$values[$i]}) {
                if ($i == 0) {
                    $state2 = 2;
                    return undef;
                }
                $state->[$i] = 0;
                my $j = $i-1;
                while ($j >= 0) {
                    if ($state->[$j] >= $#{$values[$j]}) {
                        if ($j == 0) { # all permutation exhausted
                            $state2 = 2;
                            return undef;
                        }
                        $state->[$j] = 0;
                        $j--;
                    } else {
                        $state->[$j]++;
                        last L1;
                    }
                }
                $i--;
            } else {
                $state->[$i]++;
                last;
            }
        }
      L2:
        return { map { ($keys[$_] => $values[$_][ $state->[$_] ]) }
                     0..$#{$state} };
    };
    $iter;
}

1;
# ABSTRACT: Permute multiple-valued key-value pairs

__END__

=pod

=encoding UTF-8

=head1 NAME

Permute::Named::Iter - Permute multiple-valued key-value pairs

=head1 VERSION

This document describes version 0.04 of Permute::Named::Iter (from Perl distribution Permute-Named-Iter), released on 2016-09-26.

=head1 SYNOPSIS

 use Permute::Named::Iter qw(permute_named_iter);

 my $iter = permute_named_iter(bool => [ 0, 1 ], x => [qw(foo bar baz)]);
 while (my $h = $iter->()) {
     some_setup() if $h->{bool};
     other_setup($h->{x});
     # ... now maybe do some tests ...
 }

=head1 DESCRIPTION

This module is like L<Permute::Named>, except that it offers an iterator
interface. Some other differences: 1) it only accepts an even-sized list and not
arrayref or hashref; 2) it does not use deep cloning, so if one of the values is
a reference and you modify the content of the reference, the next iteration will
see the modification; 3) the function C<permute_named_iter> is not exported by
default, you have to import it explicitly.

=head1 FUNCTIONS

=head2 permute_named_iter(@list) => CODE

Takes a list of key-specification pairs where the specifications can be single
values or references to arrays of possible values. It then returns an iterator
(coderef) which you can call repeatedly to permute all key-specification
combinations.

The function expects the pairs as an even-sized list. Each specification can be
a scalar or a reference to an array of possible values. The returned iterator
can be called and will return a hashref, or undef if all the permutation has
been exhausted.

Example 1:

 my $iter = permute_named_iter(bool => [ 0, 1 ], x => [qw(foo bar baz)]);
 my @p; while (my $h = $iter->()) { push @p, $h }

C<@p> will contain:

 ( { bool => 0, x => 'foo' },
   { bool => 0, x => 'bar' },
   { bool => 0, x => 'baz' },
   { bool => 1, x => 'foo' },
   { bool => 1, x => 'bar' },
   { bool => 1, x => 'baz' }, )

Example 2:

 my $iter = permute_named_iter(bool => 1, x => 'foo');
 my @p; while (my $h = $iter->()) { push @p, $h }

C<@p> will just contain the one permutation:

 ({bool => 1, x => 'foo'})

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Permute-Named-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Permute-Named-Iter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Permute-Named-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Permute::Named>, L<PERLANCAR::Permute::Named> and CLI L<permute-named>.

L<Set::CrossProduct>, L<Set::Product>, et al (see the POD of Set::Product for
more similar modules) and CLI L<cross>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
