package Statistics::Zscore;

use strict;
use warnings;
use Statistics::Lite qw(statshash);

our $VERSION = '0.00002';

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub combine {
    my $self = shift;
    my %args = @_;

    my $data     = $args{data};
    my $weight   = $args{weight};
    my $data_num = $args{data_num} - 1;
    my $scale    = $args{scale};
    my $plus     = $args{plus};
    my $decimal  = $args{decimal};

    $scale   ||= 1;
    $plus    ||= 0;
    $decimal ||= undef;

    my $array_set;
    my @keys;
    while ( my ( $key, $value ) = each %$data ) {
        for my $i ( 0 .. $data_num ) {
            push( @{ $array_set->[$i] }, $value->[$i] );
        }
        push @keys, $key;
    }

    my $zscore;
    for my $i ( 0 .. $data_num ) {
        $zscore->[$i] =
          $self->standardize( $array_set->[$i],
            { scale => $scale, plus => $plus } );
    }

    my $result;
    for my $j ( 0 .. $#keys ) {
        my $score;
        for my $i ( 0 .. $data_num ) {
            $score += $zscore->[$i]->[$j] * $weight->[$i];
        }
        if($decimal){
            my $format = '%0.' . $decimal . 'f'; 
            $score = sprintf( $format, $score );
        }
        $result->{ $keys[$j] } = $score;
    }
    return $result;
}

sub standardize {
    my $self      = shift;
    my $array_ref = shift;
    my $config    = shift;

    my %stats  = statshash @$array_ref;
    my $mean   = $stats{mean};
    my $stddev = $stats{stddev};
    if ( $stddev <= 0 ) { $stddev = 0.000000001; }
    my @zscores;
    for (@$array_ref) {
        my $zscore = ( $_ - $mean ) / $stddev;
        if ( $config->{scale} ) { $zscore *= $config->{scale}; }
        if ( $config->{plus} ) { $zscore += $config->{plus}; }
        if ( $config->{decimal} ) {
            my $format = '%0.' . $config->{decimal} . 'f'; 
            $zscore = sprintf( $format, $zscore );
        }
        push @zscores, $zscore;
    }
    return \@zscores;
}

1;
__END__

=head1 NAME

Statistics::Zscore - Simple scoring module that uses statistics STANDARD SCORE. 

=head1 SYNOPSIS

  use Statistics::Zscore;
  
  my $z = Statistics::Zscore->new;
  
  # This module calculates statistics STANDARD SCORE that is called 'z-score'. 
  # It returns array reference of z-score.

  my $zscore = $z->standardize( \@array );


  # Furthermore, you can use combine method to get a score 
  # which is a linear combination value of some z-scores with arbitrary weight set.
  # It returns hash reference.

  my $result = $z->combine(
      {
          data => {
              yamada => [ 95, 33, 65, 84 ],
              suzuki => [ 75, 45, 80, 78 ],
              tanaka => [ 44, 72, 84, 65 ],
          },
          weight => [ 0.25, 0.25, 0.4, 0.1 ],
          data_num => 4
      }
  );

=head1 DESCRIPTION

Statistics::Zscore is scoring module that uses statistics STANDARD SCORE. 

  In statistics, a standard score is a dimensionless quantity 
  derived by subtracting the population mean from an individual raw score 
  and then dividing the difference by the population standard deviation. 
  This conversion process is called standardizing or normalizing.

  Standard scores are also called z-values, z-scores, normal scores, 
  and standardized variables.

--from wiki pedia ( http://en.wikipedia.org/wiki/Standard_score )

=head1 METHOD

=head2 new()

  constructor.

=head2 standardize(\@array, {...opitons...})

  Receives array reference, and returns z-score's array refernce.
  {...options...} are 'scale', 'plus' and 'decimal'.
  (Defaults are scale => 1, plus => 0 and decimal => undef )

   it work inside..
      score = (value - mean) / stddev * scale + plus 
      score = sprintf( decimal, score);

=head2 combine(\%hash)

  Receives hash reference, and returns z-score's hash refernce.
  %hash includes 'scale', 'plus' and decimal options.(see above)

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
