#=======================================================================
#
#   PDF::Builder::Matrix
#   Original Copyright 1995-96 Ulrich Pfeifer.
#   modified by Alfred Reibenschuh <areibens@cpan.org> for PDF::API2
#   rewritten by Steve Simms <steve@deefs.net> and licensed under the same 
#      terms as the rest of PDF::API2
#
#=======================================================================
package PDF::Builder::Matrix;

use strict;
use warnings;
use Carp;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Matrix - Matrix operations library

=cut

sub new {
    my $type = shift();

    my $self = [];
    my $col_count = scalar(@{$_[0]});
    foreach my $row (@_) {
        unless (scalar(@$row) == $col_count) {
	    carp 'Inconsistent column count in matrix';
	    return;
        }
        push(@{$self}, [@$row]);
    }

    return bless($self, $type);
}

# internal routine
sub transpose {
    my $self = shift();

    my @result;
    my $m;

    for my $col (@{$self->[0]}) {
        push @result, [];
    }
    for my $row (@$self) {
        $m = 0;
        for my $col (@$row) {
            push @{$result[$m++]}, $col;
        }
    }

    return PDF::Builder::Matrix->new(@result);
}

# internal routine
sub vector_product {
    my ($a, $b) = @_;
    my $result = 0;

    for my $i (0 .. $#{$a}) {
        $result += $a->[$i] * $b->[$i];
    }

    return $result;
}

# used by Content.pm
sub multiply {
    my $self  = shift();
    my $other = shift->transpose();

    my @result;

    unless ($#{$self->[0]} == $#{$other->[0]}) {
	carp 'Mismatched dimensions in matrix multiplication';
	return;
    }
    for my $row (@$self) {
        my $result_col = [];
        for my $col (@$other) {
            push @$result_col, vector_product($row,$col);
        }
        push @result, $result_col;
    }

    return PDF::Builder::Matrix->new(@result);
}

1;
