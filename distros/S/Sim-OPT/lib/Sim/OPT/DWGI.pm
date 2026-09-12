package Sim::OPT::DWGI;

# DWGI -- Distance-Weighted Gradient Integration.
# Experimental global-integration sibling of Sim::OPT::Interlinear / DWGN.
#
# The input representation and the initial adjacent sampled gradients follow
# Interlinear's roots.  DWGI differs at the inference stage: it does not let
# reconstructed points become parents of later reconstructed points.  Instead,
# it transports the ORIGINAL sampled gradients across homologous lattice edges
# by Interlinear-style distance weighting and solves all missing values at once
# as a weighted sparse least-squares gradient-integration problem.
#
# Sampled values are hard anchors.

use strict;
use warnings;
use Exporter 'import';
use List::Util qw(max);
use feature 'say';

use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;
use Sim::OPT::Descend;
use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;
use Sim::OPT::Parcoord3d;
use Sim::OPT::Stats;

our @EXPORT = qw(dwgi dwgistart);
our $VERSION = '0.0011';
our $ABSTRACT = 'Distance-Weighted Gradient Integration: one-shot global reconstruction of a discrete design lattice from distance-weighted sampled gradients.';

sub _sum {
    my $s = 0;
    $s += $_ for @_;
    return $s;
}

sub _preparearr {
    my @lines = @_;
    my $optformat = 'y';
    my @arr;

    return (\@arr, $optformat) unless @lines;

    my $probe = defined $lines[1] ? $lines[1] : $lines[0];
    if (defined($probe) && $probe =~ /_/) {
        foreach my $line (@lines) {
            next unless defined $line;
            chomp $line;
            my @row = split(/,/, $line, -1);
            my @pars = split(/_/, $row[0]);
            if (!defined($row[1]) || $row[1] eq '') {
                push @arr, [ $row[0], [@pars] ];
            }
            else {
                push @arr, [ $row[0], [@pars], 0 + $row[1], 1 ];
            }
        }
    }
    else {
        $optformat = 'n';
        my @widths;
        foreach my $line (@lines) {
            next unless defined $line;
            chomp $line;
            my @row = split(/,/, $line, -1);
            push @widths, scalar(@row);
        }
        my $maxnum = max(@widths);
        foreach my $line (@lines) {
            next unless defined $line;
            chomp $line;
            my @row = split(/,/, $line, -1);
            my $rightnum = $maxnum - 1;
            my @pars;
            for (my $count = 1; $count <= $rightnum; $count++) {
                push @pars, join('-', $count, $row[$count - 1]);
            }
            my $header = join('_', @pars);
            if (scalar(@row) < $maxnum || !defined($row[-1]) || $row[-1] eq '') {
                push @arr, [ $header, [@pars] ];
            }
            else {
                push @arr, [ $header, [@pars], 0 + $row[-1], 1 ];
            }
        }
    }

    return (\@arr, $optformat);
}

sub _factlevels {
    my ($arr) = @_;
    my %levels;
    foreach my $el (@$arr) {
        foreach my $bit (@{$el->[1]}) {
            my ($f, $l) = split(/-/, $bit, 2);
            next unless defined $f && defined $l;
            $levels{$f} = $l if !defined($levels{$f}) || $l > $levels{$f};
        }
    }
    return \%levels;
}

sub _stepsizes {
    my ($levels, $lvconversion) = @_;
    my %step;
    foreach my $f (sort { $a <=> $b } keys %$levels) {
        my $n = $levels->{$f};
        if ($n <= 1) {
            $step{$f} = 0;
        }
        elsif (!defined($lvconversion) || $lvconversion eq '') {
            $step{$f} = 1 / ($n - 1);
        }
        elsif ($lvconversion eq 'equal') {
            $step{$f} = 1;
        }
        else {
            $step{$f} = (0 + $lvconversion) / ($n - 1);
        }
    }
    return \%step;
}

