package Scalar::Compare;

use strict;
use warnings;

use base 'Exporter';

our $VERSION   = '0.01';
our @EXPORT_OK = qw(scalar_compare);

=head1 NAME

Scalar::Compare - Dynamically use comparison operators

=head1 SYNOPSIS

  my $scalar1  = 'waffle';
  my $scalar2  = 'pirate';
  my $operator = 'ne';
  if (scalar_compare($scalar1, $operator, $scalar2)) {
      warn "Proceed normally.";
  }

=head1 DESCRIPTION

Simple syntax sugar around Perl's comparison operators that allows you to arbitrarily compare scalars using Perl's comparison operators.

This is useful, for instance, if you want to support arbitrary comparison criteria in your application without lines and lines of if/else blocks.

=head1 FUNCTIONS

=head2 scalar_compare

Given a scalar, an operator, and another scalar, returns the result of that operator on the provided values.

For instance:

  my $ret = scalar_compare($s1, '==', $s2)

is equivalent to:

  my $ret = $s1 == $s2;

=cut

sub scalar_compare
{
    my ($our_value, $operator, $target_value) = @_;

    if ($operator eq '==') {
        return $our_value == $target_value;
    } elsif ($operator eq 'eq') {
        return $our_value eq $target_value;
    } elsif ($operator eq '!=') {
        return $our_value != $target_value;
    } elsif ($operator eq 'ne') {
        return $our_value ne $target_value;
    } elsif ($operator eq '<') {
        return $our_value < $target_value;
    } elsif ($operator eq '<=') {
        return $our_value <= $target_value;
    } elsif ($operator eq '>') {
        return $our_value > $target_value;
    } elsif ($operator eq '>=') {
        return $our_value >= $target_value;
    } elsif ($operator eq '=~') {
        return $our_value =~ /$target_value/;
    } elsif ($operator eq '!~') {
        return $our_value !~ /$target_value/;
    } elsif ($operator eq '<=>') {
        return $our_value <=> $target_value;
    } elsif ($operator eq 'cmp') {
        return $our_value cmp $target_value;
    }

    $operator ||= 'undef';

    die "Unknown comparison operator '$operator'";
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

