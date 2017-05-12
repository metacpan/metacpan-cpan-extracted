use strict;
use warnings;
use Statistics::Zscore;
use Test::More tests => 2;

{
    my @array = qw(
      1.09
      1.38
      0.99
      1.05
      1
      1.15
      0.96
      0.87
      1.07
      1
      1.02
      0.98
      1.15
      1.06
    );

    my $z = Statistics::Zscore->new;
    my $zscore = $z->standardize( \@array, { decimal => 2 } );
    my $correct = [
        '0.29',  '2.72',  '-0.54', '-0.04', '-0.46', '0.80',
        '-0.80', '-1.55', '0.13',  '-0.46', '-0.29', '-0.63',
        '0.80',  '0.04'
    ];
    is_deeply( $zscore, $correct, "deeply match" );
}

{
    my @array2 = qw(
      16284
      17923
      16536.50
      15365.50
      15305.50
      13513.50
      12193
      9189.50
      13970
      13565.50
      11426
      11207
      14244.50
    );

    my $z = Statistics::Zscore->new;
    my $zscore = $z->standardize( \@array2, { decimal => 2 } );
    my $correct = [
        '0.97',  '1.64',  '1.08', '0.60',  '0.57',  '-0.16',
        '-0.70', '-1.93', '0.03', '-0.14', '-1.01', '-1.10',
        '0.14'
    ];
    is_deeply( $zscore, $correct, "deeply match" );
}