sub _levels_for_row {
    my ($row, $factors) = @_;
    my %byf;
    foreach my $bit (@{$row->[1]}) {
        my ($f, $l) = split(/-/, $bit, 2);
        $byf{$f} = 0 + $l;
    }
    return [ map { $byf{$_} } @$factors ];
}

sub _coord_key {
    return join(',', @_);
}

sub _max_distance {
    my ($factors, $levels, $steps) = @_;
    my $s2 = 0;
    foreach my $f (@$factors) {
        my $extent = ($levels->{$f} - 1) * $steps->{$f};
        $s2 += $extent * $extent;
    }
    return sqrt($s2);
}

sub _edge_midpoint {
    my ($levs, $fi, $factors, $steps) = @_;
    my @p;
    for (my $j = 0; $j < @$factors; $j++) {
        my $f = $factors->[$j];
        my $lv = $levs->[$j];
        my $x = ($lv - 1) * $steps->{$f};
        $x += 0.5 * $steps->{$f} if $j == $fi;
        push @p, $x;
    }
    return \@p;
}

sub _distance {
    my ($a, $b) = @_;
    my $s2 = 0;
    for (my $i = 0; $i < @$a; $i++) {
        my $d = $a->[$i] - $b->[$i];
        $s2 += $d * $d;
    }
    return sqrt($s2);
}

sub _edge_bank_from_sampled {
    my ($arr, $lev_by_i, $index_by_coord, $factors, $factor_pos, $levels, $steps) = @_;
    my (%by_class, %by_factor);
    my $observed = 0;

    for (my $i = 0; $i < @$arr; $i++) {
        my $row = $arr->[$i];
        next unless defined($row->[2]) && $row->[2] ne '';
        my $levs = $lev_by_i->[$i];

        for (my $fi = 0; $fi < @$factors; $fi++) {
            my $f = $factors->[$fi];
            my $lo = $levs->[$fi];
            next if $lo >= $levels->{$f};

            my @nlev = @$levs;
            $nlev[$fi]++;
            my $j = $index_by_coord->{ _coord_key(@nlev) };
            next unless defined $j;
            my $other = $arr->[$j];
            next unless defined($other->[2]) && $other->[2] ne '';

            # Canonical positive-level direction: y(high)-y(low), per one level.
            my $grad = (0 + $other->[2]) - (0 + $row->[2]);
            my $class = join('|', $f, $lo, $lo + 1);
            my $mid = _edge_midpoint($levs, $fi, $factors, $steps);
            my $rec = {
                grad     => $grad,
                midpoint => $mid,
                factor   => $f,
                lo       => $lo,
                hi       => $lo + 1,
                from     => $row->[0],
                to       => $other->[0],
            };
            push @{$by_class{$class}}, $rec;
            push @{$by_factor{$f}}, $rec;
            $observed++;
        }
    }

    return (\%by_class, \%by_factor, $observed);
}

sub _transport_gradient {
    my ($obs, $target_mid, $maxdist, $distance_power) = @_;
    return unless $obs && @$obs;

    my ($sumw, $sumwg) = (0, 0);
    foreach my $g (@$obs) {
        my $rawdist = _distance($target_mid, $g->{midpoint});
        my $w;
        if (!$maxdist) {
            $w = 1;
        }
        else {
            my $nd = $rawdist / $maxdist;
            $nd = 1 if $nd > 1;
            $w = 1 - $nd;
        }
        $w = $w ** $distance_power if $distance_power != 1;
        next unless $w > 0;
        $sumw  += $w;
        $sumwg += $w * $g->{grad};
    }
    return unless $sumw > 0;

    my $grad = $sumwg / $sumw;
    my $confidence = $sumw / scalar(@$obs); # 0..1; count-neutral in v0.001
    return ($grad, $confidence, $sumw);
}

