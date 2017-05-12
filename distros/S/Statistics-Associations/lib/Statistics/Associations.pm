package Statistics::Associations;

use strict;
use Carp;
our $VERSION = '0.00003';

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    return $self;
}

sub phi {
    my $self   = shift;
    my $matrix = shift;
    unless ( ref $matrix eq 'ARRAY' && ref $matrix->[0] eq 'ARRAY' ) {
        croak("ERROR: invalid matrix is posted");
    }
    my $phi    = sqrt( $self->chisq($matrix) / $self->_sum($matrix) );
    return $phi;
}

sub contingency {
    my $self        = shift;
    my $matrix      = shift;
    unless ( ref $matrix eq 'ARRAY' && ref $matrix->[0] eq 'ARRAY' ) {
        croak("ERROR: invalid matrix is posted");
    }
    my $x2          = $self->chisq($matrix);
    my $contingency = sqrt( $x2 / ( $self->_sum($matrix) + $x2 ) );
    return $contingency;
}

sub cramer {
    my $self   = shift;
    my $matrix = shift;
    unless ( ref $matrix eq 'ARRAY' && ref $matrix->[0] eq 'ARRAY' ) {
        croak("ERROR: invalid matrix is posted");
    }
    my $row_num = @$matrix;
    my $col_num = @{ $matrix->[0] };
    my $n;
    $n = $col_num if ( @$matrix >= @{ $matrix->[0] } );
    $n = $row_num if ( @$matrix <= @{ $matrix->[0] } );
    my $cramer = $self->phi($matrix) / sqrt( $n - 1 );
    return $cramer;
}

sub chisq {
    my $self   = shift;
    my $matrix = shift;
    unless ( ref $matrix eq 'ARRAY' && ref $matrix->[0] eq 'ARRAY' ) {
        croak("ERROR: invalid matrix is posted");
    }
    $self->{matrix}    = $matrix;
    $self->{row_count} = @$matrix;
    $self->{col_count} = @{ $matrix->[0] };
    my $x2;
    for my $i ( 0 .. $self->{row_count} - 1 ) {
        for my $j ( 0 .. $self->{col_count} - 1 ) {
            my $row_sum = $self->_row_sum($i);
            my $col_sum = $self->_col_sum($j);
            my $sum     = $self->_sum;
            my $expect  = $row_sum * $col_sum / $sum;
            $expect ||= 0.00000000000001;
            $x2 += ( $matrix->[$i]->[$j] - $expect )**2 / $expect;
        }
    }
    return $x2;
}

sub _row_sum {
    my $self    = shift;
    my $row_num = shift;
    $self->{row_sum}->[$row_num] or sub {
        my $sum;
        for my $i ( 0 .. $self->{col_count} - 1 ) {
            $sum += $self->{matrix}->[$row_num]->[$i];
        }
        $self->{row_sum}->[$row_num] = $sum;
      }
      ->();
}

sub _col_sum {
    my $self    = shift;
    my $col_num = shift;
    $self->{col_sum}->[$col_num] or sub {
        my $sum;
        for my $i ( 0 .. $self->{row_count} - 1 ) {
            $sum += $self->{matrix}->[$i]->[$col_num];
        }
        $self->{col_sum}->[$col_num] = $sum;
      }
      ->();
}

sub _sum {
    my $self = shift;
    my $sum;
    $self->{sum} or sub {
        for my $i ( 0 .. $self->{row_count} - 1 ) {
            for my $j ( 0 .. $self->{col_count} - 1 ) {
                $sum += $self->{matrix}->[$i]->[$j];
            }
        }
        $self->{sum} = $sum;
      }
      ->();
}

sub make_matrix {
    my $self      = shift;
    my $row_label = shift;
    my $col_label = shift;
    my $value     = shift;
    unless ( defined $row_label ) {
        croak("ERROR: undefined row_label is posted");
    }
    unless ( defined $col_label ) {
        croak("ERROR: undefined col_label is posted");
    }
    unless ( defined $value ) { $value = 1; }
    my $row_num = $self->_key2num( { row => $row_label } );
    my $col_num = $self->_key2num( { col => $col_label } );
    $self->{matrix}->[$row_num]->[$col_num] += $value;
}

sub _key2num {
    my $self = shift;
    my $ref  = shift;
    my ( $row_or_col, $label ) = each %$ref;
    my $num = $self->{$row_or_col}->{$label} ||=
      ++$self->{ $row_or_col . '_count' };
    $num = $num - 1;
    $self->{ $row_or_col . '_label' }->[$num] = $label;
    return $num;
}

sub matrix {
    my $self = shift;
    for my $i ( 0 .. $self->{row_count} - 1 ) {
        for my $j ( 0 .. $self->{col_count} - 1 ) {
            $self->{matrix}->[$i]->[$j] ||= 0;
        }
    }
    return $self->{matrix} || [];
}

sub convert_hashref {
    my $self = shift;
    my $hash = {};
    for my $i ( 0 .. $self->{row_count} - 1 ) {
        for my $j ( 0 .. $self->{col_count} - 1 ) {
            my $row_label = $self->{row_label}->[$i];
            my $col_label = $self->{col_label}->[$j];
            $hash->{$row_label}->{$col_label} = $self->{matrix}->[$i]->[$j];
        }
    }
    return $hash;
}

1;
__END__

=head1 NAME

Statistics::Associations - Calculates Association Coefficients of Nominal Scale.

=head1 SYNOPSIS

  use Statistics::Associations;
  my $asso = Statistics::Associations->new;

  # Basic Methods
  # calculates coefficients

  my $matrix = [ [ 6, 4 ], [ 5, 5 ] ];
  my $phi         = $asso->phi($matrix);
  my $contingency = $asso->contingency($matrix);
  my $cramer      = $asso->cramer($matrix);

  # -------------------

  # Helper Methods
  # it helps you to making matrix

  while(<STDIN>){
      my $row_label = ...;
      my $col_label = ...;
      my $value = ...;
      $asso->make_matrix( $row_label, $col_label, $value );
  }
  my $matrix = $asso->matrix;

  # convert to hash_ref
  my $hash_ref = $asso->convert_hashref;

=head1 DESCRIPTION

Statistics::Associations is a calculator of Association Coefficients that specialized in 'Nominal Scale'.

It calculates next three coeffients.

 * phi
 * contingency
 * cramer

And it calculates chi-square, too.

And then, it helps you to making matrix in a loop that looks like parsing logs.

=head1 METHODS

=head2 new

=head2 phi( $matrix )

=head2 contingency( $matrix )

=head2 cramer( $matrix )

=head2 chisq( $matrix )

=head2 make_matrix( $row_label, $col_label, [$value] )

=head2 matrix()

=head2 convert_hashref()

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
