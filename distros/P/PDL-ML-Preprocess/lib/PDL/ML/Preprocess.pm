package PDL::ML::Preprocess;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);
use PDL::Core ();
use PDL::Lite ();
use PDL::Ufunc ();

our $VERSION   = '0.01';
our @EXPORT_OK = qw(
    train_test_split
    standard_scale
    minmax_scale
    l2_normalize
    one_hot_encode
);

sub train_test_split {
    my ($X, $y, %opts) = @_;
    my $test_size = $opts{test_size} // 0.2;
    my $shuffle   = $opts{shuffle}   // 1;
    my $seed      = $opts{seed};

    my $n = $X->dim(-1);
    croak 'X and y must have matching sample counts'
        if defined $y && $y->dim(-1) != $n;

    my @idx = (0 .. $n - 1);
    if ($shuffle) {
        srand($seed) if defined $seed;
        for (my $i = $#idx; $i > 0; $i--) {
            my $j = int(rand($i + 1));
            @idx[$i, $j] = @idx[$j, $i];
        }
    }

    my $n_test = int($n * $test_size);
    $n_test = 1 if $n_test < 1 && $n > 1;
    my $n_train = $n - $n_test;

    my $tr = PDL::Core::pdl(PDL::long(), [ @idx[ 0 .. $n_train - 1 ] ]);
    my $te = PDL::Core::pdl(PDL::long(), [ @idx[ $n_train .. $n - 1 ] ]);

    my $X_tr = $X->dice_axis(-1, $tr);
    my $X_te = $X->dice_axis(-1, $te);
    return ($X_tr, $X_te) unless defined $y;

    my $y_tr = $y->dice_axis(-1, $tr);
    my $y_te = $y->dice_axis(-1, $te);
    return ($X_tr, $X_te, $y_tr, $y_te);
}

sub standard_scale {
    my ($X, %opts) = @_;
    my $eps  = $opts{eps} // 1e-8;
    my $mean = $opts{mean} // $X->transpose->average;
    my $diff = $X - $mean;
    my $std  = $opts{std} // sqrt(($diff * $diff)->transpose->average);
    my $safe = $std->where($std > $eps);
    my $denom = $std->copy;
    $denom->where($denom <= $eps) .= 1.0;
    my $scaled = $diff / $denom;
    return wantarray ? ($scaled, $mean, $denom) : $scaled;
}

sub minmax_scale {
    my ($X, %opts) = @_;
    my $min = $opts{min} // $X->transpose->minimum;
    my $max = $opts{max} // $X->transpose->maximum;
    my $range = $max - $min;
    $range->where($range == 0) .= 1.0;
    my $scaled = ($X - $min) / $range;
    return wantarray ? ($scaled, $min, $max) : $scaled;
}

sub l2_normalize {
    my ($X, %opts) = @_;
    my $eps  = $opts{eps} // 1e-12;
    my $norm = sqrt(($X * $X)->sumover);
    $norm->where($norm < $eps) .= 1.0;
    return $X / $norm->dummy(0);
}

sub one_hot_encode {
    my ($labels, $num_classes) = @_;
    $num_classes //= int($labels->max) + 1;
    my $n = $labels->nelem;
    my $out = PDL->zeroes(PDL::float(), $num_classes, $n);
    for my $i (0 .. $n - 1) {
        my $c = int($labels->at($i));
        croak "Class index $c out of range [0, $num_classes)" if $c < 0 || $c >= $num_classes;
        $out->set($c, $i, 1.0);
    }
    return $out;
}

1;

__END__

=head1 NAME

PDL::ML::Preprocess - Machine learning preprocessing utilities for PDL ndarrays

=head1 SYNOPSIS

    use PDL;
    use PDL::ML::Preprocess qw(train_test_split standard_scale minmax_scale l2_normalize one_hot_encode);

    my ($X_tr, $X_te, $y_tr, $y_te) = train_test_split($X, $y, test_size => 0.2, seed => 42);
    my ($X_std, $mean, $std) = standard_scale($X_tr);
    my $oh = one_hot_encode(long([0, 2, 1]), 3);

=head1 DESCRIPTION

C<PDL::ML::Preprocess> provides common tabular and vector preprocessing
functions (train/test splitting, standardization, min-max scaling, L2
normalization, and one-hot encoding) operating directly on L<PDL> ndarrays.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
