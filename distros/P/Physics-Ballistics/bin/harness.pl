#!/usr/bin/perl
package BallisticHarness;

# TODO: Really need to port most of this code into Physics::Ballistics!
# This script *should* be nothing more than a light wrapper around Physics::Ballistics.

use strict;
use warnings;

use JSON;
use File::Slurp;
use IPC::Open3;
use lib "/home/ttk/modules";
use lib "./lib";  # For running from the repo root
use Physics::Ballistics::Internal;
use Physics::Ballistics::External;
use Physics::Ballistics::Terminal;

my $CART_HR = {
  '556nato' => {
    'barrel_len_in'    => 20,
    'bullet_diam_in'   => 0.224,
    'neck_diam_in'     => 0.253,
    'shoulder_diam_in' => 0.354,
    'base_diam_in'     => 0.377,
    'rim_diam_in'      => 0.378,
    'rim_thick_in'     => 0.045,
    'case_len_in'      => 1.760,
    'overall_len_in'   => 2.260,
    'grains_to_fps' => {62 => 3100, 63 => 3070, 77 => 2679}
  },
  '6ppc' => {
    'barrel_len_in'    => 24,
    'bullet_diam_in'   => 0.243,
    'neck_diam_in'     => 0.262,
    'shoulder_diam_in' => 0.431,
    'base_diam_in'     => 0.441,
    'rim_diam_in'      => 0.445,
    'rim_thick_in'     => 0.050,  # estimate
    'case_len_in'      => 1.515,
    'overall_len_in'   => 2.100,
    'grains_to_fps' => {60 => 3300, 70 => 3250},
  },
  '243wssm' => {
    'barrel_len_in'    => 24,
    'bullet_diam_in'   => 0.243,
    'neck_diam_in'     => 0.291,
    'shoulder_diam_in' => 0.544,
    'base_diam_in'     => 0.555,
    'rim_diam_in'      => 0.535,
    'rim_thick_in'     => 0.054,
    'case_len_in'      => 1.670,
    'overall_len_in'   => 2.360,
    'grains_to_fps' => {58 => 4065, 70 => 3705, 80 => 3545, 85 => 3410, 90 => 3280, 100 => 3136}
  },
  '68spc' => {
    'barrel_len_in'    => 16,
    'bullet_diam_in'   => 0.277,
    'neck_diam_in'     => 0.298,
    'shoulder_diam_in' => 0.402,
    'base_diam_in'     => 0.421,
    'rim_diam_in'      => 0.422,
    'rim_thick_in'     => 0.049,
    'case_len_in'      => 1.676,
    'overall_len_in'   => 2.315,
    'grains_to_fps' => {85 => 2860, 90 => 2750, 100 => 2630, 110 => 2540, 115 => 2500, 120 => 2460, 123 => 2430},
    },
  '65grendel' => {
    'barrel_len_in'    => 24,
    'bullet_diam_in'   => 0.264,
    'neck_diam_in'     => 0.293,
    'shoulder_diam_in' => 0.428,
    'base_diam_in'     => 0.439,
    'rim_diam_in'      => 0.440,
    'rim_thick_in'     => 0.059,
    'case_len_in'      => 1.520,
    'overall_len_in'   => 2.260,
    'grains_to_fps' => {90 => 2880, 108 => 2790, 120 => 2700, 123 => 2650, 130 => 2510},
    },
  '65x47lapua' => {
    'barrel_len_in'    => 27.5,
    'bullet_diam_in'   => 0.264,
    'neck_diam_in'     => 0.292,
    'shoulder_diam_in' => 0.454,
    'base_diam_in'     => 0.470,
    'rim_diam_in'      => 0.473,
    'rim_thick_in'     => 0.054,
    'case_len_in'      => 1.900,
    'overall_len_in'   => 2.650,  # estimated
    'grains_to_fps' => {103 => 3080, 123 => 2900, 139 => 2700},
    },
  '762nato' => {
    'barrel_len_in'    => 24,
    'bullet_diam_in'   => 0.308,
    'neck_diam_in'     => 0.345,
    'shoulder_diam_in' => 0.454,
    'base_diam_in'     => 0.470,
    'rim_diam_in'      => 0.473,
    'rim_thick_in'     => 0.050,
    'case_len_in'      => 2.015,
    'overall_len_in'   => 2.750,
    'link_weight_gr'   => 62,
    'grains_to_fps' => {147 => 2733, 175 => 2580},
    },
  '762x54r' => {
    'barrel_len_in'    => 28,
    'bullet_diam_in'   => 0.312,
    'neck_diam_in'     => 0.336,
    'shoulder_diam_in' => 0.457,
    'base_diam_in'     => 0.487,
    'rim_diam_in'      => 0.567,
    'rim_thick_in'     => 0.063,
    'case_len_in'      => 2.115,
    'overall_len_in'   => 3.038,
    'grains_to_fps' => {150 => 2840, 174 => 2610, 181 => 2600},
    },
  '338nm' => {
    'barrel_len_in'    => 24,     # General Dynamics Lightweight Medium Machine Gun
    'bullet_diam_in'   => 0.339,
    'neck_diam_in'     => 0.370,
    'shoulder_diam_in' => 0.571,
    'base_diam_in'     => 0.585,
    'rim_diam_in'      => 0.588,
    'rim_thick_in'     => 0.060,
    'case_len_in'      => 2.492,
    'overall_len_in'   => 3.681,
    'link_weight_gr'   => 124,
    'grains_to_fps' => {300 => 2650}, # Sierra HPBT FMJ AP
    },
  '45mmG' => {
    'barrel_len_in'    => 16,
    'bullet_diam_in'   => 1.77,
    'neck_diam_in'     => 1.77,
    'shoulder_diam_in' => 1.77,
    'base_diam_in'     => 1.77,
    'rim_diam_in'      => 1.77,
    'rim_thick_in'     => 0.01,
    'case_len_in'      => 3.55,
    'overall_len_in'   => 7.00,
    'link_weight_gr'   => 5000,
    'grains_to_fps' => {15500 => 680, 31000 => 480, 46500 => 380, 62000 => 280}  # 1kg, 2kg, 3kg, 4kg, est via gunfire()
    }
};