sub _uf_find {
    my ($parent, $x) = @_;
    my $r = $x;
    $r = $parent->[$r] while $parent->[$r] != $r;
    while ($parent->[$x] != $x) {
        my $n = $parent->[$x];
        $parent->[$x] = $r;
        $x = $n;
    }
    return $r;
}

sub _uf_union {
    my ($parent, $rank, $a, $b) = @_;
    my $ra = _uf_find($parent, $a);
    my $rb = _uf_find($parent, $b);
    return if $ra == $rb;
    if ($rank->[$ra] < $rank->[$rb]) {
        $parent->[$ra] = $rb;
    }
    elsif ($rank->[$ra] > $rank->[$rb]) {
        $parent->[$rb] = $ra;
    }
    else {
        $parent->[$rb] = $ra;
        $rank->[$ra]++;
    }
}

sub _dot {
    my ($a, $b) = @_;
    my $s = 0;
    for (my $i = 0; $i < @$a; $i++) {
        $s += $a->[$i] * $b->[$i];
    }
    return $s;
}

sub _matvec {
    my ($diag, $eu, $ev, $ew, $x) = @_;
    my @y;
    $#y = $#$diag;
    for (my $i = 0; $i < @$diag; $i++) {
        $y[$i] = $diag->[$i] * $x->[$i];
    }
    for (my $e = 0; $e < @$eu; $e++) {
        my $u = $eu->[$e];
        my $v = $ev->[$e];
        my $w = $ew->[$e];
        $y[$u] -= $w * $x->[$v];
        $y[$v] -= $w * $x->[$u];
    }
    return \@y;
}

sub _pcg {
    my ($diag, $eu, $ev, $ew, $b, $x0, $tol, $maxiter, $verbose) = @_;
    my $n = @$b;
    return ([], { iterations => 0, relres => 0, converged => 1 }) if $n == 0;

    my @x = @$x0;
    my $ax = _matvec($diag, $eu, $ev, $ew, \@x);
    my (@r, @z, @p);
    $#r = $#z = $#p = $n - 1;

    for (my $i = 0; $i < $n; $i++) {
        die "DWGI: zero/negative diagonal at unknown $i\n" unless $diag->[$i] > 0;
        $r[$i] = $b->[$i] - $ax->[$i];
        $z[$i] = $r[$i] / $diag->[$i];
        $p[$i] = $z[$i];
    }

    my $bnorm2 = _dot($b, $b);
    $bnorm2 = 1 if $bnorm2 <= 0;
    my $rz = _dot(\@r, \@z);
    my $rnorm2 = _dot(\@r, \@r);
    my $relres = sqrt($rnorm2 / $bnorm2);

    return (\@x, { iterations => 0, relres => $relres, converged => 1 }) if $relres <= $tol;

    my $iter = 0;
    for ($iter = 1; $iter <= $maxiter; $iter++) {
        my $ap = _matvec($diag, $eu, $ev, $ew, \@p);
        my $pap = _dot(\@p, $ap);
        die "DWGI: PCG breakdown (p'Ap <= 0); system may be singular\n" unless $pap > 0;
        my $alpha = $rz / $pap;

        for (my $i = 0; $i < $n; $i++) {
            $x[$i] += $alpha * $p[$i];
            $r[$i] -= $alpha * $ap->[$i];
        }

        $rnorm2 = _dot(\@r, \@r);
        $relres = sqrt($rnorm2 / $bnorm2);
        say "DWGI PCG iteration $iter relative residual $relres" if $verbose && ($iter == 1 || $iter % 25 == 0);
        last if $relres <= $tol;

        for (my $i = 0; $i < $n; $i++) {
            $z[$i] = $r[$i] / $diag->[$i];
        }
        my $rz_new = _dot(\@r, \@z);
        die "DWGI: PCG breakdown (r'M^-1r <= 0)\n" unless $rz_new > 0;
        my $beta = $rz_new / $rz;
        for (my $i = 0; $i < $n; $i++) {
            $p[$i] = $z[$i] + $beta * $p[$i];
        }
        $rz = $rz_new;
    }

    my $converged = ($relres <= $tol) ? 1 : 0;
    my $used = $iter > $maxiter ? $maxiter : $iter;
    return (\@x, { iterations => $used, relres => $relres, converged => $converged });
}

