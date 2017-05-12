package RangeQuery;

use strict;
use warnings;
use Carp;

our $VERSION = '0.04';

=head1 NAME

RangeQuery - retrieves the minimum/maximum value from a sequence within a given range.

=head1 SYNOPSIS

    use RangeQuery qw(min_value max_value);

    my @sequence = (4,2,-8,6,-1,2);
    my $range = RangeQuery->new(@sequence);
    my $min = $range->min_value(0,2);   # -8
    my $max = $range->max_value (3, 5); # 6


=head1 DESCRIPTION

Retrieves the minimum/maximum value from a sequence within a given range.
It takes O(n log n) to build the object and O(1) to retrieve a min/max value.

Note: You should use a more naive approach with small sequences of values.

=head1 METHODS

=head2 new

Creates a new RangeQuery object. 
This builds the appropriate data structure in order to retrieve values efficiently.

=cut

sub new {
    my ($self, @sequence) = @_;

    croak "Set is empty." if !$#sequence;

    my @new_sequence = @sequence;
    my (@max, @min);

    my $obj = [\@new_sequence, \@max, \@min];
    bless $obj, $self;
    _build $obj;

    return $obj;
}

sub _min { $_[$_[0] > $_[1]]; }
sub _max { $_[$_[0] < $_[1]]; }

=head2 max_value

Retrieves the maximum value within a given range.

=cut

sub max_value {
    my ($self, $left, $right) = @_;
    my ($sequence, $max) = ($self->[0], $self->[1]);

    my $t = log ($right - $left + 1) / log 2;
    my $p = (1 << $t);

    return $max->[$left][$t] > $max->[$right - $p + 1][$t] ? $max->[$left][$t] : $max->[$right - $p + 1][$t];
}

=head2 min_value

Retrieves the minimum value within a given range.

=cut

sub min_value {
    my ($self, $left, $right) = @_;
    my ($sequence, $min) = ($self->[0], $self->[2]);

    my $t = log ($right - $left + 1) / log 2;
    my $p = (1 << $t);

    return $min->[$left][$t] < $min->[$right - $p + 1][$t] ? $min->[$left][$t] : $min->[$right - $p + 1][$t];
}

sub _build {
    my ($self) = @_;
    my ($sequence, $max, $min) = @{$self};
    my $size = $#{$sequence};

    for my $i (0..$size) {
	$min->[$i][0] = $max->[$i][0] = $sequence->[$i];
    }

    my $s = (log $size + 1) / log 2;
    for my $i (1 .. (log ($size + 1)) / (log 2)) {
	my $p = (1 << ($i - 1));

	for (my $j = 0; $j + (1 << $i) - 1 <= $size; $j++) {
	    $min->[$j][$i] = _min($min->[$j][$i - 1], $min->[$j + $p][$i - 1]);
	    $max->[$j][$i] = _max($max->[$j][$i - 1], $max->[$j + $p][$i - 1]);
	}
    }
}

1;
__END__

=head1 ToDo

Write this module in C.

=head1 SEE ALSO

You can check a tutorial from TopCoder, L<http://www.topcoder.com/tc?module=Static&d1=tutorials&d2=lowestCommonAncestor>

=head1 AUTHOR

JoE<atilde>o Carreira, C<< joao.carreira@ist.utl.pt >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by JoE<atilde>o Carreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