my @REQUIRED_FIELDS = qw(cartridge_name  bullet_grains  shape  barrel_len_inches  max_range_yards);
my @DYNAMIC_FIELDS  = qw(c v bc shape_used filled);


my ($CTL_HR, $DOC_AR) = parse_args(\@ARGV);
my $SELF = {
  ctl_hr   => $CTL_HR,
  doc_ar   => $DOC_AR,
  cart_hr  => $CART_HR,
  graph_ar => []  # list of {label, filename}
};
bless($SELF, "BallisticHarness");

exit(main($SELF));

sub main {
  my ($self) = @_;
  my ($ok, @errs);

  my $filenames_ar = undef;
  if ($self->opt('stdin', 0)) {
    my $got_errors = 0;
    while(defined(my $js = <STDIN>)) {
      chomp($js);
      my $hr = JSON::from_json($js);
      $self->reset_the_blanks();
      $self->{cartridge_name}     = $hr->{cartridge_name}    || $self->opt('cart',  '243wssm');
      $self->{bullet_grains}      = $hr->{bullet_grains}     || $self->opt('mass',   80);
      $self->{shape}              = $hr->{shape}             || $self->opt('shape', 'spitzer');
      $self->{barrel_len_inches}  = $hr->{barrel_len_inches} || $self->opt('barrel_len', 14.5);
      $self->{max_range_yards}    = $hr->{max_range_yards}   || $self->opt('max_range',  1000);
      ($ok, @errs) = $self->_main_achtung();
      if ($ok ne 'OK') {
        if ($self->opt('keep_going', 0)) {
           $got_errors = 1;
           print STDERR "ERROR: ".join("\n", ($filenames_ar, @errs))."\n";
        } else {
           die(join("\n", @errs));
        }
      }
    }
    ($ok, $filenames_ar, @errs) = $self->finalize_graphs() if ($self->opt('graph', 0));
    die("ERRORS\n") if ($got_errors);
  } else {

    $self->{cartridge_name}     = $self->opt('cart',  '243wssm');
    $self->{bullet_grains}      = $self->opt('mass',   80);
    $self->{shape}              = $self->opt('shape', 'spitzer');
    $self->{barrel_len_inches}  = $self->opt('barrel_len', 14.5);
    $self->{max_range_yards}    = $self->opt('max_range',  1000);

    ($ok, $filenames_ar, @errs) = $self->_main_achtung();
    die(join("\n",($filenames_ar, @errs))) unless ($ok eq 'OK');
  }

  # print JSON::to_json({filenames_ar => $filenames_ar})."\n";
  print join("\n",@{$filenames_ar})."\n" if (defined($filenames_ar));
  return 0;
}