sub _printend {
    my ($arr, $newfile, $optformat) = @_;
    return unless defined($newfile) && $newfile ne '';
    open(my $fh, '>', $newfile) or die "DWGI: cannot write $newfile: $!\n";
    foreach my $entry (@$arr) {
        if ($optformat eq 'y') {
            print {$fh} $entry->[0] . ',' . $entry->[2] . "\n";
        }
        else {
            my @vals = map { (split(/-/, $_, 2))[1] } @{$entry->[1]};
            print {$fh} join(',', @vals, $entry->[2]) . "\n";
        }
    }
    close $fh;
}

sub dwgi {
    my ($sourcefile, $configf, $metafile, $blockelts_r, $reportf, $countblock,
        $dowhat_r, $dirfiles_r, $lines_r) = @_;

    my %dowhat = (ref($dowhat_r) eq 'HASH') ? %$dowhat_r : ();
    my %dirfiles = (ref($dirfiles_r) eq 'HASH') ? %$dirfiles_r : ();
    my @lines = (ref($lines_r) eq 'ARRAY') ? @$lines_r : ();

    if (!@lines) {
        if (ref($sourcefile) eq 'ARRAY') {
            @lines = @$sourcefile;
        }
        else {
            my $src = $dirfiles{precomputed} || $sourcefile;
            die "DWGI: no source data supplied\n" unless defined($src) && $src ne '';
            open(my $fh, '<', $src) or die "DWGI: cannot open $src: $!\n";
            @lines = <$fh>;
            close $fh;
        }
    }
    chomp @lines;

    my $lvconversion = exists($dowhat{lvconversion}) ? $dowhat{lvconversion} : '';
    my $distance_power = exists($dowhat{dwgi_distance_power}) ? 0 + $dowhat{dwgi_distance_power} : 1;
    my $tol = exists($dowhat{dwgi_cg_tol}) ? 0 + $dowhat{dwgi_cg_tol} : 1e-8;
    my $maxiter = exists($dowhat{dwgi_cg_maxiter}) ? 0 + $dowhat{dwgi_cg_maxiter} : 2000;
    my $verbose = exists($dowhat{dwgi_verbose}) ? $dowhat{dwgi_verbose} : 1;
    $verbose = ($verbose && $verbose ne 'n') ? 1 : 0;

    die "DWGI: dwgi_distance_power must be > 0\n" unless $distance_power > 0;
    die "DWGI: dwgi_cg_tol must be > 0\n" unless $tol > 0;
    die "DWGI: dwgi_cg_maxiter must be >= 1\n" unless $maxiter >= 1;

    say 'DWGI 0.0011 -- Distance-Weighted Gradient Integration' if $verbose;
    say 'DWGI input rows: ' . scalar(@lines) if $verbose;

    my ($arr_ref, $optformat) = _preparearr(@lines);
    my @arr = @$arr_ref;
    die "DWGI: empty design lattice\n" unless @arr;

    my $levels = _factlevels(\@arr);

    # Only dimensions with more than one lattice level are reconstruction
    # factors.  Fixed dimensions may still be present in Sim::OPT coordinate
    # labels (for example 6-1 and 7-1), but they have no adjacent edges and
    # therefore require no sampled gradient evidence.  Keeping them out of
    # the integration geometry also prevents them from being misreported as
    # unidentifiable active factors.
    my @factors = grep { $levels->{$_} > 1 }
                  sort { $a <=> $b } keys %$levels;
    my %factor_pos;
    @factor_pos{@factors} = (0 .. $#factors);
    my $steps = _stepsizes($levels, $lvconversion);
    my $maxdist = _max_distance(\@factors, $levels, $steps);

    my (@lev_by_i, %index_by_coord);
    my (@sampled, @unknown_global, @global_to_unknown);
    my ($sample_sum, $sample_n) = (0, 0);

    for (my $i = 0; $i < @arr; $i++) {
        my $levs = _levels_for_row($arr[$i], \@factors);
        $lev_by_i[$i] = $levs;
        my $ck = _coord_key(@$levs);
        die "DWGI: duplicate lattice coordinate $ck\n" if exists $index_by_coord{$ck};
        $index_by_coord{$ck} = $i;
        if (defined($arr[$i][2]) && $arr[$i][2] ne '') {
            $sampled[$i] = 1;
            $sample_sum += 0 + $arr[$i][2];
            $sample_n++;
            $global_to_unknown[$i] = -1;
        }
        else {
            $sampled[$i] = 0;
            my $u = scalar(@unknown_global);
            push @unknown_global, $i;
            $global_to_unknown[$i] = $u;
        }
    }

    die "DWGI: at least one sampled/known value is required\n" unless $sample_n;
    my $sample_mean = $sample_sum / $sample_n;

    my ($bank_by_class, $bank_by_factor, $n_observed_gradients) = _edge_bank_from_sampled(
        \@arr, \@lev_by_i, \%index_by_coord, \@factors, \%factor_pos,
        $levels, $steps
    );

    my @factors_without_gradients = grep {
        !exists($bank_by_factor->{$_}) || !@{$bank_by_factor->{$_}}
    } @factors;
    if (@factors_without_gradients) {
        die "DWGI: no original adjacent sampled gradient exists for active factor(s) " .
            join(', ', @factors_without_gradients) .
            ". A one-shot gradient field cannot identify variation along those factor(s).\n";
    }

    say "DWGI sampled anchors: $sample_n" if $verbose;
    say "DWGI original adjacent sampled gradients: $n_observed_gradients" if $verbose;
    say "DWGI exact gradient classes (factor/level-pair): " . scalar(keys %$bank_by_class) if $verbose;
    say "DWGI raw maximum lattice distance: $maxdist" if $verbose;

    my $m = scalar(@unknown_global);
    my (@diag, @rhs, @support_sum, @support_n);
    $#diag = $#rhs = $m - 1 if $m;
    for (my $u = 0; $u < $m; $u++) { $diag[$u] = 0; $rhs[$u] = 0; }
    $#support_sum = $#support_n = $#arr;
    for (my $i = 0; $i < @arr; $i++) { $support_sum[$i] = 0; $support_n[$i] = 0; }

    my (@eu, @ev, @ew);

    my ($candidate_edges, $constrained_edges, $fallback_edges) = (0, 0, 0);

    for (my $i = 0; $i < @arr; $i++) {
        my $levs = $lev_by_i[$i];
        for (my $fi = 0; $fi < @factors; $fi++) {
            my $f = $factors[$fi];
            my $lo = $levs->[$fi];
            next if $lo >= $levels->{$f};
            $candidate_edges++;

            my @nlev = @$levs;
            $nlev[$fi]++;
            my $j = $index_by_coord{ _coord_key(@nlev) };
            next unless defined $j;

            my $class = join('|', $f, $lo, $lo + 1);
            my $obs = $bank_by_class->{$class};
            if (!$obs || !@$obs) {
                # No originally sampled gradient on this exact level boundary.
                # Fall back to the original gradient component field for the same
                # factor; midpoint distance now includes displacement along the
                # factor itself as well as transverse displacement.
                $obs = $bank_by_factor->{$f};
                $fallback_edges++;
            }

            my $target_mid = _edge_midpoint($levs, $fi, \@factors, $steps);
            my ($d, $w) = _transport_gradient($obs, $target_mid, $maxdist, $distance_power);
            die "DWGI: could not transport a positive-weight gradient to edge class $class\n"
                unless defined($d) && defined($w) && $w > 0;
            $constrained_edges++;
            $support_sum[$i] += $w; $support_n[$i]++;
            $support_sum[$j] += $w; $support_n[$j]++;

            my $ui = $global_to_unknown[$i];
            my $uj = $global_to_unknown[$j];
            my $i_sample = $sampled[$i];
            my $j_sample = $sampled[$j];

            if (!$i_sample) {
                $diag[$ui] += $w;
                $rhs[$ui]  -= $w * $d;
                if ($j_sample) {
                    $rhs[$ui] += $w * (0 + $arr[$j][2]);
                }
            }
            if (!$j_sample) {
                $diag[$uj] += $w;
                $rhs[$uj]  += $w * $d;
                if ($i_sample) {
                    $rhs[$uj] += $w * (0 + $arr[$i][2]);
                }
            }
            if (!$i_sample && !$j_sample) {
                push @eu, $ui;
                push @ev, $uj;
                push @ew, $w;
            }
        }
    }

    say "DWGI full lattice edges considered: $candidate_edges" if $verbose;
    say "DWGI gradient-constrained edges: $constrained_edges" if $verbose;
    say "DWGI edges using same-factor fallback gradients: $fallback_edges" if $verbose;

    my @x0 = ($sample_mean) x $m;
    my ($x, $cg) = _pcg(\@diag, \@eu, \@ev, \@ew, \@rhs, \@x0, $tol, $maxiter, $verbose);
    say "DWGI PCG iterations: $cg->{iterations}; relative residual: $cg->{relres}; converged: $cg->{converged}" if $verbose;
    die "DWGI: global integration did not converge within $maxiter PCG iterations (relative residual $cg->{relres})\n"
        unless $cg->{converged};

    for (my $u = 0; $u < $m; $u++) {
        my $gi = $unknown_global[$u];
        my $support = $support_n[$gi] ? $support_sum[$gi] / $support_n[$gi] : 0;
        $support = 1 if $support > 1;
        $arr[$gi][2] = $x->[$u];
        $arr[$gi][3] = $support;
    }
    for (my $i = 0; $i < @arr; $i++) {
        $arr[$i][3] = 1 if $sampled[$i];
    }

    my $newfile;
    if (defined($metafile) && $metafile ne '') {
        $newfile = $metafile;
    }
    elsif (defined($sourcefile) && !ref($sourcefile) && $sourcefile ne '') {
        $newfile = $sourcefile . '_dwgi_meta.csv';
    }
    _printend(\@arr, $newfile, $optformat) if defined $newfile;

    my @newarr;
    foreach my $lin (@arr) {
        push @newarr, join(',', $lin->[0], $lin->[2]);
    }

    my $report = {
        schema                    => 'dwgi-report-1',
        version                   => $VERSION,
        lattice_points            => scalar(@arr),
        sampled_anchors           => $sample_n,
        unknown_points            => $m,
        original_sampled_gradients=> $n_observed_gradients,
        gradient_classes          => scalar(keys %$bank_by_class),
        candidate_edges           => $candidate_edges,
        constrained_edges         => $constrained_edges,
        fallback_edges            => $fallback_edges,
        pcg_iterations             => $cg->{iterations},
        pcg_relative_residual      => $cg->{relres},
        pcg_converged              => $cg->{converged},
    };

    return (\@arr, \@newarr, $report);
}

sub dwgistart {
    say "DWGI -- Distance-Weighted Gradient Integration";
    say "Name of a CSV lattice file:";
    chomp(my $sourcefile = <STDIN>);
    die "DWGI: file not found: $sourcefile\n" unless -e $sourcefile;
    my ($arr, $lines, $report) = dwgi($sourcefile, '', '', '', '', 0, {}, {}, []);
    say "DWGI reconstructed " . scalar(@$arr) . " lattice points.";
    return ($arr, $lines, $report);
}

if (@ARGV) {
    if ($ARGV[0] eq 'dwgistart') {
        dwgistart();
    }
    elsif ($ARGV[0] eq '.') {
        my $src = $ARGV[1] // die "usage: perl DWGI.pm . source.csv [output.csv]\n";
        my $out = $ARGV[2] // ($src . '_dwgi_meta.csv');
        dwgi($src, '', $out, '', '', 0, {}, {}, []);
    }
}

1;

__END__

=head1 NAME

Sim::OPT::DWGI - Distance-Weighted Gradient Integration

=head1 DESCRIPTION

DWGI is an experimental one-shot sibling of Interlinear/DWGN.  It keeps the
finite discrete design lattice and the initial adjacent sampled gradients, but
replaces generational nearest-neighbour propagation with a global weighted
least-squares integration.

For each adjacent lattice edge u->v, DWGI estimates a desired increment d_uv
from ORIGINAL sampled gradients belonging to the same factor/level pair.  The
gradients are averaged with Interlinear-like linear distance strength
w = 1 - distance/max_distance.  All missing scalar values are then obtained
simultaneously by minimizing

    sum_edges w_uv * ((y_v - y_u) - d_uv)^2

with every sampled y fixed exactly.  The normal equations are a sparse weighted
graph Laplacian and are solved by Jacobi-preconditioned conjugate gradients.

No reconstructed DWGI value is ever used to create another gradient.

=head1 INTERFACE

    my ($arr_ref, $lines_ref, $report) = Sim::OPT::DWGI::dwgi(
        $sourcefile, $configfile, $metafile, $blockelts_ref, $reportfile,
        $countblock, $dowhat_ref, $dirfiles_ref, $lines_ref
    );

The argument shape intentionally mirrors Interlinear so that integration into
Sim::OPT can be tested with minimal plumbing.

Optional C<$dowhat_ref> controls introduced by DWGI:

    dwgi_distance_power => 1       # 1 preserves linear distance strength
    dwgi_cg_tol         => 1e-8
    dwgi_cg_maxiter     => 2000
    dwgi_verbose        => 1

C<lvconversion> is also honored.

=head1 IMPORTANT V0.0011 RULE

DWGI 0.0011 uses the same hierarchical transport rule as 0.001.  The 0.0011 bug-fix excludes one-level fixed dimensions from the active reconstruction-factor set.

DWGI uses a hierarchical transport rule.  For a target lattice edge it
first uses original sampled gradients from the same factor AND the same adjacent
level pair, preserving the strongest DWGN correspondence.  If that exact class
was not sampled initially, it falls back to all ORIGINAL gradients of the same
factor and weights them by full edge-midpoint distance.  Reconstructed values
never enter this gradient bank.  If an active factor has no original sampled
adjacent gradient at all, DWGI stops rather than inventing variation along it.

Derived point strength (array element 3) is a local DWGI support score: the
mean confidence of incident transported-gradient constraints.  It is NOT the
same quantity as generational DWGN strength and should not be compared as such.

DWGI 0.0011 — Distance-Weighted Gradient Integration

DWGI is an experimental one-shot sibling of Interlinear/DWGN.

It deliberately preserves the roots of DWGN — a complete discrete factorial lattice, sampled scalar values, adjacent directional gradients, normalized geometric distance, and confidence weighting — while replacing generational propagation with one global integration.

Mathematical definition

For every adjacent lattice edge u -> v, DWGI constructs a desired scalar increment d_uv from original sampled gradients only. It then solves

minimize  sum_edges w_uv * ((y_v - y_u) - d_uv)^2

with every actually sampled y held fixed exactly.

The normal equations are a sparse weighted graph Laplacian. Version 0.0011 solves them with the same pure-Perl Jacobi-preconditioned conjugate-gradient solver as 0.001.

No reconstructed point is ever used to create another gradient.

Gradient transport rule

For an edge along factor f between adjacent levels k and k+1:

If original sampled gradients exist for exactly (f,k,k+1), only those gradients are used.

Otherwise, all original sampled gradients for factor f are eligible.

Eligible gradients are averaged with linear Interlinear-like distance strength 1 - distance/max_distance, measured between gradient-edge midpoints.

A factor is active only when its lattice has more than one level. Fixed one-level factors are ignored by the integration geometry and require no gradient evidence. If an active factor has no original adjacent sampled gradient at all, DWGI stops: variation along that factor is not identifiable from the initial gradient evidence.

This hierarchical rule preserves the strongest DWGN level-pair correspondence where it exists while still permitting a complete one-shot field when sparse acquisition omitted some exact level boundaries.

Sim::OPT-shaped interface

my ($arr_ref, $lines_ref, $report) = Sim::OPT::DWGI::dwgi(
    $sourcefile, $configfile, $metafile, $blockelts_ref, $reportfile,
    $countblock, $dowhat_ref, $dirfiles_ref, $lines_ref
);

The argument shape mirrors Sim::OPT::Interlinear::interlinear() intentionally.

New optional dowhat keys:

canon                  => 'dwgi'    # select DWGI through Sim::OPT::Metabridge
dwgi_distance_power   => 1
dwgi_cg_tol           => 1e-8
dwgi_cg_maxiter       => 2000
dwgi_verbose          => 1

DWGN remains the default.  Select DWGI with canon => 'dwgi'; Sim::OPT::Metabridge performs the dispatch without requiring OPTcue.

Qualification performed here

5x5 linear field, two-axis central star: maximum error ~1.8e-15; 3 PCG iterations.

5x5x5 separable quadratic, three-axis central star: maximum error ~1.6e-9 at a 1e-10 solver tolerance; sampled-anchor error exactly zero.

Interaction field: sampled anchors remain exact while the reconstructed field shows the expected approximation error, demonstrating that the solver is genuinely reconciling an imperfect transported gradient field rather than reproducing a trivial analytic formula.

Partial factor/level coverage: same-factor fallback exercised and a linear field reconstructed to numerical precision.

Missing all gradient evidence for an active factor: explicit identifiability failure.

A synthetic production-shape lattice of 9 x 11 x 11 x 19 x 17 = 351,747 points was also exercised. The prototype built all 1,616,494 edge constraints successfully. Ten PCG iterations plus setup took about 25 seconds in the test container and peaked at about 1.1 GB RSS. The residual after 10 iterations was ~0.628 and after 25 iterations ~0.191 in a deliberately demanding large synthetic solve. A complete 351,747-point convergence run has not yet been qualified here, so version 0.001 should be treated as research code, not a replacement for production DWGN.

Derived-point support

For API compatibility, arr->[3] is populated. Sampled points retain strength 1; reconstructed points receive the mean confidence of their incident transported-gradient constraints. This is a DWGI support score, not DWGN generational strength and should not be compared numerically with it.

Installation

Install the module only:

cp lib/Sim/OPT/DWGI.pm $HOME/Sim-OPT/lib/Sim/OPT/DWGI.pm

The optional experimental Descend hook is provided separately under experimental/. Do not install it over a production Descend without first preserving the current file. Its only functional change is a soft-coded engine selector around the existing Interlinear call.

First scientific comparison recommended

Run DWGN and DWGI from the same prepared sparse lattice and compare:

sampled anchors (must be identical);

reconstructed objective landscape;

incumbent/ranking changes;

holdout error where real simulated values are available;

wall-clock and memory;

DWGI gradient residuals and PCG convergence.

The point of v0.001 is not to prove that global integration is superior. It is to create the cleanest possible experiment separating iterative gradient propagation from simultaneous gradient integration.

=cut
