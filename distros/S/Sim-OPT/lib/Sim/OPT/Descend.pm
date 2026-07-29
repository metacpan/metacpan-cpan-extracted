package Sim::OPT::Descend;
# This is the module Sim::OPT::Descend of Sim::OPT, a program for detailed metadesign managing parametric explorations, distributed under a dual licence, open-source (GPL v3) and proprietary.
# Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is proprietary. The open-source, GPL version of it can be found at https://metacpan.org/dist/Sim-OPT.

use Math::Trig;
use Math::Round;
use List::Util qw[ min max reduce shuffle];
use List::MoreUtils qw(uniq);
use List::AllUtils qw(sum);
use Sim::OPT::Stats qw(:all);
use Set::Intersection;
use Storable qw(lock_store lock_nstore lock_retrieve dclone);
use Data::Dump qw(dump);
use Data::Dumper;
use IO::Tee;
use feature 'say';
use Switch::Back;

use Sim::OPT;
use Sim::OPT::Morph;
use Sim::OPT::Sim;
use Sim::OPT::Report;

use Sim::OPT::Takechance;
use Sim::OPT::Interlinear;
use Sim::OPT::Parcoord3d;
use Sim::OPT::Stats;
eval { use Sim::OPTcue::OPTcue; 1 };
eval { use Sim::OPTcue::Metabridge; 1 };
eval { use Sim::OPTcue::Exogen::PatternSearch; 1 };
eval { use Sim::OPTcue::Exogen::NelderMead; 1 };
eval { use Sim::OPTcue::Exogen::Armijo; 1 };
eval { use Sim::OPTcue::Exogen::NSGAII; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::SimulatedAnnealing; 1 };
eval { use Sim::OPTcue::Exogen::NSGAIII; 1 };
eval { use Sim::OPTcue::Exogen::MOEAD; 1 };
eval { use Sim::OPTcue::Exogen::SPEA2; 1 };
eval { use Sim::OPTcue::Exogen::ParticleSwarm; 1 };
eval { use Sim::OPTcue::Exogen::RadialBasis; 1 };
eval { use Sim::OPTcue::Exogen::Kriging; 1 };
eval { use Sim::OPTcue::Exogen::DecisionTree; 1 };
eval { use Sim::OPTcue::Exogen::KNN; 1 };
eval { use Sim::OPTcue::Exogen::FFNN; 1 };
eval { use Sim::OPTcue::Exogen::GBDT; 1 };
eval { use Sim::OPTcue::Endogen::DWGN2; 1 };
eval { use Sim::OPTcue::Endogen::NeuralBoltzmann; 1 };


$Data::Dumper::Indent = 0;
$Data::Dumper::Useqq  = 1;
$Data::Dumper::Terse  = 1;

no strict;
no warnings;

@ISA = qw(Exporter); # our @adamkISA = qw(Exporter);
%EXPORT_TAGS = ( DEFAULT => [qw( &opt &prepare )]); # our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#@EXPORT   = qw(); # our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( descend prepareblank tee ); # our @EXPORT = qw( );

$VERSION = '0.181'; # our $VERSION = '';
$ABSTRACT = 'Sim::OPT::Descent is an module collaborating with the Sim::OPT module for performing block coordinate descent.';

#########################################################################################
# HERE FOLLOWS THE CONTENT OF "Descend.pm" - Sim::OPT::Descend
##############################################################################



sub fundamentality_indices
{
  my ($args_r) = @_;
  my %args = %$args_r;

  my $file      = $args{file}      or die "Missing argument: file\n";
  my $outdir    = $args{outdir}    || ".";
  my $instcol   = $args{instcol}   || 1;
  my $ycol      = $args{ycol}      || 3;
  my $metric    = $args{metric};
  my $metriccol = $args{metriccol} || 2;
  my $sep       = defined($args{sep}) ? $args{sep} : ",";
  my $header    = $args{header}    || 0;
  my $quiet     = $args{quiet}     || 0;
  my $fundnum   = $args{fundamentalitynum};

  my $ordinary_file = $args{ordinary_sensitivity_file}
                   || $args{sensitivity_file}
                   || $args{ordinary_file};

  my ( $fund_rows_r, $vars_r, $fund_skipped ) = fund_read_totres_rows(
    $file,
    {
      instcol   => $instcol,
      ycol      => $ycol,
      metric    => $metric,
      metriccol => $metriccol,
      sep       => $sep,
      header    => $header,
      quiet     => $quiet,
    }
  );

  my @rows      = @$fund_rows_r;
  my @vars      = @$vars_r;
  my $n_skipped = $fund_skipped;

  die "No complete fundamentality rows found in $file\n" unless @rows;

  my @sens_rows;
  my $sens_rows_skipped = 0;

  if ( defined($ordinary_file) && $ordinary_file ne "" && -e $ordinary_file )
  {
    my ( $sens_rows_r, $sens_vars_r, $sens_skipped ) = fund_read_totres_rows(
      $ordinary_file,
      {
        instcol       => $instcol,
        ycol          => $ycol,
        metric        => $metric,
        metriccol     => $metriccol,
        sep           => $sep,
        header        => $header,
        quiet         => $quiet,
        required_vars => \@vars,
        require_sensvar => 1,
      }
    );

    @sens_rows = @$sens_rows_r;
    $sens_rows_skipped = $sens_skipped;
    $n_skipped += $sens_skipped;
  }
  elsif ( defined($ordinary_file) && $ordinary_file ne "" )
  {
    warn "Ordinary sensitivity file was requested but not found: $ordinary_file\n"
      unless $quiet;
  }
  else
  {
    warn "No ordinary_sensitivity_file supplied. sensitivities.csv and relfund.csv will not contain ordinary sensitivities.\n"
      unless $quiet;
  }

  my %absolute;
  my %abs_rows_used;
  my %abs_rows_requested;
  my %ordinary;
  my %sens_rows_used;
  my %sens_rows_requested;

  for my $v ( @vars )
  {
    my @subrows = grep {
      defined($_->{order}[0]) && $_->{order}[0] == $v
    } @rows;

    $abs_rows_used{$v} = scalar @subrows;
    my @levels = fund_levels_for_var( \@rows, $v );
    $abs_rows_requested{$v} = ( defined($fundnum) && $fundnum ne "" )
                            ? scalar(@levels) * $fundnum
                            : "";

    if ( !@subrows )
    {
      $absolute{$v} = undef;
    }
    else
    {
      my $abs_r = fund_onevar_sensitivity( \@subrows, $v );
      $absolute{$v} = $abs_r->{sensitivity};
    }

    if ( @sens_rows )
    {
      my @sens_subrows = grep {
        defined($_->{sensvar}) && $_->{sensvar} == $v
      } @sens_rows;

      $sens_rows_used{$v} = scalar @sens_subrows;
      $sens_rows_requested{$v} = $abs_rows_requested{$v};

      if ( @sens_subrows )
      {
        my $sens_r = fund_onevar_sensitivity( \@sens_subrows, $v );
        $ordinary{$v}{sensitivity} = $sens_r->{sensitivity};
      }
      else
      {
        $ordinary{$v}{sensitivity} = undef;
      }
    }
    else
    {
      $sens_rows_used{$v} = 0;
      $sens_rows_requested{$v} = $abs_rows_requested{$v};
      $ordinary{$v}{sensitivity} = undef;
    }
  }

  my $abs_file  = "$outdir/absfund.csv";
  my $sens_file = "$outdir/sensitivities.csv";
  my $rel_file  = "$outdir/relfund.csv";

  open my $ABS, ">", $abs_file or die "Cannot write $abs_file: $!\n";
  print $ABS "Variable,Absolute_fundamentality,Rows_used_first_position,Rows_requested\n";
  for my $v ( @vars )
  {
    my $a = defined($absolute{$v}) ? $absolute{$v} : "";
    my $n = $abs_rows_used{$v} || 0;
    my $q = defined($abs_rows_requested{$v}) ? $abs_rows_requested{$v} : "";
    print $ABS "X$v,$a,$n,$q\n";
  }
  close $ABS;

  open my $SENS, ">", $sens_file or die "Cannot write $sens_file: $!\n";
  print $SENS "Variable,Sensitivity,Rows_used_ordinary_sample,Rows_requested,Ordinary_sample_file\n";
  for my $v ( @vars )
  {
    my $s = defined($ordinary{$v}{sensitivity}) ? $ordinary{$v}{sensitivity} : "";
    my $n = $sens_rows_used{$v} || 0;
    my $q = defined($sens_rows_requested{$v}) ? $sens_rows_requested{$v} : "";
    my $of = defined($ordinary_file) ? $ordinary_file : "";
    print $SENS "X$v,$s,$n,$q,$of\n";
  }
  close $SENS;

  open my $REL, ">", $rel_file or die "Cannot write $rel_file: $!\n";
  print $REL "Variable,Absolute_fundamentality,Ordinary_sensitivity,Relative_fundamentality,Rows_used_first_position,Rows_used_ordinary_sample\n";
  for my $v ( @vars )
  {
    my $a = $absolute{$v};
    my $s = $ordinary{$v}{sensitivity};

    my $rel = "";

    if ( defined($a) && defined($s) && fund_is_number($a) && fund_is_number($s) && $s != 0 )
    {
      $rel = ( $a - $s ) / $s;
    }

    $a = "" unless defined $a;
    $s = "" unless defined $s;

    my $an = $abs_rows_used{$v} || 0;
    my $sn = $sens_rows_used{$v} || 0;

    print $REL "X$v,$a,$s,$rel,$an,$sn\n";
  }
  close $REL;

  return({
    absfund_file       => $abs_file,
    sensitivities_file => $sens_file,
    relfund_file       => $rel_file,
    ordinary_sensitivity_file => $ordinary_file,
    rows_used          => scalar(@rows),
    ordinary_rows_used => scalar(@sens_rows),
    rows_skipped       => $n_skipped,
    fundamentality_rows_skipped => $fund_skipped,
    ordinary_rows_skipped => $sens_rows_skipped,
    variables          => \@vars,
  });
}