sub _main_achtung {
  my ($self) = @_;

  my ($ok, @errs) = $self->fill_in_the_blanks();
  my $filenames_ar = undef;

  if ($self->opt('graph')) {
    my $sim_ar;

    ($ok, $sim_ar, @errs) = $self->sim();
    return ($ok, $sim_ar, @errs) unless ($ok eq 'OK');

    ($ok, @errs) = $self->make_graphs($sim_ar);
    return ($ok, @errs) unless ($ok eq 'OK');

    ($ok, $filenames_ar, @errs) = $self->finalize_graphs() unless ($self->opt('stdin', 0));
    return ($ok, $filenames_ar, @errs) unless ($ok eq 'OK');
  }

  return ('OK', $filenames_ar)
}

sub sim {
  my ($self) = @_;

  my ($ok, @errs) = $self->fill_in_the_blanks();
  return ($ok, @errs) unless ($ok eq 'OK');

  my $sim_ar = Physics::Ballistics::External::flight_simulator('G1', $self->{bc}, $self->{v}, 1.5, 0.5, -1, 100, 0, 0, $self->{max_range_yards});
  return ('OK', $sim_ar);
}

sub make_graphs {
  my ($self, $sim_ar) = @_;

  my ($ok, @errs) = $self->fill_in_the_blanks();
  return ($ok, @errs) unless ($ok eq 'OK');

  my $grams = $self->{bullet_grains} * 0.06479891;  # for calculating momentum
  my $filelabel = "$self->{cartridge_name}, $self->{bullet_grains}gr, $self->{shape_used}";
  my $filename  = "Balls.".join('.', split(/, /, $filelabel)).".$self->{barrel_len_inches}_inch_brl.$self->{max_range_yards}_yards.tab";
  my $success = 0;
  eval { File::Slurp::write_file($filename, ''); $success = 1; };
  return ('ERROR', $@) unless ($success);

  foreach my $r (@{$sim_ar}) {
    my $vel_mps = $r->{vel_fps} * 0.3048;
    my $vel_cps = $vel_mps * 100;
    $r->{momentum_kboles} = int($grams * $vel_cps / 1000); # bole = g cm / 2
    $r->{pen_cinder_inches} = Physics::Ballistics::Terminal::pc($self->{bullet_grains}, $r->{vel_fps}, $r->{range_yards}*3, $self->{c}->{bullet_diam_in}, 'ms', 'cinder') / 25.4;
    $r->{hits_score}  = Physics::Ballistics::Terminal::hits_score($self->{bullet_grains}, $r->{vel_fps}, $self->{c}->{bullet_diam_in});
    $r->{ke_joules}   = int(Physics::Ballistics::External::muzzle_energy($self->{bullet_grains}, $r->{vel_fps}, 1));
    $r->{vel_fps}     = int($r->{vel_fps} + 0.5);
    $r->{range_yards} = int($r->{range_yards} + 0.5);
    $r->{drop_inches} = int($r->{drop_inches} + 0.5);
    File::Slurp::append_file($filename, join("\t", ($r->{range_yards}, $r->{vel_fps}, $r->{momentum_kboles}, $r->{ke_joules}, $r->{pen_cinder_inches}, $r->{hits_score}))."\n");
  }
  push(@{$self->{graphs_ar}}, [$filelabel, $filename]);
  return 'OK';
}

sub _run_gnuplot {
  my ($self, $plot_name, $axes, $plot_title) = @_;
  my $filename = "gnuplot.$plot_name.gp";
  my $s = "set title \"$plot_title\"\nset terminal jpeg xFFFFFF\nplot ";
  foreach my $tup (@{$self->{graphs_ar}}) {
    my ($label, $filename) = @{$tup};
    $s .= "\"$filename\" using $axes title \"$label\" with lines, ";
  }
  chop($s); chop($s);
  my ($success, $kid, $wr_h, $rd_h) = (0, undef, undef, undef);
  my $gnuplot_cmd = $self->opt('gnuplot_cmd', '/usr/bin/gnuplot');
  my $filepath_prefix = $self->opt('gnuplot_filepath_prefix', '/tmp');
  my $file_title = join("_", split(/\s+/, $plot_title));
  my $out_filename = "$filepath_prefix/graph.$file_title.jpg";
  if (defined(my $file_label = $self->opt('file_label', undef))) {
    $out_filename = "$filepath_prefix/graph.$file_label.$file_title.jpg";
  }
  eval { $kid = open3 ($wr_h, $rd_h, undef, "$gnuplot_cmd > $out_filename"); $success = 1; };
  return ('ERROR', 'failed to open gnuplot', $@) unless ($success);
  print $wr_h "$s\n";
  close($wr_h);
  waitpid($kid, 0);
  return ('OK', $out_filename);
}

