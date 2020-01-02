#=======================================================================
#
#   PDF::Builder::Matrix
#   Original Copyright 1995-96 Ulrich Pfeifer.
#   modified by Alfred Reibenschuh <areibens@cpan.org> for PDF::API2
#
#   This library is free software; you can redistribute it
#   and/or modify it under the same terms as Perl itself.
#
#=======================================================================
package PDF::Builder::Matrix;

use strict;
use warnings;

our $VERSION = '3.017'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Matrix - matrix operations library

=cut

sub new {
    my $type = shift;
    my $self = [];
    my $len = scalar(@{$_[0]});
    for (@_) {
        return if scalar(@{$_}) != $len;
        push(@{$self}, [@{$_}]);
    }
    bless $self, $type;
    return $self;
}

# internal routine
sub transpose {
    my $self = shift;
    my @result;
    my $m;

    for my $col (@{$self->[0]}) {
        push @result, [];
    }
    for my $row (@{$self}) {
        $m = 0;
        for my $col (@{$row}) {
            push(@{$result[$m++]}, $col);
        }
    }
    return PDF::Builder::Matrix->new(@result);
}

# internal routine
sub vekpro {
    my ($a, $b) = @_;
    my $result = 0;

    for my $i (0 .. $#{$a}) {
        $result += $a->[$i] * $b->[$i];
    }
    return $result;
}

# used by Content.pm
sub multiply {
    my $self  = shift;
    my $other = shift->transpose();
    my @result;
    my $m;

    return if $#{$self->[0]} != $#{$other->[0]};
    for my $row (@{$self}) {
        my $rescol = [];
        for my $col (@{$other}) {
            push(@{$rescol}, vekpro($row,$col));
        }
        push(@result, $rescol);
    }
    return PDF::Builder::Matrix->new(@result);
}

1;
