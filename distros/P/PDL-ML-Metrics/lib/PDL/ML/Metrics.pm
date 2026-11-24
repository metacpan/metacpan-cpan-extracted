package PDL::ML::Metrics;

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
    accuracy
    precision_recall_f1
    confusion_matrix
    mse
    rmse
    mae
    r2_score
    cosine_similarity
    roc_auc
);

sub accuracy {
    my ($y_true, $y_pred) = @_;
    return ($y_true == $y_pred)->double->avg;
}

sub confusion_matrix {
    my ($y_true, $y_pred, $num_classes) = @_;
    my $n = $y_true->nelem;
    $num_classes //= int(($y_true->max > $y_pred->max ? $y_true->max : $y_pred->max)) + 1;
    my $cm = PDL->zeroes(PDL::long(), $num_classes, $num_classes);
    for my $i (0 .. $n - 1) {
        my $t = int($y_true->at($i));
        my $p = int($y_pred->at($i));
        $cm->set($p, $t, $cm->at($p, $t) + 1);
    }
    return $cm;
}

sub precision_recall_f1 {
    my ($y_true, $y_pred, $pos_label) = @_;
    $pos_label //= 1;
    my $tp = (($y_true == $pos_label) & ($y_pred == $pos_label))->double->sum;
    my $fp = (($y_true != $pos_label) & ($y_pred == $pos_label))->double->sum;
    my $fn = (($y_true == $pos_label) & ($y_pred != $pos_label))->double->sum;
    my $prec = ($tp + $fp) > 0 ? $tp / ($tp + $fp) : 0.0;
    my $rec  = ($tp + $fn) > 0 ? $tp / ($tp + $fn) : 0.0;
    my $f1   = ($prec + $rec) > 0 ? 2 * $prec * $rec / ($prec + $rec) : 0.0;
    return ($prec, $rec, $f1);
}

sub mse {
    my ($y_true, $y_pred) = @_;
    my $diff = $y_true->double - $y_pred->double;
    return ($diff * $diff)->avg;
}

sub rmse {
    my ($y_true, $y_pred) = @_;
    return sqrt(mse($y_true, $y_pred));
}

sub mae {
    my ($y_true, $y_pred) = @_;
    return abs($y_true->double - $y_pred->double)->avg;
}

sub r2_score {
    my ($y_true, $y_pred) = @_;
    my $yt = $y_true->double;
    my $yp = $y_pred->double;
    my $ss_res = (($yt - $yp) ** 2)->sum;
    my $ss_tot = (($yt - $yt->avg) ** 2)->sum;
    return $ss_tot == 0 ? 0.0 : 1.0 - ($ss_res / $ss_tot);
}

sub cosine_similarity {
    my ($a, $b) = @_;
    my $ad = $a->double;
    my $bd = $b->double;
    my $dot = ($ad * $bd)->sumover;
    my $na  = sqrt(($ad * $ad)->sumover);
    my $nb  = sqrt(($bd * $bd)->sumover);
    my $den = $na * $nb;
    $den->where($den == 0) .= 1.0;
    my $res = $dot / $den;
    return $res->nelem == 1 ? $res->sclr : $res;
}

sub roc_auc {
    my ($y_true, $y_score) = @_;
    my $n = $y_true->nelem;
    my @pairs = sort { $b->[0] <=> $a->[0] }
        map { [ $y_score->at($_), $y_true->at($_) ? 1 : 0 ] } (0 .. $n - 1);

    my $n_pos = grep { $_->[1] == 1 } @pairs;
    my $n_neg = $n - $n_pos;
    return 0.0 if $n_pos == 0 || $n_neg == 0;

    my ($tp, $fp, $prev_tp, $prev_fp, $auc) = (0, 0, 0, 0, 0.0);
    for my $p (@pairs) {
        if ($p->[1]) { $tp++ } else { $fp++ }
        $auc += ($fp - $prev_fp) * ($tp + $prev_tp) / 2.0;
        ($prev_tp, $prev_fp) = ($tp, $fp);
    }
    return $auc / ($n_pos * $n_neg);
}

1;

__END__

=head1 NAME

PDL::ML::Metrics - Classification, regression, and similarity metrics for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::ML::Metrics qw(accuracy precision_recall_f1 confusion_matrix mse rmse mae r2_score cosine_similarity roc_auc);

    my $acc = accuracy(long([1, 0, 1]), long([1, 0, 0]));
    my ($p, $r, $f1) = precision_recall_f1(long([1, 0, 1]), long([1, 1, 1]));
    my $auc = roc_auc(long([0, 0, 1, 1]), double([0.1, 0.4, 0.35, 0.8]));

=head1 DESCRIPTION

C<PDL::ML::Metrics> provides standard classification, regression, ranking, and
vector-similarity evaluation metrics operating on L<PDL> ndarrays.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