sub finalize_graphs {
  my ($self) = @_;
  my @filename_list = ();

  my ($ok, $filename, @errs) = $self->_run_gnuplot("velocity_vs_range", "1:2", "velocity fps vs range yards");
  return ($ok, $filename, @errs) unless ($ok eq 'OK');
  push (@filename_list, $filename);

  ($ok, $filename, @errs) = $self->_run_gnuplot("momentum_vs_range", "1:3", "momentum Kboles vs range yards");
  return ($ok, $filename, @errs) unless ($ok eq 'OK');
  push (@filename_list, $filename);

  ($ok, $filename, @errs) = $self->_run_gnuplot("ke_vs_range", "1:4", "energy joules vs range yards");
  return ($ok, $filename, @errs) unless ($ok eq 'OK');
  push (@filename_list, $filename);

  ($ok, $filename, @errs) = $self->_run_gnuplot("pen_cinder_vs_range", "1:5", "penetration of cinder inches vs range yards");
  return ($ok, $filename, @errs) unless ($ok eq 'OK');
  push (@filename_list, $filename);

  ($ok, $filename, @errs) = $self->_run_gnuplot("hits_vs_range", "1:6", "HITS score vs range yards");
  return ($ok, $filename, @errs) unless ($ok eq 'OK');
  push (@filename_list, $filename);

  return ('OK', \@filename_list);
}

sub reset_the_blanks {
  my ($self) = @_;
  foreach my $f (@DYNAMIC_FIELDS) {
    delete $self->{$f} if (defined($self->{$f}));
  }
  return 'OK';
}

sub fill_in_the_blanks {
  my ($self) = @_;

  return 'OK' if (defined($self->{filled}));

  my @missing_fields = ();
  foreach my $f (@REQUIRED_FIELDS) {
    push(@missing_fields, $f) unless (defined($self->{$f}));
  }

  return ('ERROR', 'missing required fields', @missing_fields) unless (scalar(@missing_fields) == 0);  
  return ('ERROR', 'bad cartridge name') unless (defined($self->{cart_hr}->{$self->{cartridge_name}}));
  return ('ERROR', 'bad bullet weight' ) unless ($self->opt('guess_muzzle_velocity',0) || defined($self->{cart_hr}->{$self->{cartridge_name}}->{grains_to_fps}->{$self->{bullet_grains}}));

  $self->{c} = $self->{cart_hr}->{$self->{cartridge_name}};

  my ($blt_diam, $case_diam, $case_len, $brl1, $brl2) = ($self->{c}->{bullet_diam_in}, $self->{c}->{base_diam_in}, $self->{c}->{case_len_in}, $self->{c}->{barrel_len_in}, $self->{barrel_len_inches});
  # print ("blt_diam=$blt_diam case_diam=$case_diam case_len=$case_len brl1=$brl1 brl2=$brl2\n");
  my $velocity_factor = Physics::Ballistics::Internal::powley($blt_diam, $case_diam, $case_len, $brl1, $brl2);
  my $ballistics_str  = Physics::Ballistics::External::ebc($self->{bullet_grains}, $self->{c}->{bullet_diam_in}, $self->{shape});
  return ('ERROR', 'failed to parse ebc results', $ballistics_str) unless ($ballistics_str =~ /^bc=([\d\.]+).*?shape=([^\s]+)/);
  my $bc = $1;
  my $shape_used = $2;

  my $base_velocity   = $self->ascertain_muzzle_velocity();
  $self->{v}          = $velocity_factor * $base_velocity;  # velocity, fps
  $self->{bc}         = $bc;
  $self->{shape_used} = $shape_used;
  $self->{filled}     = 1;

  return 'OK';
}