sub fund_read_totres_rows
{
  my ( $file, $opts_r ) = @_;
  my %opts = %{ $opts_r || {} };

  my $instcol   = $opts{instcol}   || 1;
  my $ycol      = $opts{ycol}      || 3;
  my $metric    = $opts{metric};
  my $metriccol = $opts{metriccol} || 2;
  my $sep       = defined($opts{sep}) ? $opts{sep} : ",";
  my $header    = $opts{header}    || 0;
  my $quiet     = $opts{quiet}     || 0;
  my @required_vars = @{ $opts{required_vars} || [] };
  my $require_sensvar = $opts{require_sensvar} || 0;

  open my $fh, "<", $file or die "Cannot open $file: $!\n";

  my $line_no = 0;
  if ( $header )
  {
    <$fh>;
    $line_no++;
  }

  my @raw_rows;
  my %var_seen;
  my $n_skipped = 0;

  while ( my $line = <$fh> )
  {
    $line_no++;
    chomp $line;
    $line =~ s/\r\z//;
    next if $line =~ /^\s*$/;

    my @f = fund_parse_csv_line( $line, $sep );

    if ( defined $metric )
    {
      next if !defined $f[$metriccol - 1];
      next if $f[$metriccol - 1] ne $metric;
    }

    my $instname = $f[$instcol - 1];
    my $y        = $f[$ycol - 1];

    if ( !defined($instname) || !defined($y) || !fund_is_number($y) )
    {
      warn "Skipping line $line_no in $file: missing instance name or non-numeric Y\n"
        unless $quiet;
      $n_skipped++;
      next;
    }

    my ( $x_r, $order_r ) = fund_parse_instance_ordered( $instname );
    my %x     = %$x_r;
    my @order = @$order_r;

    if ( !%x || !@order )
    {
      warn "Skipping line $line_no in $file: cannot parse instance '$instname'\n"
        unless $quiet;
      $n_skipped++;
      next;
    }

    my $sensvar;
    for ( my $i = 0; $i < $#f; $i++ )
    {
      if ( defined($f[$i]) && $f[$i] eq "sensvar" )
      {
        $sensvar = $f[$i + 1];
        last;
      }
    }

    if ( $require_sensvar && ( !defined($sensvar) || !fund_is_number($sensvar) ) )
    {
      warn "Skipping line $line_no in $file: ordinary sensitivity row lacks sensvar tag\n"
        unless $quiet;
      $n_skipped++;
      next;
    }

    for my $v ( keys %x )
    {
      $var_seen{$v} = 1;
    }

    push @raw_rows, {
      instance => $instname,
      x        => \%x,
      order    => \@order,
      y        => 0 + $y,
      sensvar  => defined($sensvar) ? 0 + $sensvar : undef,
      line     => $line_no,
    };
  }

  close $fh;

  die "No usable rows found in $file\n" unless @raw_rows;

  my @vars = @required_vars ? @required_vars : sort { $a <=> $b } keys %var_seen;
  my @rows;

  ROW:
  for my $r ( @raw_rows )
  {
    for my $v ( @vars )
    {
      if ( !exists $r->{x}{$v} )
      {
        warn "Skipping line $r->{line} in $file: missing variable $v\n" unless $quiet;
        $n_skipped++;
        next ROW;
      }
    }

    push @rows, $r;
  }

  die "No complete rows left after variable consistency check in $file\n" unless @rows;

  return( \@rows, \@vars, $n_skipped );
}


sub fund_levels_for_var
{
  my ( $rows_r, $var ) = @_;
  my %seen;

  for my $r ( @$rows_r )
  {
    next unless exists $r->{x}{$var};
    $seen{ $r->{x}{$var} } = 1;
  }

  return fund_sort_levels( keys %seen );
}


sub fund_onevar_sensitivity
{
  my ( $rows_r, $var ) = @_;
  my @rows = grep { exists $_->{x}{$var} } @$rows_r;

  return({ sensitivity => undef, rows_used => 0, nlevels => 0 }) unless @rows;

  my %groups;
  my @y;

  for my $r ( @rows )
  {
    push @{ $groups{ $r->{x}{$var} } }, $r->{y};
    push @y, $r->{y};
  }

  my @levels = fund_sort_levels( keys %groups );
  return({ sensitivity => undef, rows_used => scalar(@rows), nlevels => scalar(@levels) })
    if scalar(@levels) < 2;

  my $grand = fund_mean( \@y );
  my $sst = 0.0;
  for my $yy ( @y )
  {
    $sst += ( $yy - $grand ) ** 2;
  }

  if ( $sst <= 0 )
  {
    return({ sensitivity => "NA", rows_used => scalar(@rows), nlevels => scalar(@levels), levels => join("|", @levels) });
  }

  my $ss_between = 0.0;
  for my $lev ( @levels )
  {
    my @gy = @{ $groups{$lev} };
    my $m = fund_mean( \@gy );
    $ss_between += scalar(@gy) * ( $m - $grand ) ** 2;
  }

  my $sens = $ss_between / $sst;

  return({
    sensitivity => $sens,
    rows_used   => scalar(@rows),
    nlevels     => scalar(@levels),
    levels      => join("|", @levels),
    ss_between  => $ss_between,
    sst         => $sst,
  });
}


sub fund_anova_main_effects
{
  my ( $rows_r, $vars_r ) = @_;

  my @rows = @$rows_r;
  my @vars = @$vars_r;

  my @y = map { $_->{y} } @rows;

  my %level_seen;

  for my $r ( @rows )
  {
    for my $v ( @vars )
    {
      $level_seen{$v}{ $r->{x}{$v} } = 1;
    }
  }

  my @levels;

  for my $j ( 0 .. $#vars )
  {
    my $v = $vars[$j];
    my @lev = fund_sort_levels( keys %{ $level_seen{$v} || {} } );

    die "Variable $v has no observed levels in ANOVA subset\n" unless @lev;

    $levels[$j] = \@lev;
  }

  my @col_var_index;
  my @col_level;

  push @col_var_index, undef;
  push @col_level, undef;

  for my $j ( 0 .. $#vars )
  {
    my @lev = @{ $levels[$j] };

    for my $m ( 1 .. $#lev )
    {
      push @col_var_index, $j;
      push @col_level, $lev[$m];
    }
  }

  my @X;

  for my $r ( @rows )
  {
    my @xr = (1.0);

    for my $j ( 0 .. $#vars )
    {
      my $v   = $vars[$j];
      my @lev = @{ $levels[$j] };

      for my $m ( 1 .. $#lev )
      {
        push @xr, ( $r->{x}{$v} eq $lev[$m] ) ? 1.0 : 0.0;
      }
    }

    push @X, \@xr;
  }

  my $mean_y = fund_mean( \@y );

  my $sst = 0.0;
  for my $v ( @y )
  {
    $sst += ( $v - $mean_y ) ** 2;
  }

  






  if ( $sst <= 0 )
	{
	  my %out;

	  for my $j ( 0 .. $#vars )
	  {
	    my $v = $vars[$j];

	    $out{$v} = {
	      var          => $v,
	      nlevels      => scalar @{ $levels[$j] },
	      levels       => join( "|", @{ $levels[$j] } ),
	      ref_level    => $levels[$j][0],
	      df           => 0,
	      ss           => 0,
	      sensitivity  => "NA",
	      partial_eta2 => "NA",
	      f            => "NA",
	      p            => "NA",
	    };
	  }

	  return( \%out );
	}






  my @all_cols = ( 0 .. $#col_var_index );

  my ( $sse_full, $rank_full ) =
    fund_sse_for_cols( \@X, \@y, \@all_cols );

  my $n = scalar @y;
  my $df_error = $n - $rank_full;

  die "No residual degrees of freedom. Rows=$n, model_rank=$rank_full\n"
    if $df_error <= 0;

  my $mse_error = $sse_full / $df_error;

  my %out;

  for my $j ( 0 .. $#vars )
  {
    my @reduced_cols = grep {
      !defined($col_var_index[$_]) || $col_var_index[$_] != $j
    } @all_cols;

    my ( $sse_reduced, $rank_reduced ) =
      fund_sse_for_cols( \@X, \@y, \@reduced_cols );

    my $df = $rank_full - $rank_reduced;
    my $ss = $sse_reduced - $sse_full;

    $ss = 0 if $ss < 0 && abs($ss) < 1e-7;

    my $sensitivity  = $ss / $sst;
    my $partial_eta2 = ( $ss + $sse_full ) > 0
                     ? $ss / ( $ss + $sse_full )
                     : 0;

    my $fstat = ( $df > 0 && $mse_error > 0 )
              ? ( $ss / $df ) / $mse_error
              : 0;

    $out{ $vars[$j] } = {
      var          => $vars[$j],
      nlevels      => scalar @{ $levels[$j] },
      levels       => join( "|", @{ $levels[$j] } ),
      ref_level    => $levels[$j][0],
      df           => $df,
      ss           => $ss,
      sensitivity  => $sensitivity,
      partial_eta2 => $partial_eta2,
      fstat        => $fstat,
    };
  }

  return \%out;
}


sub fund_parse_instance_ordered
{
  my ($s) = @_;

  $s =~ s/\r\z//;
  $s =~ s/^.*[\\\/]//;
  $s =~ s/\.csv\z//i;

  my ($left) = split /__/, $s, 2;

  my %x;
  my @order;

  for my $part ( split /_/, $left )
  {
    next if !defined($part) || $part eq "";

    if ( $part =~ /^\s*(\d+)\s*-\s*([^_]+?)\s*\z/ )
    {
      my ( $var, $lev ) = ( $1, $2 );
      $var = 0 + $var;

      $x{$var} = $lev;
      push @order, $var;
    }
  }

  return( \%x, \@order );
}


sub fund_parse_csv_line
{
  my ( $line, $sep ) = @_;

  chomp $line if defined $line;
  $line =~ s/\r\z// if defined $line;

  if ( $line !~ /"/ )
  {
    return split /\Q$sep\E/, $line, -1;
  }

  my @fields;
  my $field = "";
  my $in_quotes = 0;
  my @chars = split //, $line;

  for ( my $i = 0; $i < @chars; $i++ )
  {
    my $c = $chars[$i];

    if ( $in_quotes )
    {
      if ( $c eq '"' )
      {
        if ( $i + 1 < @chars && $chars[$i + 1] eq '"' )
        {
          $field .= '"';
          $i++;
        }
        else
        {
          $in_quotes = 0;
        }
      }
      else
      {
        $field .= $c;
      }
    }
    else
    {
      if ( $c eq '"' )
      {
        $in_quotes = 1;
      }
      elsif ( $c eq $sep )
      {
        push @fields, $field;
        $field = "";
      }
      else
      {
        $field .= $c;
      }
    }
  }

  push @fields, $field;

  return @fields;
}



sub fund_is_number
{
  my ($x) = @_;

  return defined($x)
      && $x =~ /^\s*[-+]?(?:(?:\d+(?:\.\d*)?)|(?:\.\d+))(?:[eE][-+]?\d+)?\s*\z/;
}



sub fund_sort_levels
{
  my @v = @_;

  my $all_numeric = 1;

  for my $x ( @v )
  {
    if ( !fund_is_number($x) )
    {
      $all_numeric = 0;
      last;
    }
  }

  return $all_numeric ? sort { $a <=> $b } @v : sort @v;
}



sub fund_mean
{
  my ($a) = @_;

  my $s = 0.0;
  $s += $_ for @$a;

  return $s / @$a;
}


sub fund_sse_for_cols
{
  my ( $X, $y, $cols ) = @_;

  my $n = scalar @$y;
  my $p = scalar @$cols;

  my @xtx = map { [(0.0) x $p] } 1 .. $p;
  my @xty = (0.0) x $p;
  my $yty = 0.0;

  for my $r ( 0 .. $n - 1 )
  {
    my $yr = $y->[$r];

    $yty += $yr * $yr;

    for my $a ( 0 .. $p - 1 )
    {
      my $xa = $X->[$r][ $cols->[$a] ];

      $xty[$a] += $xa * $yr;

      for my $b ( 0 .. $a )
      {
        my $xb = $X->[$r][ $cols->[$b] ];
        $xtx[$a][$b] += $xa * $xb;
      }
    }
  }

  for my $a ( 0 .. $p - 1 )
  {
    for my $b ( $a + 1 .. $p - 1 )
    {
      $xtx[$a][$b] = $xtx[$b][$a];
    }
  }

  my ( $beta, $rank ) = fund_solve_linear_system( \@xtx, \@xty );

  my $explained = 0.0;

  for my $i ( 0 .. $p - 1 )
  {
    $explained += $beta->[$i] * $xty[$i];
  }

  my $sse = $yty - $explained;

  $sse = 0 if $sse < 0 && abs($sse) < 1e-7;

  return( $sse, $rank );
}



sub fund_solve_linear_system
{
  my ( $Ain, $bin ) = @_;

  my $n = scalar @$bin;

  my @A = map { [ @$_ ] } @$Ain;
  my @b = @$bin;

  my @where = (-1) x $n;
  my $rank = 0;
  my $eps = 1e-10;

  for my $col ( 0 .. $n - 1 )
  {
    my $sel = $rank;

    for my $i ( $rank .. $n - 1 )
    {
      $sel = $i if abs($A[$i][$col]) > abs($A[$sel][$col]);
    }

    next if abs($A[$sel][$col]) < $eps;

    if ( $sel != $rank )
    {
      @A[$sel, $rank] = @A[$rank, $sel];
      @b[$sel, $rank] = @b[$rank, $sel];
    }

    my $pivot = $A[$rank][$col];

    for my $j ( $col .. $n - 1 )
    {
      $A[$rank][$j] /= $pivot;
    }

    $b[$rank] /= $pivot;

    for my $i ( 0 .. $n - 1 )
    {
      next if $i == $rank;

      my $factor = $A[$i][$col];

      next if abs($factor) < $eps;

      for my $j ( $col .. $n - 1 )
      {
        $A[$i][$j] -= $factor * $A[$rank][$j];
      }

      $b[$i] -= $factor * $b[$rank];
    }

    $where[$col] = $rank;
    $rank++;
  }

  my @x = (0.0) x $n;

  for my $j ( 0 .. $n - 1 )
  {
    $x[$j] = $b[ $where[$j] ] if $where[$j] != -1;
  }

  return( \@x, $rank );
}




sub odd
{
    my $number = shift;
    return !even ($number);
}

sub even
{
    my $number = abs shift;
    return 1 if $number == 0;
    return odd ($number - 1);
}


sub auto_objcol {
  my ($arr_r) = @_;
  my $c = 0;

  foreach my $line ( @$arr_r ) 
  {
    chomp $line;
    my @f = split(/,/, $line, -1);  # -1 keeps empties (safe with ,,)

    for my $i (0 .. $#f) 
    {
      my $v = $f[$i];
      if (defined $v && $v =~ /^\s*[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?\s*$/) 
      {
        $c = $i;  # last numeric on the line
      }
    }
  }
  return $c;
}


sub auto_objcol_file 
{
  my ( $file ) = @_;
  open( my $FH, '<', $file ) or die "Cannot open $file: $!";
  my $line = <$FH>;
  close $FH;

  unless ( defined( $line ) )
  {
    return( 0 ); 
  }
  chomp $line;
  my @f = split( /,/, $line );

  my $c = 0;
  for my $i (0 .. $#f) {
    my $v = $f[$i];
    # numeric? (integer/float/scientific)
    if ( defined ( $v ) and ( $v =~ /^\s*[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?\s*$/ ) )
    {
      $c = $i;
    }
  } #say  "!!! OBJECTIVECOLUMN: $c";
  return( $c );
}



sub descend
{
  my $configfile = $main::configfile;
  my %vals = %main::vals;

  my $mypath = $main::mypath;
  my $exeonfiles = $main::exeonfiles;
  my $generatechance = $main::generatechance;
  my $file = $main::file;
  my $preventsim = $main::preventsim;
  my $fileconfig = $main::fileconfig;
  my $outfile = $main::outfile;
  my $tofile = $main::tofile;
  my $report = $main::report;
  my $simnetwork = $main::simnetwork;

  #say  "\n#Now in Sim::OPT::Descend.\n";

  my %simtitles = %main::simtitles;
  my %retrievedata = %main::retrievedata;
  my @keepcolumns = @main::keepcolumns;
  my @weights = @main::weights;
  my @weighttransforms = @main::weighttransforms;
  my @weightsaim = @main::weightsaim;
  my @varthemes_report = @main::varthemes_report;
  my @varthemes_variations = @vmain::arthemes_variations;
  my @varthemes_steps = @main::varthemes_steps;
  my @rankdata = @main::rankdata; # CUT
  my @rankcolumn = @main::rankcolumn;
  my %reportdata = %main::reportdata;
  my @report_loadsortemps = @main::report_loadsortemps;
  my @files_to_filter = @main::files_to_filter;
  my @filter_reports = @main::filter_reports;
  my @base_columns = @main::base_columns;
  my @maketabledata = @main::maketabledata;
  my @filter_columns = @main::filter_columns;
  my %vals = %main::vals;

  my %dt = %{ $_[0] };  #say "IN DESCEND, ARRIVED " . dump( \%dt );

  my @instances = @{ $dt{instances} }; #say  "HERE IN DESCEND \@instances: " . dump( @instances );
  my %dirfiles = %{ $dt{dirfiles} }; #say  "HERE IN DESCEND \%dirfiles: " . dump( \%dirfiles );
  my %vehicles = %{ $dt{vehicles} }; #say  "HERE IN DESCEND \%vehicles: " . dump( \%vehicles );
  my %winhash = %{ $dt{winhash} }; #say  "HERE IN DESCEND \%winhash: " . dump( \%winhash );
  #my $winning = $winhash{winning};
  my %inst = %{ $dt{inst} }; #say  "HERE IN DESCEND \%inst: " . dump( \%inst );
  my @precedents = @{ $dt{precedents} }; #say  "HERE IN DESCEND \@precedents: " . dump( @precedents );
  my %dowhat = %{ $dt{dowhat} };
  #my $csim = $dt{csim}; #UNUSED
  my $precious = $dt{precious};
  my @packet = @{ $dt{packet} }; #say  "HERE IN DESCEND \@packet: " . dump( @packet );

  my $exitname = $dirfiles{exitname};
  
  
  
  
  	my $fundamentality_run = "n";

	if ( ( $dt{fundamentality_run} || "" ) eq "y" )
	{
	  $fundamentality_run = "y";
	}
	elsif ( ( $dirfiles{fundamentality} || "" ) eq "y" )
	{
	  $fundamentality_run = "y";
	}
	elsif ( ref( $d{dirfiles} ) eq "HASH"
		&& ( $d{dirfiles}{fundamentality} || "" ) eq "y" )
	{
	  $fundamentality_run = "y";
	}

	say "THSTHS DESCEND fundamentality_run=$fundamentality_run";







  #say  "IN ENTRY DESCEND3  \$dirfiles{starsign} " . dump( $dirfiles{starsign} );

  my %d = %{ $instances[0] };
  my $countcase = $d{countcase}; #say  "HERE IN DESCEND \$countcase: " . dump( $countcase );
  my $countblock = $d{countblock}; #say  "HERE IN DESCEND \$countblock: " . dump( $countblock );
  my %incumbents = %{ $d{incumbents} }; #say  "HERE IN DESCEND \%incumbents: " . dump( \%incumbents );
  my @varnumbers = @{ $d{varnumbers} };
  @varnumbers = Sim::OPT::washn( @varnumbers ); #say  "HERE IN DESCEND \@varnumbers: " . dump( @varnumbers );
  my @miditers = @{ $d{miditers} };
  @miditers = Sim::OPT::washn( @miditers ); #say  "HERE IN DESCEND \@miditers: " . dump( @miditers );
  my @sweeps = @{ $d{sweeps} }; #say  "HERE IN DESCEND \@sweeps: " . dump( @sweeps );
  my @sourcesweeps = @{ $d{sourcesweeps} }; #say  "HERE IN DESCEND \@sourcesweeps: " . dump( @sourcesweeps );
  my @rootnames = @{ $d{rootnames} }; #say  "HERE IN DESCEND \@rootnames: " . dump( @rootnames );
  my @winneritems = @{ $d{winneritems} }; #say  "HERE IN DESCEND \@winneritems: " . dump( @winneritems );
  my $instn = $d{instn}; #say  "HERE IN DESCEND \$instn: " . dump( $instn );

  my $fire = $d{fire};

  my $skipfile = $vals{skipfile};
	my $skipsim = $vals{skipsim};
	my $skipreport = $vals{skipreport};

	my @blockelts = @{ $d{blockelts} };

	my @blocks = @{ $d{blocks} };
  my $rootname = Sim::OPT::getrootname(\@rootnames, $countcase);
  $rootname = Sim::OPT::clean( $rootname, $mypath, $file );
  my %varnums = %{ $d{varnums} };
  my %mids = %{ $d{mids} };
  my %carrier = %{ $d{carrier} };
  my $outstarmode = $dowhat{outstarmode};
  my $is = $d{is}; ###DDD!!! JUST USED IN FIRING MODE
  my $stamp = $d{stamp};

  my $from     = $instances[0]{origin} // $instances[0]{from}; 

  if ( !$dirfiles{repfile} )
  {
    $dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
  }
  my $repfile = $dirfiles{repfile};
  
  if ( !$dirfiles{sortmixed} )
  {
    $dirfiles{sortmixed} = "$dirfiles{repfile}" . "_sortm.csv";
  }
  
  
  if ( !$dirfiles{totres} )
  {
    $dirfiles{totres} = "$mypath/$file-$countcase" . "_totres.csv";
  }
  
  if ( !$dirfiles{ordres} )
  {
    $dirfiles{ordres} = "$mypath/$file-$countcase" . "_ordres.csv";
  }

  #say  "RELAUNCHED IN DESCEND WITH INST " . dump( %inst );

  my ( $direction, $starorder );
  if ( $outstarmode eq "y" )
  {
    $direction = ${$dowhat{direction}}[$countcase][$countblock]; 
    $starorder = ${$dowhat{starorder}}[$countcase][$countblock];
    if ( $direction eq "" )
    {
      $direction = ${$dowhat{direction}}[0][0];
    }

    if ( $starorder eq "" )
    {
      $starorder = ${$dowhat{starorder}}[0][0];
    }
  }
  else
	{
		#$direction = $dirfiles{direction};
		#$starorder = $dirfiles{starorder};
		#if ( $direction eq "" ){ $direction = ${$dowhat{direction}}[$countcase][$countblock]; }
		#if ( $starorder eq "" ){ $starorder = ${$dowhat{starorder}}[$countcase][$countblock]; }
    $direction = ${$dowhat{direction}}[$countcase][$countblock];
    $starorder = ${$dowhat{starorder}}[$countcase][$countblock];

    if ( $direction eq "" )
    {
      $direction = ${$dowhat{direction}}[0][0];
    }

    if ( $starorder eq "" )
    {
      $starorder = ${$dowhat{starorder}}[0][0];
    }
	}

  #say  "\$direction: $direction ";
  #say  "\${\$dowhat{direction}}[\$countcase][\$countblock]: ${$dowhat{direction}}[$countcase][$countblock]"; 

  my $precomputed = $dowhat{precomputed};
  my @takecolumns = @{ $dowhat{takecolumns} }; #NEW


  my @starpositions;
  if ( $outstarmode eq "y" )
  {
    @starpositions = @{ $dowhat{starpositions} };
  }
  else
  {
    @starpositions = @{ $dirfiles{starpositions} };
  }

  my $starnumber = scalar( @starpositions );
  my $starobjective = $dowhat{starobjective};
  my $objectivecolumn = $dowhat{objectivecolumn};
  my $searchname = $dowhat{searchname};

  my $countstring = $dirfiles{countstring};
  my $starstring = $dirfiles{starstring};
  my $starsign = $dirfiles{starsign};
  my $totres = $dirfiles{totres};
  my $ordres = $dirfiles{ordres};
  my $tottot = $dirfiles{tottot};
  my $ordtot = $dirfiles{ordtot};

  my $confinterlinear = "$mypath/" . $dowhat{confinterlinear} ;

  if ( !$dirfiles{repfile} )
  {
    $dirfiles{repfile} = "$mypath/$file-report-$countcase-$countblock.csv";
  }
  my $repfile = $dirfiles{repfile}; #say  "IN DESCENT FROM DIRFILES, \$countblock $countblock, \$repfile $repfile";

  if ( $fire eq "y" )
  {
    $repfile = $repfile . "-fire-$stamp.csv";###DDD!!!
  }

  if ( not( $repfile ) )
  {
    say  "I don't find \$repfile $repfile! at \$countblock $countblock. QUITTING."; 
    die; 
  }

  if ( ( not ( $fire eq "y" ) ) and ( ( $dowhat{ga} eq "y" ) or ( $dowhat{randompick} eq "y" ) ) )
  {
    Sim::OPT::washduplicates( $repfile );
  }
  

  my $sortmixed = $dirfiles{sortmixed};

  if ( !$sortmixed ){ die; };

  if ( $fire eq "y" )
  {
    $sortmixed = $sortmixed . "-fire-$stamp.csv";###DDD!!!
  }

  my ( $entryfile, $exitfile, $orderedfile );
  my $entryname = $dirfiles{entryname};
  if ( $entryname ne "" )
  {
    $entryfile = "$mypath/" . "$file" . "_tmp_" . "$entryname" . ".csv";
  }
  else
  {
    $entryfile = "";
  }

  my $exitname = $dirfiles{exitname};
  if ( $exitname ne "" )
  {
    $exitfile = "$mypath/" . "$file" . "_tmp_" . "$exitname" . ".csv";
  }
  else
  {
    $exitfile = "";
  }

  my $orderedname = "$exitname" . "-ord";
  if ( $orderedname ne "" )
  {
    $orderedfile = "$mypath/" . "$file" . "_tmp_" . "$orderedname" . ".csv";
  }
  else
  {
    $orderedfile = "";
  }

  #if ( $winning ne "" )
  #{
  #  Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
  #  miditers => \@miditers,  winneritems => \@winneritems,
  #  dirfiles => \%dirfiles, varnumbers => \@varnumbers,
  #  sweeps => \@sweeps, incumbents => \%incumbents, dowhat => \%dowhat ,
  #  sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
  #}


  if ( ( $dowhat{dumpfiles} eq "y" ) and ( not( -e $repfile ) ) )
  { die "There isn't \$repfile: $repfile"; };


  my $instance = $instances[0]; #

  my %dat = %{$instance};
  my @winneritems = @{ $dat{winneritems} };
  my $countvar = $dat{countvar};
  my $countstep = $dat{countstep};
  

  my $counthold = 0;

  my $skip = $dowhat{$countvar}{skip};

  my $word = join( ", ", @blockelts ); ###NEW

  my $varnumber = $countvar;
  my $stepsvar = $varnums{$countvar};


  say  "Descending into case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . ".";

  my @columns_to_report = @{ $reporttempsdata[1] };
  my $number_of_columns_to_report = scalar(@columns_to_report);
  my $number_of_dates_to_mix = scalar(@simtitles);
  my @dates                    = @simtitles;


  #my $throwclean = $repfile;
  #$throwclean =~ s/\.csv//;
  #my $selectmixed = "$throwclean-select.csv"; #say  "!!!! \$throwclean-select.csv: $throwclean-select.csv";

  
  my $remember;

  sub cleanselect
  {   # IT CLEANS THE MIXED FILE AND SELECTS SOME COLUMNS, THEN COPIES THEM IN ANOTHER FILE
    my ( $repfile, $selectmixed, $inst_r, $countblock, $varnums_r, $blockelts_r, $from, $dowhat_r ) = @_;
    $inst_r ||= {};
    my %varnums = %$varnums_r; #say  "IN DESCENT \@blockelts  " . dump( @blockelts );
    my @blockelts = @$blockelts_r;
    my %dowhat = %$dowhat_r;

    #say  "IN DESCENT \@blockelts " . dump( @blockelts );
    ####HERE!!!
    my $expected_r = Sim::OPT::enumerate(\%varnums, \@blockelts, $from); say  "IN DESCENT \$countblock $countblock \$expected_r " . dump( $expected_r );
    
    
    my %present;
    open( MIXFILE, $repfile ) or die "$!";
    my @lines = <MIXFILE>;
    close MIXFILE;

    @lines = uniq( @lines ); say  "IN DESCEND \@lines: " . dump( @lines );

    foreach my $ln (@lines)
    {
      chomp $ln;
      next if $ln =~ /^\s*$/;
      ####HERE!!!
      my $rid = Sim::OPT::instid( $ln, $file ); say  "IN DESCEND \$countblock $countblock \$rid " . dump( $rid );# NOT $repfile
      if ( defined($rid) and $rid ne "" )
      {
        #$dirfiles{reps}{$rid} = $ln; say  "IN DESCEND WRITING \$dirfiles{reps}{\$rid} \$dirfiles{reps}{$rid} " . dump( $dirfiles{reps}{$rid} );# NOT $repfile
        $present{$rid} = 1; say  "IN DESCENT \$file $file \$ln $ln \$countblock $countblock \$present{\$rid} \$present{$rid} " . dump( $present{$rid} );# NOT $repfile
        say  "IN DESCEND CHECKING: \$rid $rid \$dirfiles{reps}{\$rid}: " . dump( $dirfiles{reps}{$rid} );
      }
    }
    

    open( MIXFILE, ">>$repfile" ) or die "$!";
    for my $rid ( @{ $expected_r } )
    {
      next if $present{$rid};

      if ( exists $dirfiles{reps}{$rid} )
      {
        say MIXFILE $dirfiles{reps}{$rid}; say  "IN DESCENT EXISTS \$countblock $countblock \$dirfiles{reps}{\$rid} \$dirfiles{reps}{$rid} " . dump( $dirfiles{reps}{$rid} );# NOT $repfile
      }
    }
    close MIXFILE;

    open( MIXFILE, "$repfile" ) or die $!;
    my @lines = <MIXFILE>;
    close MIXFILE;

    open( SELECTEDMIXED, ">$selectmixed" ) or die( "$!" );
    foreach my $line (@lines)
    {
      if ( ( $line ne "" ) and ( $line ne " " ) and ( $line ne "\n" ) )
      {



# -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------




        chomp $line;
        $line =~ s/\n/°/g;
        $line =~ s/°/\n/g;
        $line =~ s/[()%]//g;
        $line =~ s/,$//;
        $line =~ s/,$//;
        $line =~ s/,$//;
        $line =~ s/ ?//;
        $line =~ s/ ?//;





        # -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------




        my @elts = split(/,/, $line); #say  "ELTS: " . dump( @elts );
        my $touse = $elts[0];

        $touse = Sim::OPT::clean( $touse, $mypath, $file );

        if ( ( ( $dowhat{names} eq "short" ) or ( $dowhat{names} eq "medium" ) ) and ( $touse =~ /^\d+$/ ) )
        {
          my $clear = $inst_r->{$touse};

          if ( ( !defined($clear) ) or ( $clear eq "" ) )
          {
            my $k = "$mypath/$file" . "_" . $touse;
            $clear = $inst_r->{$k};
          }


          if ( ( !defined($clear) ) or ( $clear eq "" ) )
          {
            die "Cannot map crypto id '$touse' to clear instance (names=short)";
          }
          $touse = $clear;
        }

        my ( @elements, @names, @obtaineds, @newnames ); #say  "\@keepcolumns: " . dump( @keepcolumns );
        foreach my $elm_ref (@keepcolumns)
        {
          my @cols = @{ $elm_ref };
          my $name = $cols[0];
          my $number = $cols[1];
          push ( @elements, $elts[$number] ); #say  "\PUSH \$elts[\$number]: " . dump( $elts[$number] );
          #say  "\$elts: $elts, \$number: $number";
          push ( @names, $name );
        } #say  "ELEMENTS: ". dump( @elements ); say  "NAMES: ". dump( @names );

        if ( not ( scalar( @weighttransforms ) == 0 ) )
        {
          my $coun = 0;
          foreach my $elt_ref ( @weighttransforms )
          {
            my @els = @{ $elt_ref };
            my $newname = $els[0];
            my $transform = $els[1];
            my $obtained = eval ( $transform ); #say  "HERE \$transform: $transform, \$obtained: $obtained";
            push ( @obtaineds, $obtained );
            push ( @newnames, $newname );
            $coun++;
          }
        }
        else
        {
          @obtaineds = @elements;
          @newnames = @names;
        }
        #say  "ELEMENTS: ". dump( @elements ); #say  "\@obtaineds: ". dump( @obtaineds );
        #say  "NAMES: ". dump( @names ); #say  "NEWNAMES: ". dump( @newnames );

        if ( !defined( $dirfiles{countnettotrowlength}  ) ) #THIS SWITCHES OFF AFTER THE FIRST PASS
        {
          $dirfiles{totrowlength} = ( scalar( @obtaineds ) * 2 );
          $dirfiles{countnettotrowlength}++; #THIS CALCULATES THE LENGTH OF THE ROW AND STORES IT
        }
        
        say  "IN DESCEND \$dowhat{discard} $dowhat{discard}";
        unless ( $obtaineds[-1] eq $dowhat{discard} )
        {
          print SELECTEDMIXED "$touse,";

          my $coun = 0; #say  "PRINTNG OBTAINEDS: " . dump ( @obtaineds ) ;
          foreach my $elt ( @obtaineds )
          {
            print SELECTEDMIXED "$newnames[$coun],";
            unless ( $coun == $#obtaineds )
            {
              print SELECTEDMIXED "$elt,";
            }
            else 
            {
              print SELECTEDMIXED "$elt";
            }
            $coun++;
          }
          print SELECTEDMIXED "\n";
        }
      }
    }
    close SELECTEDMIXED;
  }

  if ( $precomputed eq "" )###DDD!!!
  {
    #cleanselect( $repfile, $selectmixed, \%inst, $countblock, \%varnums, \@blockelts, $from, \%dowhat );
  }

  ###say  "IN DESCEND AFTER CLEANSELECT; INST " . dump( \%inst );


  #my $throw = $selectmixed;
  #$throw =~ s/\.csv//;
  #my $weight = "$throw-weight.csv";
  sub weight
  {
    my ( $selectmixed, $weight ) = @_;
    say  "Scaling results for case " . ( $countcase + 1 ). ", block " . ( $countcase + 1 ) . ".";
    open( SELECTEDMIXED, $selectmixed ) or die( "$!" );#say  "!!!! \$throw-weight.csv: $throw-weight.csv";
    my @lines = <SELECTEDMIXED>;
    close SELECTEDMIXED;

    my $counterline = 0;
    open( WEIGHT, ">$weight" ) or die( "$!" );

    my ( @containerone, @containernames, @containertitles, @containertwo, @containerthree, @maxes, @mins );
    foreach my $line (@lines)
    {
      $line =~ s/^[\n]//;
      chomp $line;
      my @elts = split( /\s+|,/, $line );
      my $touse = shift( @elts ); # IT CHOPS AWAY THE FIRST ELEMENT DESTRUCTIVELY
      my $countel = 0;
      my $countcol = 0;
      my $countcn = 0;
      foreach my $elt ( @elts )
      {
        if ( odd( $countel ) )
        {
          push ( @{ $containerone[ $countcol ] }, $elt );
          $countcol++;
        }
        else
        {
          push ( @{ $containernames[$countcn] }, $elt );
          $countcn++;
        }
        $countel++;
      }
      push ( @containertitles, $touse );
    }


    

    my $countcolm = 0;
    foreach my $colref ( @containerone )
    {
      my @column = @{ $colref }; # DEREFERENCE
    
      if ( max( @column ) != 0) # FILLS THE UNTRACTABLE VALUES
      {
        push ( @maxes, max( @column ) );
      }
      else
      {
        push ( @maxes, "" );
      }
    
      push ( @mins, min( @column ) );
    
      foreach my $el ( @column )
      {
        if ( abs( $maxes[ $countcolm ] ) >= abs( $mins[$countcolm] ) )
        {
          $absmaxes[ $countcolm ] = abs( $maxes[ $countcolm ] );
        }
        else 
        {
          $absmaxes[ $countcolm ] = abs( $mins[ $countcolm ] );
        }

        my $eltrans;
        if ( $absmaxes[ $countcolm ] != 0 )
        {
          $eltrans = ( $el / $absmaxes[$countcolm] ) ;
        }
        else
        {
          $eltrans = "" ;
        }
        push ( @{ $containertwo[$countcolm] }, $eltrans) ; #print  "ELTRANS: $eltrans\n";
      }
      $countcolm++;
    }
    #say  "HERE \@containerone: " . dump( @containerone ); #say  "\@containertwo: " . dump( @containertwo );
    #say  "\@maxes: " . dump( @maxes ); #say  "\@mins: " . dump( @mins );
    #say  "\@containernames: " . dump( @containernames );





    $dirfiles{absmaxes} ||= ();
    $dirfiles{absmins}  ||= ();

    my $c = 0;
    foreach my $max ( @maxes ) 
    {

      if ( !defined( $max ) or ( $max eq "NOTHING1") ) {  # keep index alignment
        $c++;
        next;
      }

      if ( !defined($dirfiles{absmaxes}[$c]) or ( $max > $dirfiles{absmaxes}[$c] ) ) 
      {
        $dirfiles{absmaxes}[$c] = $max;
      } else {
        $max = $dirfiles{absmaxes}[$c];
      }
      $c++;
    }

    $c = 0;
    foreach my $min ( @mins ) 
    {
      if ( !defined( $min ) ) 
      { 
        $c++; 
        next; 
      }

      if ( !defined($dirfiles{absmins}[$c]) or ( $min < $dirfiles{absmins}[$c] ) ) 
      {
        $dirfiles{absmins}[$c] = $min;
      } 
      else 
      {
        $min = $dirfiles{absmins}[$c];   
      }
      $c++;
    } 




    

    my $countrow = 0;
    foreach ( @lines )
    {
      my ( @c1row, @c2row, @cnamesrow );

      foreach my $c1_ref ( @containerone )
      {
        my @c1col = @{ $c1_ref };
        push( @c1row, $c1col[ $countrow ] );
      }

      foreach my $cnames_ref ( @containernames )
      {
        my @cnamescol = @{ $cnames_ref };
        push( @cnamesrow, $cnamescol[$countrow] );
      }

      foreach my $c2_ref ( @containertwo )
      {
        my @c2col = @{ $c2_ref };
        push( @c2row, $c2col[$countrow] );
      }


      my ( $numberels, $scalar_keepcolumns );
      if ( not ( scalar( @weighttransforms ) == 0 ) )
      {
        $numberels = scalar( @weighttransforms );
        $scalar_keepcolumns = scalar( @weighttransforms );
      }
      else
      {
        $numberels = scalar( @keepcolumns );
        $scalar_keepcolumns = scalar( @keepcolumns );
      }


      my $wsum = 0; # WEIGHTED SUM
      my $counterin = 0;
      foreach my $elt ( @c2row )
      {
        my $newelt = ( $elt * abs( $weights[$counterin] ) );
        $wsum = ( $wsum + $newelt ) ;
        $counterin++;
      }

      #say  "HERE \@cnamesrow: " . dump( @cnamesrow ); #say  "\@c1row: " . dump( @c1row ); #say  "\@c2row: " . dump( @c2row );

      print WEIGHT "$containertitles[ $countrow ],";

      $countel = 0;
      foreach my $el ( @c1row )
      {
        print WEIGHT "$cnamesrow[$countel],";
        print WEIGHT "$el,";
        $countel++;
      }

      foreach my $el ( @c2row )
      {
        print WEIGHT "$el,";
      }

      print WEIGHT "$wsum\n";

      $countrow++;
    }
    close WEIGHT;
  }


  



  if ( $precomputed eq "" )###DDD!!!!
  {
    #weight( $selectmixed, $weight ); #
  }

  #say  "IN DESCEND AFTER WEIGHT; INST " . dump( %inst );

  #my $weighttwo = $weight;


  if ( $precomputed ne "" )###DDD!!!
  {
    $weighttwo = $repfile; ############### TAKE CARE!
  }

  if ( $objectivecolumn eq "" )
  {
    $dowhat{objectivecolumn} = auto_objcol( \@packet ); say  "IN DESCENT CALCULATED \$dowhat{objectivecolumn} $dowhat{objectivecolumn}"; 
    $objectivecolumn = $dowhat{objectivecolumn};
  }

  #if ( $objectivecolumn eq "" )
  #{
  #  #$dowhat{objectivecolumn} = auto_objcol_file( $weighttwo );
  #  $objectivecolumn = $dowhat{objectivecolumn};
  #}


  #if ( not( -e $weighttwo ) ){ die; };


  if ( ( $dowhat{dumpfiles} eq "y" ) and ( not ( ( $repfile ) and ( -e $repfile ) ) ) )
  {
    die( "$!" );
  }

  sub sortmixed
  {
    my ( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode,
     $instn, $inst_r, $dirfiles_r, $vehicles_r, $countcase, $countblock, $fire, $packet_r ) = @_;
    say  "Processing results for case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . ".";
    my %inst = %{ $inst_r }; say  "IN SORTMIXED \%inst" . dump( \%inst );
    my %dirfiles = %{ $dirfiles_r };
    my %vehicles = %{ $vehicles_r };
    my @packet = @$packet_r; say  "IN SORTMIXED RECEIVED \@packet: " . dump( @packet );


    #my $weighttwoNEW = $weighttwo . "-NEW.csv"; ###HERE!!!### SWITCH
    #open( WEIGHTTWONEW, ">$weighttwoNEW" ) or die( "$!" ); say  "!!!!!IN SORTMIXED \$weighttwo" . dump( $weighttwo );
    #foreach my $l ( @packet )
    #{
    #  say WEIGHTTWONEW "$l";
    #}
    #close WEIGHTTWONEW; ###HERE!!!### SWITCH


    if ( $searchname eq "n" )###################################
    {
      #open( WEIGHTTWO, $weighttwo ) or die( "$!" ); say  "!!!!!IN SORTMIXED \$weighttwo" . dump( $weighttwo );
      #my @lines = <WEIGHTTWO>;
      #close WEIGHTTWO;

      if ( $dirfiles{popsupercycle} eq "y" )
      {
        my $openblock = pop( @{ $vehicles{nesting}{$dirfiles{nestclock}} } );
        while ( $openblock <= $countblock )
        {
          push( @lines, @{ $vehicles{$countcase}{$openblock} } );
          $openblock++;
        }
        unless ( $dowhat{metamodel} eq "y" )
        {
          $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
        }
      }

      #@lines = uniq( @lines );
      @lines = uniq( @packet );
      #say  "\$objectivecolumn: $objectivecolumn, FIRSTLINE! " . dump( $lines[0] ) . "OF \$weighttwo: $weighttwo";

      my @splitteds;
      foreach my $line ( @lines )
      {



        # -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------



        chomp $line;
        $line =~ s/ $// ;
        $line =~ s/,$// ;
        $line =~ s/ $// ;
        $line =~ s/,$// ;
        my @elts = split( "," , $line );
        push( @splitteds, [ @elts ] );




        # -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------



      }

      say  "\$direction $direction, \$starorder $starorder, \$objectivecolumn: $objectivecolumn, LINES! " . dump( @lines );

      my @sorted;
      if ( $direction ne "star" )
      {
        if ( $direction eq "<" )
        {
          say  "I AM 1";
          #@sorted = sort { $a->[$objectivecolumn] <=> $b->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $a ))[ $objectivecolumn ] <=> ( split( ',', $b ))[ $objectivecolumn ] } @lines;
        }
        elsif ( $direction eq ">" )
        {
          say  "I AM 2";
          #@sorted = sort { $b->[$objectivecolumn] <=> $a->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $b ))[ $objectivecolumn ] <=> ( split( ',', $a ))[ $objectivecolumn ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode eq "y" ) )
      {
        if ( $starorder eq "<" )
        {
          #@sorted = sort { $a->[0] <=> $b->[0] } @splitteds;
          @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          #@sorted = sort { $b->[0] <=> $a->[0] } @splitteds;
          @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode ne "y" ) )
      {
        if ( $starorder eq "<" )
        {
          say  "I AM 3";
          #@sorted = sort { $a->[$objectivecolumn] <=> $b->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          say  "I AM 4";
          #@sorted = sort { $b->[$objectivecolumn] <=> $a->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
        }
      }
      else
      {
        if ( $starorder eq "<" )
        {
          say  "I AM 5a";
          #@sorted = sort { $a->[$objectivecolumn] <=> $b->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          say  "I AM 6a";
          #@sorted = sort { $b->[$objectivecolumn] <=> $a->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
        }
      }

      #say  "SORTED!: " . dump( @sorted );

      open( SORTMIXED, ">$sortmixed" ) or die( "$!" );
      if ( not( -e $sortmixed ) ){ die; };
      #say  "!!!!!!!!IN SORTMIXED \$sortmixed" . dump( $sortmixed );

      open( TOTRES, ">>$totres" ) or die; #say  "!!!!!!!!IN SORTMIXED \$totres" . dump( $totres );

      foreach my $line ( @sorted )
      {
        say SORTMIXED $line;
        say TOTRES $line;
        push ( @totalcases, $line );
      }
      close TOTRES;
      close SORTMIXED;
      
      
      
      

	



      


      if ( $fire eq "y" ) ###DDD!!! ATTENTION
      {
        open( SORTMIXED, "$sortmixed" ) or die( "$!" );
        {
          my @lines = <SORTMIXED>;
          close SORTMIXED;
          $lines[0] =~ s/ +$// ;
          $lines[0] =~ s/,+$// ;
          my @elts = split( ",", $lines[0] );
          my $firedvalue = $elts[$#elts];
          #say "returning $firedvalue";
          #open( RESPONSIN, ">./responsin" );
          #print RESPONSIN $firedvalue;
          #close RESPONSIN;
          return($firedvalue);
        }
      }

      #########################################à
    }
    elsif ( $searchname eq "y" )###################################
    {
      #my @theselines;
      my @theselines = @packet;
      #if ( ( $weighttwo ne "" ) and ( -e $weighttwo ) )
      #{
      #  open( WEIGHTTWO, $weighttwo ) or die( "$!" );
      #  @theselines = <WEIGHTTWO>;
      #  close WEIGHTTWO;
      #}

      if ( $dirfiles{popsupercycle} eq "y" )
      {
        my $openblock = pop( @{ $vehicles{nesting}{$dirfiles{nestclock}} } );
        while ( $openblock <= $countblock )
        {
          push( @lines, @{ $vehicles{$countcase}{$openblock} } );
          $openblock++;
        }
        unless ( $dowhat{metamodel} eq "y" )
        {
          $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
        }
      }

      if ( $exitfile ne "" )
      {
        open( EXITFILE, ">>$exitfile" ) or die;
        foreach my $line ( @theselines )
        {
          print EXITFILE $line;
        }
        close EXITFILE;
      }


      @theselines = uniq( @theselines );
      say  "\$objectivecolumn: $objectivecolumn, LINES! " . dump( @theselines );

      my $thoselines;
      if ( ( $entryfile ne "" ) and ( -e $entryfile ) )
      {
        open( ENTRYFILE, "$entryfile" ) or die; #say  "IN DESCENT OPENING \$entryfile" . dump( $entryfile );
        $thoselines = <ENTRYFILE>;
        close ENTRYFILE;
      }

      my @lines;
      push( @lines, @theselines, $thoselines );

      if ( ( $exitfile ne "" ) and ( -e $exitfile ) )
      {
        open( EXITFILE, "$exitfile" ) or die;
        @lines = <EXITFILE>;
        close EXITFILE;
      }

      my @splitteds;
      foreach my $line ( @lines )
      {


        # -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------



        chomp $line;
        $line =~ s/ $// ;
        $line =~ s/,$// ;
        $line =~ s/ $// ;
        $line =~ s/,$// ;
        #my @elts = split( "," , $line );
        #push( @splitteds, [ @elts ] );



        # -------------------------
# DEBUG: inspect prepfile lines before/after trimming
# -------------------------

my $n = scalar(@prepfile_lines);
say  "META DEBUG: prepfile_lines count = $n";

my $max = $n < 5 ? $n : 5;

# BEFORE trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $prepfile_lines[$i];
    $ln = "<undef>" unless defined $ln;
    chomp $ln;
    say  "META DEBUG: BEFORE[$i] = <$ln>";
}

# Apply your trimming to a COPY (do not alter original yet)
my @trimmed = @prepfile_lines;
for ( my $i = 0 ; $i < @trimmed ; $i++ )
{
    next unless defined $trimmed[$i];
    chomp $trimmed[$i];
    $trimmed[$i] =~ s/,+$//;   # your trailing-comma strip
}

# AFTER trimming
for ( my $i = 0 ; $i < $max ; $i++ )
{
    my $ln = $trimmed[$i];
    $ln = "<undef>" unless defined $ln;
    say  "META DEBUG: AFTER[$i]  = <$ln>";
}

# -------------------------
# END DEBUG
# -------------------------



      }

      my @sorted;
      if ( $direction ne "star" )
      {
        if ( $direction eq "<" )
        {
          say  "I AM 5";
          #@sorted = sort { $a->[$objectivecolumn] <=> $b->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $a ))[ $objectivecolumn ] <=> ( split( ',', $b ))[ $objectivecolumn ] } @lines;
        }
        elsif ( $direction eq ">" )
        {
          say  "I AM 6";
          #@sorted = sort { $b->[$objectivecolumn] <=> $a->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $b ))[ $objectivecolumn ] <=> ( split( ',', $a ))[ $objectivecolumn ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode eq "y" ) )
      {
        if ( $starorder eq "<" )
        {
          #@sorted = sort { $a->[0] <=> $b->[0] } @splitteds;
          @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          #@sorted = sort { $b->[0] <=> $a->[0] } @splitteds;
          @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lines;
        }
      }
      elsif ( ( $direction eq "star" ) and ( $outstarmode ne "y" ) )
      {
        if ( $starorder eq "<" )
        {
          say  "I AM 7";
          #@sorted = sort { $a->[$objectivecolumn] <=> $b->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
        }
        elsif ( $starorder eq ">" )
        {
          say  "I AM 8";
          #@sorted = sort { $b->[$objectivecolumn] <=> $a->[$objectivecolumn] } @splitteds;
          @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
        }
      }

      say  "!!! SORTED!!: " . dump( @sorted );

      open ( ORDEREDFILE, ">>$orderedfile" ) or die;
      open( TOTRES, ">>$totres" ) or die;

      foreach my $line ( @sorted )
      {
        print ORDEREDFILE $line;
        print TOTRES $line;
        push ( @totalcases, $line );
      }
      close TOTRES;
      close ORDEREDFILE;
    }#######################################################
    close SORTMIXED;
  } ### END SUB sortmixed
  close SORTMIXED;
  #if ( not( -e $weighttwo) ){ die; };
  if ( not( $sortmixed ) ){ die; };
  my $firedvalue = sortmixed( $weighttwo, $sortmixed, $searchname, $entryfile, $exitfile, $orderedfile, $outstarmode,
  $instn, \%inst, \%dirfiles, \%vehicles, $countcase, $countblock, $fire, \@packet );

  say  "IN DESCEND AFTER SORTMIXED; INST " . dump( %inst );

  if ( $firedvalue ne "" )
  {
    return( $firedvalue );
  }




 



  ###HERE

  #say  "TOTRES DEBUG: totres=[$totres]";
  #say  "TOTRES DEBUG: exists=" . (defined($totres) && -e $totres ? 1 : 0) . " readable=" . (defined($totres) && -r $totres ? 1 : 0);
  #say  "TOTRES DEBUG: cwd=" . `pwd`;

  open( TOTRES, "<$totres" ) or die "Cannot open totres '$totres': $!";
  my @lins = <TOTRES>;
  close TOTRES;
  
  my @newlins;
  foreach my $lin ( @lins )
  {
    chomp $lin;
    my @elts = split( /,/, $lin );
    @elts = @elts[ 0 .. $dirfiles{totrowlength} ];
    push( @newlins, [ map { $_ } @elts ] );
  }
  

  $dirfiles{counttotfiles}++;
  my $newtotdest = $totres . ".old" . $dirfiles{counttotfiles};
  say  `mv -f $totres $newtotdest`;

   
  my $counterline = 0;
  open( TOTRES, ">$totres" ) or die( "$!" );
  my ( @containerone, @containernames, @containertitles, @containertwo, @containerthree, @maxes, @mins );
  foreach my $newlin_r (@newlins)
  {

    my @elts = @{ $newlin_r };
    my $touse = shift( @elts ); # IT CHOPS AWAY THE FIRST ELEMENT DESTRUCTIVELY
    my $countel = 0;
    my $countcol = 0;
    my $countcn = 0;
    foreach my $elt ( @elts )
    {
      if ( odd( $countel ) )
      {
        push ( @{ $containerone[ $countcol ] }, $elt );
        $countcol++;
      }
      else
      {
        push ( @{ $containernames[$countcn] }, $elt );
        $countcn++;
      }
      $countel++;
    }
    push ( @containertitles, $touse );
  }

  

  my $countcolm = 0;
  foreach my $colref ( @containerone )
  {
    my @column = @{ $colref }; # DEREFERENCE
  
    if ( max( @column ) != 0) # FILLS THE UNTRACTABLE VALUES
    {
      push ( @maxes, max( @column ) );
    }
    else
    {
      push ( @maxes, "" );
    }
  
    push ( @mins, min( @column ) );
  
    foreach my $el ( @column )
    {
      if ( abs( $maxes[ $countcolm ] ) >= abs( $mins[$countcolm] ) )
      {
        $absmaxes[ $countcolm ] = abs( $maxes[ $countcolm ] );
      }
      else 
      {
        $absmaxes[ $countcolm ] = abs( $mins[ $countcolm ] );
      }

      my $eltrans;
      if ( $absmaxes[ $countcolm ] != 0 )
      {
        $eltrans = ( $el / $absmaxes[$countcolm] ) ;
      }
      else
      {
        $eltrans = "" ;
      }
      push ( @{ $containertwo[$countcolm] }, $eltrans) ; #print  "ELTRANS: $eltrans\n";
    }
    $countcolm++;
  }
  #say  "HERE \@containerone: " . dump( @containerone ); #say  "\@containertwo: " . dump( @containertwo );
  #say  "\@maxes: " . dump( @maxes ); #say  "\@mins: " . dump( @mins );
  #say  "\@containernames: " . dump( @containernames );



  
  $dirfiles{absmaxes} ||= ();
  $dirfiles{absmins}  ||= ();

  my $c = 0;
  foreach my $max ( @maxes ) 
  {

    if ( !defined( $max ) or ( $max eq "NOTHING1") ) {  # keep index alignment
      $c++;
      next;
    }

    if ( !defined($dirfiles{absmaxes}[$c]) or ( $max > $dirfiles{absmaxes}[$c] ) ) 
    {
      $dirfiles{absmaxes}[$c] = $max;
    } else {
      $max = $dirfiles{absmaxes}[$c];
    }
    $c++;
  }

  $c = 0;
  foreach my $min ( @mins ) 
  {
    if ( !defined( $min ) ) 
    { 
      $c++; 
      next; 
    }

    if ( !defined($dirfiles{absmins}[$c]) or ( $min < $dirfiles{absmins}[$c] ) ) 
    {
      $dirfiles{absmins}[$c] = $min;
    } 
    else 
    {
      $min = $dirfiles{absmins}[$c];   
    }
    $c++;
  }

    
    


  my @newbowl;
  my $countrow = 0;
  foreach ( @newlins )
  {
    my ( @c1row, @c2row, @cnamesrow );

    foreach my $c1_ref ( @containerone )
    {
      my @c1col = @{ $c1_ref };
      push( @c1row, $c1col[ $countrow ] );
    }

    foreach my $cnames_ref ( @containernames )
    {
      my @cnamescol = @{ $cnames_ref };
      push( @cnamesrow, $cnamescol[ $countrow ] );
    }

    foreach my $c2_ref ( @containertwo )
    {
      my @c2col = @{ $c2_ref };
      push( @c2row, $c2col[ $countrow ] );
    }

    my $wsum = 0;
    my $counterin = 0;
    foreach my $elt ( @c2row )
    {
      my $newelt = ( $elt * abs( $weights[$counterin] ) );
      $wsum = ( $wsum + $newelt );
      $counterin++;
    }

    my @row;
    push( @row, $containertitles[ $countrow ] );

    my $countel = 0;
    foreach my $el ( @c1row )
    {
      push( @row, $cnamesrow[$countel] );
      push( @row, $el );
      $countel++;
    }

    foreach my $el ( @c2row )
    {
      push( @row, $el );
    }

    push( @row, $wsum );

    push( @newbowl, [ @row ] );

    $countrow++;
  }


  my @sortthis; #say  "0 \$dowhat{objectivecolumn} $dowhat{objectivecolumn}, \$direction: $direction ";
  if ( $direction eq "<" )
  {
    @sortthis = sort { $a->[$dowhat{objectivecolumn}] <=> $b->[$dowhat{objectivecolumn}] } @newbowl; #say  "1 \$dowhat{objectivecolumn} $dowhat{objectivecolumn}";
  }
  elsif ( $direction eq ">" )
  {
    @sortthis = sort { $b->[$dowhat{objectivecolumn}] <=> $a->[$dowhat{objectivecolumn}] } @newbowl; #say  "2 \$dowhat{objectivecolumn} $dowhat{objectivecolumn}";
  }
  else
  {
    @sortthis = @newbowl;   #say  "3 \$dowhat{objectivecolumn} $dowhat{objectivecolumn}";
  }
  
  my @bag;
  foreach my $elts_r ( @sortthis )
  {
    my @elts = @{ $elts_r };
    
    if ( $elts[0] ~~ @bag )
    {
      push( @bag, $elts[0] );
      next;
    }
    else 
    {
      push( @bag, $elts[0] );
    }
    

    my $string = join( ",", @elts );
    say TOTRES $string;
  }
  close TOTRES;
  
  
  
        say "##DDD## dirfiles fundamentality: $dirfiles{fundamentality}";
	if ( $fundamentality_run eq "y" )
	{
	  my $totres = $dirfiles{totres};

	  if ( !defined($totres) || $totres eq "" )
	  {
	    $totres = "$dowhat{mypath}/$dowhat{file}-$countcase" . "_totres.csv";
	  }

	  say "FUND POSTPROCESS in Descend.pm";
	  say "FUND POSTPROCESS totres=$totres";
	  say "FUND POSTPROCESS exists=" . ( -e $totres ? "yes" : "no" );

	  if ( -e $totres )
	  {
	    my $fund_r = fundamentality_indices(
	      {
		file      => $totres,
		outdir    => $dowhat{mypath},
		instcol   => 1,
		metriccol => 2,
		ycol      => 3,
		metric    => "totdhs",
		sep       => ",",
		header    => 0,
		quiet     => 0,
		ordinary_sensitivity_file => $dt{ordinary_sensitivity_file} || $dirfiles{ordinary_sensitivity_file},
		fundamentalitynum => $dt{fundamentalitynum} || $dirfiles{fundamentalitynum},
	      });

	    say "Fundamentality indices written:";
	    say "  $fund_r->{absfund_file}";
	    say "  $fund_r->{sensitivities_file}";
	    say "  $fund_r->{relfund_file}";
	  }
	  else
	  {
	    warn "Cannot compute fundamentality indices: totres file not found after Descend.pm result aggregation: $totres\n";
	  }
	} #DDD#



#################################################################################


  sub metamodel
  {
    my ( $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $carrier_r, $metafile,
      $direction, $starorder, $ordmeta, $varnums_r, $countblock, $lines_r ) = @_;

    my %dowhat = %$dowhat_r;

    return unless ( defined($dowhat{metamodel}) && $dowhat{metamodel} eq "y" );

    # -----------------------------------------------------------------
    # Metamodel dispatch (new semantics)
    #
    #  $dowhat{altmetamodel} = "" (or undef)  => OPTcue not present, Interlinear only (dwgn)
    #  $dowhat{altmetamodel} = "cue"          => OPTcue + Metabridge available (notify)
    #
    # Method selection is by $dowhat{canon}:
    #  $dowhat{canon} = "" (or undef)         => Interlinear (dwgn)
    #  $dowhat{canon} = "NeuralBoltzmann" ... => Metabridge dispatch
    #
    # Backward compatibility:
    #  * $dowhat{altmetamodel} = "y" is treated as "cue".
    #  * $dowhat{metamodeltreaty} overrides altmetamodel if set.
    # -----------------------------------------------------------------
    my $treaty = defined($dowhat{altmetamodel}) ? $dowhat{altmetamodel} : "";
    $treaty = $dowhat{metamodeltreaty} if defined($dowhat{metamodeltreaty}) && $dowhat{metamodeltreaty} ne "";
    $treaty = "cue" if defined($treaty) && lc($treaty) eq "y";

    if ( defined($treaty) && lc($treaty) eq "cue" )
    {
      require Sim::OPTcue::OPTcue;
      return Sim::OPTcue::OPTcue::notify(
        $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $carrier_r, $metafile,
        $direction, $starorder, $ordmeta, $varnums_r, $countblock, $lines_r
      );
    }

    return dwgn(
      $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $carrier_r, $metafile,
      $direction, $starorder, $ordmeta, $varnums_r, $countblock, $lines_r
    );
  }



  sub dwgn
  {
    my ( $dowhat_r, $sortmixed, $file, $dirfiles_r, $blockelts_r, $carrier_r, $metafile,
      $direction, $starorder, $ordmeta, $varnums_r, $countblock, $lines_r ) = @_;

    my %dowhat = %$dowhat_r;
    my %dirfiles = %$dirfiles_r;
    my @blockelts = @$blockelts_r;
    my %carrier = %$carrier_r;
    my %varnums = %$varnums_r;
    my @raw_full = @$lines_r;

    return unless ( $dowhat{metamodel} eq "y" );

    # Optional override of the entrance file (for debugging / staging)
    if ( defined( $dowhat{preprep} ) and ( $dowhat{preprep} ne "" ) )
    {
      $sortmixed = $dowhat{preprep};
      die "PREPREP file not found: $sortmixed\n" unless ( -e $sortmixed );
    }

    my $mypath = $main::mypath;
    my $tofile = $main::tofile;

    # Interlinear config path (same intent as in descend())
    my $confinterlinear = $dowhat{confinterlinear};
    if ( defined( $confinterlinear ) and ( $confinterlinear ne "" ) and defined( $mypath ) and ( $mypath ne "" ) )
    {
      $confinterlinear = "$mypath/$confinterlinear";
    }


    my $is_num = sub
    {
      my ( $v ) = @_;
      return 0 unless defined $v;
      return ( $v =~ /^\s*[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?\s*$/ ) ? 1 : 0;
    };

    my $canon_id = sub
    {
      my ( $id ) = @_;
      return "" unless defined $id;
      $id =~ s/\r?\n$//;

      if ( defined( $mypath ) and ( $mypath ne "" ) and defined( $file ) and ( $file ne "" ) )
      {
        $id =~ s/^\Q$mypath\/$file\E//;
      }

      $id =~ s/^_+//;

      if ( defined( $file ) and ( $file ne "" ) )
      {
        $id =~ s/^\Q$file\_\E//;
      }
      return $id;
    };

    my $compound_from_fields = sub
    {
      my ( $fields_r ) = @_;
      my @f = @{ $fields_r };

      # last numeric field is the safest definition across both full and short formats
      for ( my $i = $#f; $i >= 0; $i-- )
      {
        if ( $is_num->( $f[$i] ) )
        {
          my $v = $f[$i];
          $v =~ s/^\s+|\s+$//g;
          return $v;
        }
      }
      return ""; # should never happen for valid formats
    };

    #open( my $IN, "<", $sortmixed ) or die "Cannot open $sortmixed: $!\n";
    #my @raw_full = <$IN>;
    #close $IN;

    my @clean_full;
    foreach my $ln ( @raw_full )
    {
      next unless defined $ln;
      $ln =~ s/\r?\n$//;

      # preserve the entire row, but canonicalize the ID field reliably
      my @f = split( /,/, $ln, -1 );
      next unless scalar( @f ) > 0;
      $f[0] = $canon_id->( $f[0] );

      my $rebuilt = join( ",", @f );
      push( @clean_full, $rebuilt );
    }

    if ( defined( $dowhat{dumpfiles} ) and ( $dowhat{dumpfiles} eq "y" ) )
    {
      my $cleanordres = $sortmixed . "_tmp_cleaned.csv";
      open( my $CLEAN, ">", $cleanordres ) or die "Cannot write $cleanordres: $!\n";
      foreach my $ln ( @clean_full ) { print $CLEAN $ln . "\n"; }
      close $CLEAN;
    }

    my %varns = %varnums;
    foreach my $key ( keys %varns )
    {
      if ( not( $key ~~ @blockelts ) )
      {
        $varns{$key} = 1;
      }
    }

    my $bit = $file . "_";
    my @bag = ( $bit );

    my @box_refs = @{ Sim::OPT::toil( \@blockelts, \%varns, \@bag ) };
    my @box      = @{ $box_refs[-1] };
    my $integrated_r = Sim::OPT::integratebox( \@box, \%carrier, $file, \@blockelts );

    my @blank_ids;
    foreach my $el ( @{ $integrated_r } )
    {
      push( @blank_ids, $canon_id->( $el->[0] ) );
    }
    @blank_ids = uniq( @blank_ids );

    if ( defined( $dowhat{dumpfiles} ) and ( $dowhat{dumpfiles} eq "y" ) )
    {
      my $blankfile = $sortmixed . "_tmp_blank.csv";
      open( my $BL, ">", $blankfile ) or die "Cannot write $blankfile: $!\n";
      foreach my $id ( @blank_ids ) { print $BL $id . "\n"; }
      close $BL;
    }

    my %modhs;
    my %torecovers;

    foreach my $key ( sort keys %varnums )
    {
      if ( not( $key ~~ @blockelts ) )
      {
        $modhs{$key} = $varnums{$key};
        $torecovers{$key} = $carrier{$key};
      }
    }

    my @prep_blanks = @blank_ids;
    if ( scalar( keys %modhs ) > 0 )
    {
      foreach my $id ( @prep_blanks )
      {
        foreach my $key ( keys %modhs )
        {
          $id =~ s/$key-\d+/$key-$modhs{$key}/;
        }
      }
    }

    my @prep_results = @clean_full;
    if ( scalar( keys %modhs ) > 0 )
    {
      foreach my $ln ( @prep_results )
      {
        foreach my $key ( keys %modhs )
        {
          $ln =~ s/$key-\d+/$key-$modhs{$key}/;
        }
      }
    }

    if ( defined( $dowhat{dumpfiles} ) and ( $dowhat{dumpfiles} eq "y" ) )
    {
      my $prepblank = $sortmixed . "_tmp_prepblank.csv";
      my $prepsort  = $sortmixed . "_tmp_prepsort.csv";
      open( my $PB, ">", $prepblank ) or die "Cannot write $prepblank: $!\n";
      foreach my $id ( @prep_blanks ) { print $PB $id . "\n"; }
      close $PB;
      open( my $PS, ">", $prepsort ) or die "Cannot write $prepsort: $!\n";
      foreach my $ln ( @prep_results ) { print $PS $ln . "\n"; }
      close $PS;
    }

    # ---------- join blanks + known values (FULL -> SHORT) in memory ----------

    # Map: id -> compound (from FULL results; compound is last numeric field)
    my %id2compound;
    foreach my $ln ( @prep_results )
    {
      my @f = split( /,/, $ln, -1 );
      next unless scalar( @f ) > 1;
      my $id = $canon_id->( $f[0] );
      my $compound = $compound_from_fields->( \@f );
      next if ( $id eq "" );
      next if ( $compound eq "" );
      $id2compound{$id} = $compound;
    }

    my @prepfile_lines;
    foreach my $id ( @prep_blanks )
    {
      my $cid = $canon_id->( $id );
      if ( exists( $id2compound{$cid} ) )
      {
        push( @prepfile_lines, $cid . "," . $id2compound{$cid} );
      }
      else
      {
        push( @prepfile_lines, $cid );
        #push( @prepfile_lines, $cid . "," );
      }
    }

    if ( defined( $dowhat{dumpfiles} ) and ( $dowhat{dumpfiles} eq "y" ) )
    {
      my $prepfile = $sortmixed . "_tmp_prepfile.csv";
      open( my $PF, ">", $prepfile ) or die "Cannot write $prepfile: $!\n";
      foreach my $ln ( @prepfile_lines ) { print $PF $ln . "\n"; }
      close $PF;
    }

    say "!!!!!ABOUT TO CALL INTERLINEAR WITH " . dump( @prepfile_lines );
    my $rawmetafile = $metafile . "_tmp_raw.csv";
    my ( $arr_r, $fulls_r ) = Sim::OPT::Interlinear::interlinear( $sortmixed, $confinterlinear, 
      $rawmetafile, \@blockelts, $tofile, $countblock, 
      $dowhat_r, $dirfiles_r, \@prepfile_lines );
    my @fulls = @$fulls_r;

    say "!!!!! FROM INTERLINEAR IN DESCEND RETURNED NOT USED \@ARR " . dump( $arr_r );
    say "!!!!! AND RETURNED NEWARR " . dump( @fulls );
    #open( my $RM, "<", $rawmetafile ) or die "Cannot open $rawmetafile: $!\n";
    #my @fulls = <$RM>;
    #close $RM;

    my @metalines;
    foreach my $ln ( @fulls )
    {
      next unless defined $ln;
      $ln =~ s/\r?\n$//;

      foreach my $key ( keys %torecovers )
      {
        $ln =~ s/$key-\d+/$key-$torecovers{$key}/;
      }
      push( @metalines, $ln );
    }

    @metalines = uniq( @metalines );

    #open( my $MF, ">", $metafile ) or die "Cannot write $metafile: $!\n";
    #foreach my $ln ( @metalines ) 
    #{ 
    #  print $MF $ln . "\n"; 
    #}
    #close $MF;

    # Sort and write ORDMETA (overwrite, not append)
    my @sorted;
    if ( ( defined( $direction ) and ( $direction eq "<" ) ) or ( defined( $starorder ) and ( $starorder eq "<" ) ) )
    {
      @sorted = sort { (split( /,/, $a, -1 ))[1] <=> ( split( /,/, $b, -1 ))[1] } @metalines;
    }
    else
    {
      @sorted = sort { (split( /,/, $b, -1 ))[1] <=> ( split( /,/, $a, -1 ))[1] } @metalines;
    }

    open( my $OM, ">", $ordmeta ) or die "Cannot write $ordmeta: $!\n";
    foreach my $ln ( @sorted ) { print $OM $ln . "\n"; }
    close $OM;
  }  # END SUB DWGN


  sub takeoptima
  {
    my ( $sortmixed, $carrier_r, $blockelts_r, $searchname, $orderedfile, $direction, $starorder, $mids_r,
    $blocks_r, $totres, $objectivecolumn, $ordres, $starpositions_r, $countstring, $starnumber, $ordtot,
    $file, $ordmeta, $orderedfile, $dirfiles_r, $countcase, $countblock, $varnums_r, $vehicles_r, $inst_r ) = @_;
    my %carrier = %{ $carrier_r }; #say  "HERE 3 CARRIER: " . dump( \%carrier );
    my @blockelts = @{ $blockelts_r };
    my @blocks = @{ $blocks_r };
    my @starpositions = @{ $starpositions_r };
    my %dirfiles = %{ $dirfiles_r };
    my %varnums = %{ $varnums_r };
    my %vehicles = %{ $vehicles_r };
    my $slicenum = $dirfiles->{slicenum};
    my %inst = %{ $inst_r };
    

    close SORTMIXED;
    my @lines;
    if ( $searchname eq "n" )
    {
      open( SORTMIXED, $sortmixed ) or die( "$!" );
      @lines = <SORTMIXED>;
      close SORTMIXED;
      say "!!!!!IN TAKEOPTINA OPENED \$sortmixed $sortmixed: " . dump ( @lines );
      say "!!!!!IN TAKEOPTINA \$dirfiles{newrandompick}: $dowhat{newrandompick}" ;
    }
    elsif ( $searchname eq "y" )
    {
      open( ORDEREDFILE, $orderedfile ) or die( "$!" );
      @lines = <ORDEREDFILE>;
      close ORDEREDFILE;
      say "!!!!!IN TAKEOPTINA OPENED \$sortmixed $orderedfile: " . dump ( @lines );
    }
    
    
    
    
    



    if ( $slicenum eq "" )
    {
      $slicenum = scalar( @lines ) - 1;
    }

    my $halfremainder = ( ( scalar( @lines ) - $slicenum ) / 2 );
    my $winnerentry;
    if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
    {
      $winnerentry = $lines[0]; #say  "!!! \$winnerenty = \$lines[0]: $winnerenty";
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
      }
    }
    elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
    {
      $winnerentry = $lines[0];
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
      }
    }
    elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
    {
      my $half = ( int( scalar( @lines ) / 2 )  );
      $winnerentry = $lines[ $half ];
      if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
      {
        push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
      }
    }
    chomp $winnerentry;

    my @winnerelms = split( /,/, $winnerentry ); #say  "!!! \@winnerelms: " . dump( @winnerelms );
    my $winneritem = $winnerelms[0]; #say  "!!! \$winneritem: $winneritem";

    #say  "HERE WINNERITEM BEFORE CLEANING: $winneritem.";
    $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );
    #say  "HERE WINNERITEM AFTER CLEANING: $winneritem.";
    push ( @{ $incumbents{$closingelt} }, $winneritem );

    my $message;
    $message = "$mypath/attention.txt";

    open( MESSAGE, ">>$message");
    my $countelm = 0;
    foreach my $elm (@lines)
    {
      chomp $elm;
      my @lineelms = split( /\s+|,/, $elm );
      my $val = $lineelms[$objectivecolumn];
      my $case = $lineelms[0];
      {
        if ($countelm > 0)
        {
          if ( $val ==  $winnerval )
          {
            say MESSAGE "Attention. At case " . ( $countcase + 1 ) . ", block " . ( $countcase + 1 ) . "There is a tie between optimal cases. Besides case $winnerline, producing a compound objective function of $winnerval, there is the case $case producing the same objective function value. Case $winnerline has been used for the search procedures which follow.\n";
          }
        }
      }
      $countelm++;
    }
    close (MESSAGE);

    push( @{ $incumbents{$word} }, $winnerline );

    #if ( $countblock == 0 )
    #{
    #  shift( @{ $winneritems[$countcase][$countblock] } );
    #}



    ################################################### STOP CONDITIONS!

    if ( $countblock == $#blocks )
    {
      #if ( $sourceblockelts[0] =~ />/ )
      #{
      #  $dirfiles{starsign} = "y";
      #}

      
      #if ( ( $dirfiles{starsign} eq "y" ) or
    	#		( ( $dirfiles{random} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{newrandompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{newenumerate} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{neldermead} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{simulatedannealing} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{particleswarm} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{armijo} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{nsgaii} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{nsgaiii} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{moead} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{spea2} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
      #    ( ( $dirfiles{randompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    	#		( ( $dirfiles{latinhypercube} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    	#		( ( $dirfiles{factorial} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    	#		( ( $dirfiles{facecentered} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) ) ### BEGINNING OF THE PART ON STAR CONFIGURATIONS
      if ( $dirfiles{metamodel} eq "y" )
      {
        open( TOTRES, "<$totres" ) or die;
        my @lins = <TOTRES>;
        close TOTRES;



        my @lins = uniq( @lins );
        my @sorted;
        if ( $direction ne "star" )
        {
          if ( $direction eq "<" )
          {
            @sorted = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lins;
          }
          elsif ( $direction eq ">" )
          {
            @sorted = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lins;
          }
          else
          {
            #say  "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }
        }
        elsif ( $direction eq "star" )
        {
          if ( $starorder eq "<" )
          {
            @sorted = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lins;
          }
          elsif ( $starorder eq ">" )
          {
            @sorted = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lins;
          }
          else
          {
            say  "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }
        }


        open( ORDRES, ">>$ordres" ) or die;

        foreach my $lin ( @sorted )
        {
          print ORDRES $lin;
        }
        close ORDRES;


        if ( ( scalar( @starpositions ) > 0 ) and ( $countstring ) )
        {
          open( ORDRES, "$ordres" ) or die;
          my @ordlines = <ORDRES>;
          close ORDRES;

          open( TOTTOT, ">>$tottot" ) or die;
          foreach my $line ( @ordlines )
          {
            print TOTTOT $line;
          }
          close TOTTOT;

          if ( $countstring == $starnumber )
          {
            open( TOTTOT, "<$tottot" ) or die;
            my @totlines = <TOTTOT>;
            close TOTTOT;


            my @lns = uniq( @totlines );
            my @sortedln;
            if ( $direction ne "star" )
            {
              if ( $direction eq "<" )
              {
                @sortedln = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lns;
              }
              elsif ( $direction eq ">" )
              {
                @sortedln = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lns;
              }
              else
              {
                say  "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
              }
            }
            elsif ( $direction eq "star" )
            {
              if ( $starorder eq "<" )
              {
                @sortedln = sort { (split( ',', $a))[ 0 ] <=> ( split( ',', $b))[ 0 ] } @lns;
              }
              elsif ( $starorder eq ">" )
              {
                @sortedln = sort { (split( ',', $b))[ 0 ] <=> ( split( ',', $a))[ 0 ] } @lns;
              }
              else
              {
                say  "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
              }
            }


            open( ORDTOT, ">>$ordtot" ) or die;
            foreach my $ln ( @sortedln )
            {
              print ORDTOT $ln;
            }
            close ORDTOT;
          }
        }

        unless ( $direction eq "star" )
        {
          say  "#Optimal option for case " . ( $countcase + 1 ) . ": $newtarget.";
        }

        @totalcases = uniq( @totalcases );
        my $netinstnum = scalar( @totalcases );

        say  "#Net number of instances: $netinstnum." ;
        open( RESPONSE , ">>$mypath/response.txt" );
        unless ( $direction eq "star" )
        {
          say RESPONSE "#Optimal option for case " . ( $countcase + 1 ) . ": $newtarget.";
        }

        if ( $starstring eq "" )
        {
          #say  "NOT DOING";
          say RESPONSE "#Net number of instances: $netinstnum.\n" ;
        }
        elsif ( $starstring ne "" )
        {
          my @lines = uniq( @lines );
          if ( ( $starorder = ">" ) or ( $direction = ">" ) )
          {
            @lines = sort { (split( ',', $b))[ $objectivecolumn ] <=> ( split( ',', $a))[ $objectivecolumn ] } @lines;
          }
          elsif ( ( $starorder = "<" ) or ( $direction = "<" ) )
          {
            @lines = sort { (split( ',', $a))[ $objectivecolumn ] <=> ( split( ',', $b))[ $objectivecolumn ] } @lines;
          }
          else
          {
            say  "THE OBJECTIVE IS NOT CLEAR IN THE \%dowhat PARAMETER OF THE CONFIGURATION FILE.";
          }

          my $num = scalar( @lines );
          say RESPONSE "#Net number of instances: $num.\n" ;
        }

        say RESPONSE "Order of the parameters: " . dump( @sweeps );
        say RESPONSE "Number of parameter levels: " . dump( @varnumbers );
        say RESPONSE "Last initialization level: " . dump( @miditers );
        say RESPONSE "Descent directions: " . dump( $dowhat{direction} );

        my $metafile = $sortmixed . "_meta.csv";
        my $ordmeta = $sortmixed . "_ordmeta.csv";

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) }; #say  "IN callblock \@blockelts " . dump( @blockelts );
 


        say "!!!!! CALL METAMODEL 1 ";
        metamodel( \%dowhat, $sortmixed, $file, \%dirfiles, \@blockelts, \%carrier, $metafile,
          $direction, $starorder, $ordmeta, \%varnums, $countblock, \@lines );

        my @lines;
        if ( $dirfiles{metamodel} eq "y" )
        {
          open( ORDMETA, $ordmeta ) or die( "$!" );
          @lines = <ORDMETA>;
          close ORDMETA;
        }
        else
        {
          if ( $searchname eq "n" )
          {
            open( SORTMIXED, $sortmixed ) or die( "$!" );
            @lines = <SORTMIXED>;
            close SORTMIXED;
          }
          elsif ( $searchname eq "y" )
          {
            open( ORDEREDFILE, $orderedfile ) or die( "$!" );
            @lines = <ORDEREDFILE>;
            close ORDEREDFILE;
          }
        }

        if ( $slicenum eq "" )
        {
          $slicenum = scalar( @lines ) - 1;
        }

        my $winnerentry;
        if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
          }
        }
        chomp $winnerentry;


        if ( $dirfiles{popsupercycle} = "y" )
        {
          $dirfiles{launching} = "y";
          my $revealnum = $dirfiles{revealnum} - 1;
          my $revealfile = $file . "_" . "reveal-" . "$countcase-$countblock.csv";
          my @group = @lines[0..$revealnum];
          my @reds;
          foreach my $el ( @group )
          {
            my @els = split( ",", $el );
            push( @reds, $els[0] );
          }

          my $c = 0;
          foreach my $instance ( @{ $vehicles{cumulateall} } )
          {
            if ( $instance->{is} ~~ @reds )
            {
              my @instancees;
              push( @instancees, $instance );
              if ( $dowhat{morph} eq "y" )
              {
                say  "#Calling morphing operations for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my @result = Sim::OPT::Morph::morph( $configfile, \@instancees, \%dirfiles, \%dowhat, \%vehicles, \%inst );
              }
 
              my( $packet_r, $dirfiles_r );
              if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
              {
                say  "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                ( $packet_r, $dirfiles_r, $csim ) = Sim::OPT::Sim::sim(
                    { instances => \@instancees, dirfiles => \%dirfiles, dowhat => \%dowhat, vehicles => \%vehicles, inst => \%inst } );
                @packet = uniq( @$packet_r ); say  "RECEIVED PACKET " . dump( @packet );
                %dirfiles = %$dirfiles;
              }
            }
          }
          if ( $dowhat{metamodel} eq "y" )
          {
            $dirfiles{nestclock} = $dirfiles{nestclock} - 1;
          }
          $dirfiles{launching} = "n";
        }

        my @winnerelms = split( /,/, $winnerentry ); #say  "!!!! \@winnerelms: " . dump( @winnerelms );
        my $winneritem = $winnerelms[0]; #say  "!!!! \$winnerelms[0]: " . dump( $winnerelms[0] );

        $countblock = 0;
        $countcase++; ####!!!

        $countstring++;
        $dirfiles{countstring} = $countstring;


        ###DDDTHIS
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );




        if ( ( ( ( $dowhat{names} eq "short" ) or ( $dowhat{names} eq "medium" ) ) ) and ( $winneritem =~ /^\d+$/ ) )
        {
          my $clear = $inst{$winneritem};
          if ( (!defined($clear) ) or ( $clear eq "") )
          {
            my $k = "$mypath/$file" . "_" . $winneritem;
            $clear = $inst{$k};
          }

          if ( ( !defined($clear) ) and ( $clear eq "" ) )
          {
            die "Cannot map crypto winner '$winneritem' to clear instance (names=short)";
          }
            
          $winneritem = $clear;
        }



        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );



        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };
        say  "WINNERITEMS: " . dump( @winneritems );
        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, incumbents => \%incumbents, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      } ### END OF THE PART ON STAR CONFIGURATIONS
      else
      {
        say  "IN CASE END NOT STARSIGN.";
        $countblock = 0;
        $countcase++; ####!!!

        $countstring++;
        $dirfiles{countstring} = $countstring;
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );
        say  "\$winneritem: " . dump( $winneritem );
        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );
        say  "WINNERITEMS: " . dump( @winneritems );
        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, incumbents => \%incumbents, dowhat => \%dowhat ,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      }
    }
    elsif( $countblock < $#blocks )
    {
      if ( ( $dirfiles{starsign} eq "y" ) or
    			( ( $dirfiles{random} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
          ( ( $dirfiles{randompick} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    			( ( $dirfiles{latinhypercube} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    			( ( $dirfiles{factorial} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) or
    			( ( $dirfiles{facecentered} eq "y" ) and ( $dowhat{metamodel} eq "y" ) ) )
      { ### BEGINNING OF THE PART ABOUT STAR CONFIGURATIONS
        my $metafile = $sortmixed . "_tmp_meta.csv";
        my $ordmeta = $sortmixed . "_ordmeta.csv";

        my @blockelts = @{ Sim::OPT::getblockelts( \@sweeps, $countcase, $countblock ) };
        
        say "!!!!! CALL METAMODEL 1 ";
        metamodel( \%dowhat, $sortmixed, $file, \%dirfiles, \@blockelts, \%carrier, $metafile,
          $direction, $starorder, $ordmeta, \%varnums, $countblock, \@lines );

        my @lines;
        if ( $dirfiles{metamodel} eq "y" )
        {
          open( ORDMETA, $ordmeta ) or die( "$!" );
          @lines = <ORDMETA>;
          close ORDMETA;
        }
        else
        {
          if ( $searchname eq "n" )
          {
            open( SORTMIXED, $sortmixed ) or die( "$!" );
            @lines = <SORTMIXED>;
            close SORTMIXED;
          }
          elsif ( $searchname eq "y" )
          {
            open( ORDEREDFILE, $orderedfile ) or die( "$!" );
            @lines = <ORDEREDFILE>;
            close ORDEREDFILE;
          }
        }

        my $winnerentry;
        if ( ( $direction eq ">" ) or ( ( $direction eq "star"  ) and ( $starorder eq ">"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "<" ) or ( ( $direction eq "star"  ) and ( $starorder eq "<"  ) ) )
        {
          $winnerentry = $lines[0];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[0..$slicenum]);
          }
        }
        elsif ( ( $direction eq "=" ) or ( ( $direction eq "star"  ) and ( $starorder eq "="  ) ) )
        {
          my $half = ( int( scalar( @lines ) / 2 )  );
          $winnerentry = $lines[ $half ];
          if ( scalar( @{ $vehicles{nesting}{$dirfiles{nestclock}} } ) > 0 )
          {
            push( @{ $vehicles{$countcase}{$countblock} }, @lines[$halfremainder..(-$halfremainder)]);
          }
        }
        chomp $winnerentry;

        if ( $dirfiles{popsupercycle} = "y" )
        {
          $dirfiles{launching} = "y";
          my $revealnum = $dirfiles{revealnum} - 1;
          my $revealfile = $file . "_" . "reveal-" . "$countcase-$countblock.csv";
          my @group = @lines[0..$revealnum];
          my @reds;
          foreach my $el ( @group )
          {
            my @els = split( ",", $el );
            push( @reds, $els[0] );
          }

          my $c = 0;
          foreach my $instance ( @{ $vehicles{cumulateall} } )
          {
            if ( $instance->{is} ~~ @reds )
            {
              my @instancees;
              push( @instancees, $instance );
              if ( $dowhat{morph} eq "y" )
              {
                say  "#Calling morphing operations for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                my @result = Sim::OPT::Morph::morph( $configfile, \@instancees, \%dirfiles, \%dowhat, \%vehicles, \%inst );
              }

              my( $packet_r, $dirfiles_r );
              if ( ( $dowhat{simulate} eq "y" ) or ( $dowhat{newreport} eq "y" ) )
              {
                #say  "#Calling simulations, reporting and retrieving for instance $instance{is} in case " . ($countcase +1) . ", block " . ($countblock + 1) . ".";
                ( $packet_r, $dirfiles_r, $csim ) = Sim::OPT::Sim::sim(
                    { instances => \@instancees, dirfiles => \%dirfiles, dowhat => \%dowhat, vehicles => \%vehicles, inst => \%inst } );
                    @packet = uniq( @$packet_r ); say  "RECEIVED PACKET " . dump( @packet );
                    %dirfiles = %$dirfiles;
              }
              #if ( $dowhat{descend} eq "y" )
              #{
              #	#say  "#Calling descent for case " . ($countcase + 1) . ", block " . ($countblock + 1) . ".";
              #	#say  "\@sourcesweeps: " . dump( @sourcesweeps );
              #	Sim::OPT::Descend::descend(	{ instances => \@instancees, dirfiles => \%dirfiles, vehicles => \%vehicles } );
              #}
            }
          }
          $dirfiles{launching} = "n";
        }

        my @winnerelms = split( /,/, $winnerentry );
        my $winneritem = $winnerelms[0];

        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );

        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );

        @varnumbers = @{ dclone( $dirfiles{varnumbershold} ) };
        @miditers = @{ dclone( $dirfiles{miditershold} ) };

        $countblock++; ### !!!        push ( @{ $winneritems[$countcase][$countblock + 1] }, $winneritem );
        say  "WINNERITEMS: " . dump( @winneritems );
        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, incumbents => \%incumbents, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      } ### END OF THE PART ABOUT STAR CONFIGURATIONS
      else
      { #say  "!!!! RELAUNCHING WITH INST " . dump( %inst ); 
        $winneritem = Sim::OPT::clean( $winneritem, $mypath, $file );
        say  "!!!! \winneritem: " . dump( @winneritem );
        push ( @{ $winneritems[$countcase][$countblock+1] }, $winneritem );
        say  "!!!! WINNERITEMS: " . dump( @winneritems );
        $countblock++; ### !!!

        Sim::OPT::callblock( { countcase => $countcase, countblock => $countblock,
        miditers => \@miditers,  winneritems => \@winneritems,
        dirfiles => \%dirfiles, varnumbers => \@varnumbers,
        sweeps => \@sweeps, incumbents => \%incumbents, dowhat => \%dowhat,
        sourcesweeps => \@sourcesweeps, instn => $instn, inst => \%inst, vehicles => \%vehicles } );
      }
    }
  } # END SUB takeoptima

  #say  "IN DESCEND BEFORE TAKEOPTIMA; INST " . dump( %inst );
  #say  "HERE 2 CARRIER: " . dump( \%carrier );
  takeoptima( $sortmixed, \%carrier, \@blockelts, $searchname, $orderedfile, $direction, $starorder,
  \%mids, \@blocks, $totres, $objectivecolumn, $ordres, \@starpositions, $countstring, $starnumber,
  $ordtot, $file, $ordmeta, $orderedfile, \%dirfiles, $countcase, $countblock, \%varnums, \%vehicles, \%inst ); #say  "TAKEOPTIMA \$sortmixed : " . dump( $sortmixed );
  close OUTFILE;
  close TOFILE;
}    # END SUB descend

# TO DO: TEST NUM META WINNERS.

1;

__END__

=head1 NAME

Sim::OPT::Descend.

=head1 SYNOPSIS

  use Sim::OPT;
  opt;

=head1 DESCRIPTION

Sim::OPT::Descent is a module collaborating with the Sim::OPT module for performing block coordinate descent or parallel blocks search, or free mixes of the two. It closes the circularly recursive loop formed by Sim::OPT -> Sim::OPT::Morph -> Sim::OPT::Sim -> Sim::OPT::Report::report -> Sim::OPT::Descent, which repeats at every search cycle.

The objective function for rating the performances of the candidate solutions can be obtained by the weighting of objective functions (performance indicators) performed by the Sim::OPT::Report module, which follows user-specified criteria.

This module is dual-licensed, open-source and proprietary. The open-source distribution is available on CPAN (https://metacpan.org/dist/Sim-OPT ). A proprietary distribution, including additional modules (OPTcue), is available from the author’s website (https://sites.google.com/view/bioclimatic-design/home/software ).

=head2 EXPORT

"descend".

=head1 SEE ALSO

An example of configuration file for block search ("des.pl") is packed in "optw.zip" file in "examples" directory in this distribution. But mostly, reference to the source code may be made.

=head1 AUTHOR

Gian Luca Brunetti, E<lt>gianluca.brunetti@polimi.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2025 by Gian Luca Brunetti, gianluca.brunetti@gmail.com. This software is distributed under a dual licence, open-source (GPL v3) and proprietary. The present copy is proprietary. The open-source, GPL version of it can be found at https://metacpan.org/dist/Sim-OPT.


=cut