sub ascertain_muzzle_velocity {
  my ($self) = @_;
  my $gr     = $self->{bullet_grains};
  my $gv_hr  = $self->{c}->{grains_to_fps};
  my @masses = sort { $a <=> $b } keys %{$gv_hr};
  my $k      = scalar(@masses)-1;

  # If we know a mv from empirical data, just return it.
  return $gv_hr->{$gr} if (defined($gv_hr->{$gr}));

  # If we're off either end, extrapolate:
  return $self->_extrapolate_mv($gr, $gv_hr, $masses[   1], $masses[   0]) if ($gr < $masses[0]);
  return $self->_extrapolate_mv($gr, $gv_hr, $masses[$k-1], $masses[$k-0]) if ($gr > $masses[$k]);

  # Figure out where $gr lies relative to @masses:
  # I could implement a proper binary-search here, but @masses is so tiny, why bother?
  my $ix = int(scalar(@masses) / 2);
  while ($gr < $masses[$ix]) { $ix--; }
  while ($gr > $masses[$ix]) { $ix++; }
  # Now $masses[$ix-1] < $gr < $masses[$ix]
  my $m0 = $masses[$ix-1];
  my $m1 = $masses[$ix];
  my $d0 = $gr - $m0;  # Distance to lower  mass
  my $d1 = $m1 - $gr;  # Distance to higher mass
  my $dm = $m1 - $m0;  # Distance between endpoint masses
  my $p0 = $d0 / $dm;  # Fraction of total distance taken by lower  difference.
  my $p1 = $d1 / $dm;  # Fraction of total distance taken by higher difference.
  my $e0 = Physics::Ballistics::External::muzzle_energy($m0, $gv_hr->{$m0}, 1);
  my $e1 = Physics::Ballistics::External::muzzle_energy($m1, $gv_hr->{$m1}, 1);
  my $nrg= $e0 * $p1 + $e1 * $p0;  # Estimated muzzle energy, in joules
  my $fp = $nrg / 1.3558179;       # Estimated muzzle energy, in foot-pounds
  my $mv = Physics::Ballistics::External::muzzle_velocity_from_energy($gr, $fp);
  return $mv;
}

# _extrapolate_mv($gr, $gv_hr, $masses[   1], $masses[   0]) if ($gr < $masses[0]);
# _extrapolate_mv($gr, $gv_hr, $masses[$k-1], $masses[$k-0]) if ($gr > $masses[$k]);
# returns a velocity, feet per second
sub _extrapolate_mv {
  my ($self, $gr, $gv_hr, $m0, $m1) = @_;
  my $e0 = Physics::Ballistics::External::muzzle_energy($m0, $gv_hr->{$m0}, 1);
  my $e1 = Physics::Ballistics::External::muzzle_energy($m1, $gv_hr->{$m1}, 1);
  my $ed = $e1 - $e0;
  my $d0 = $m1 - $m0;
  my $d1 = $gr - $m1;
  my $rr = $ed / $d0;
  my $nrg= $rr * $d1;
  my $fp = $nrg / 1.3558179;
  my $mv = Physics::Ballistics::External::muzzle_velocity_from_energy($gr, $fp);
  return $mv;
}

sub parse_args {
    my $argv_ar;
    my $opt_hr = { v => 1 };
    my @args_a = ();
    if (scalar(@_) > 1) {
        $argv_ar = \@_;
    }
    elsif (scalar(@_) == 1) {
        $argv_ar = $_[0];
        $argv_ar = [$argv_ar] unless (ref($argv_ar) eq 'ARRAY');
    }
    else {
        return ($opt_hr, \@args_a);
    }
    foreach my $arg (@{$argv_ar}) {
        if    ($arg =~ /^\-(v+)$/) {
            $opt_hr->{'v'} = length($1) + 1;
        }
        elsif ($arg eq '-q') {
            $opt_hr->{'v'} = 0;
        }
        elsif ($arg =~ /^\-([^-].*)$/) {
            my $many_short_args = $1;
            foreach my $c (split(//, $many_short_args)) {
                if ($c eq 'q') {
                    $opt_hr->{'v'} = 0;
                }
                elsif ($c eq 'v') {
                    $opt_hr->{'v'}++;
                }
                else {
                    $opt_hr->{$c} = -1;
                }
            }
        }
        elsif ($arg =~ /^\-\-+(.*?)=json:(.*)/) {
            $opt_hr->{_parse_args_helper($1)} = JSON::from_json($2);
        }
        elsif ($arg =~ /^\-\-+(.*?)=(.*)/) {
            $opt_hr->{_parse_args_helper($1)} = $2;
        }
        elsif ($arg =~ /^\-\-+(.*)/) {
            $opt_hr->{_parse_args_helper($1)} = -1;
        }
        else {
            push(@args_a, $arg);
        }
    }
    return ($opt_hr, \@args_a);
}

sub _parse_args_helper {
    my ($s) = @_;
    return join('_', split(/-/, $s));
}

sub opt {
  my($self, $name, $default_value, $opt_hr) = @_;
  $opt_hr //= {};
  return $opt_hr->{$name} // $self->{ctl_hr}->{$name} // $default_value;
}

1;

