
######################################################################
######################################################################
######################################################################
###
###
### PGPLOT interface to PDL::Graphics::Simple.
###
### See the PDL::Graphics::Simple docs for details
###
##
#

package PDL::Graphics::Simple::PGPLOT;

use strict;
use warnings;
use File::Temp qw/tempfile/;
use PDL::Options q/iparse/;

use PDL;

our $mod = {
    shortname => 'pgplot',
    module=>'PDL::Graphics::Simple::PGPLOT',
    engine => 'PDL::Graphics::PGPLOT::Window',
    synopsis=> 'PGPLOT (venerable but trusted)',
    pgs_api_version=> '1.012',
};
PDL::Graphics::Simple::register( $mod );
print $@;

sub check {
  my $force = shift;
  $force = 0 unless(defined($force));
  return $mod->{ok} unless( $force or !defined($mod->{ok}) );
  eval { require PDL::Graphics::PGPLOT::Window; PDL::Graphics::PGPLOT::Window->import; };
  if ($@) {
    $mod->{ok} = 0;
    $mod->{msg} = $@;
    return 0;
  }
  # Module loaded OK, now try to extract valid devices from it
  eval {
    my %devs;
    PGPLOT::pgqndt(my $n);
    for my $count (1..$n) {
      PGPLOT::pgqdt($count,my ($type,$v1,$descr,$v2,$v3));
      $devs{substr $type, 1} = 1; # chop off "/"
    }
    $mod->{devices} = \%devs;
  };
  if ($@) {
    $mod->{ok} = 0;
    $mod->{msg} = $@;
    return 0;
  }
  delete $mod->{disp_dev};
  if ($ENV{PDL_SIMPLE_DEVICE} || $ENV{PGPLOT_DEV}) {
    $mod->{disp_dev} = $ENV{PDL_SIMPLE_DEVICE} || $ENV{PGPLOT_DEV};
    $mod->{disp_dev} =~ s#^/+##;
  } else {
    TRY:for my $try (qw/XWINDOW XSERVE CGW GW/) {
      if ($mod->{devices}->{$try}) {
        $mod->{disp_dev} = $try;
        last TRY;
      }
    }
  }
  unless (exists($mod->{disp_dev})) {
    $mod->{ok} = 0;
    $mod->{msg} = "Couldn't identify a PGPLOT display device -- giving up.\n";
    return 0;
  }
  unless ($mod->{devices}{VCPS}) {
    $mod->{ok} = 0;
    $mod->{msg} = "Couldn't find the VCPS file-output device -- giving up.\n";
    return 0;
  }
  $mod->{pgplotpm_version} = $PGPLOT::VERSION;
  { PGPLOT::pgqinf('VERSION', $mod->{pgplot_version}, my $len); }
  $mod->{ok} = 1;
  return 1;
}

##########
# PDL::Graphics::Simple::PGPLOT::new
our $new_defaults ={
    size => [8,6,'in'],
    type => '',
    output=>'',
    multi=>undef
};

our $filetypes = {
    png => 'PNG',
    ps  => 'VCPS'
};

sub new {
    my $pkg = shift;
    my $opt_in = shift;
    my $opt = { iparse( $new_defaults, $opt_in ) };

    # Force a recheck on failure, in case the user fixed PGPLOT.
    # Also loads PDL::Graphics::PGPLOT::Window.
    unless(check()) {
	die "$mod->{shortname} appears nonfunctional: $mod->{msg}\n" unless(check(1));
    }

    # Figure the device name and size to feed to PGPLOT.
    # size has already been regularized.
    my $conv_tempfile;
    my $dev;

    if( $opt->{type} =~ m/^i/i) {
	$dev = ( $opt->{output} // "" ) . "/$mod->{disp_dev}";
    } else {
	my $ext;

	if($PDL::VERSION < 3  and ($PDL::VERSION > 2.1  or  $PDL::VERSION < 2.005)) {
	    print STDERR "WARNING - file output shapes vary under PDL < 2.005 (early version: $PDL::VERSION)\n";
	}

	if( $opt->{output} =~ m/\.(\w{2,4})$/ ) {
	    $ext = $1;
	} else {
	    $ext = 'png';
	    $opt->{output} .= ".png";
	}

	unless ($filetypes->{$ext}  and  $mod->{devices}{$filetypes->{$ext}}) {
	    my($fh);
	    ($fh, $conv_tempfile) = tempfile('pgs_pgplot_XXXX');
	    close $fh;
	    unlink $conv_tempfile; # just to be sure...
	    $conv_tempfile .= ".ps";
	    $dev = "$conv_tempfile/VCPS";
	} else {
	    $dev = "$opt->{output}/$filetypes->{$ext}";
	}
    }

    $ENV{PGPLOT_PS_WIDTH} = $opt->{size}[0] * 1000;
    $ENV{PGPLOT_PS_HEIGHT} = $opt->{size}[1] * 1000;

    my @params = (size => [@{$opt->{size}}[0,1]]);
    push @params, nx=>$opt->{multi}[0], ny=>$opt->{multi}[1]
      if defined $opt->{multi};
    my $pgw = pgwin( $dev, { @params } );
    my $me = { opt=>$opt, conv_fn=>$conv_tempfile, obj=>$pgw };
    return bless $me;
}

our $pgplot_methods = {
    polylines => 'lines',
    'lines'  => 'line',
    'bins'   => 'bin',
    'points' => 'points',
    'errorbars' => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	$me->{obj}->points($data->[0],$data->[1],$ppo);
	$me->{obj}->errb($data->[0],$data->[1],$data->[2]);
    },
    'limitbars'=> sub {
	my ($me, $ipo, $data, $ppo) = @_;
	# use XY absolute error form, but with X errorbars right on the point
	$me->{obj}->points($data->[0],$data->[1],$ppo);
	my $z = zeroes($data->[0]);
	$me->{obj}->errb($data->[0],$data->[1], $z, $z, -($data->[2]-$data->[1]), $data->[3]-$data->[1], $ppo);
    },
    'image'  => 'imag',
    'contours' => 'cont',
    fits => 'fits_imag',
    'circles'=> sub {
	my ($me,$ipo,$data,$ppo) = @_;
	$ppo->{filltype}='outline';
	$me->{obj}->tcircle(@$data, $ppo);
    },
    'labels'=> sub {
	my ($me,$ipo,$data,$ppo) = @_;
	for my $i (0..$data->[0]->dim(0)-1) {
	    my $s = $data->[2]->[$i];
	    my $j = 0.0;
	    if ( $s =~ s/^([\<\|\>\ ])// ) {
		$j = 0.5 if($1 eq '|');
		$j = 1.0 if($1 eq '>');
	    }
	    $me->{obj}->text( $s, $data->[0]->at($i), $data->[1]->at($i), {JUSTIFICATION=>$j} );
	}
    }
};

sub plot {
    my $me = shift;
    my $ipo = shift;
    my $po = {};
    $po->{title}   = $ipo->{title}   if defined $ipo->{title};
    $po->{xtitle}  = $ipo->{xlabel}  if defined $ipo->{xlabel};
    $po->{ytitle}  = $ipo->{ylabel}  if defined $ipo->{ylabel};
    $po->{justify} = $ipo->{justify} if defined $ipo->{justify};

    my %color_opts;
    if (defined $ipo->{crange}) {
	$color_opts{MIN} = $ipo->{crange}[0] if defined $ipo->{crange}[0];
	$color_opts{MAX} = $ipo->{crange}[1] if defined $ipo->{crange}[1];
    }

    if ($ipo->{oplot}  and   $me->{opt}->{type} =~ m/^f/i) {
	die "The PGPLOT engine does not yet support oplot for files.  Instead, \nglom all your lines together into one call to plot.\n";
    }

    unless ($ipo->{oplot}) {
	$me->{curvestyle} = 0;
	$me->{logaxis} = $ipo->{logaxis};
	$po->{axis} = 0;
	if($ipo->{logaxis} =~ m/x/i) {
	    $po->{axis} += 10;
	    $ipo->{xrange} = [ map log10($_), @{$ipo->{xrange}}[0,1] ];
	}
	if($ipo->{logaxis} =~ m/y/i) {
	    $po->{axis} += 20;
	    $ipo->{yrange} = [ map log10($_), @{$ipo->{yrange}}[0,1] ];
	}
	$me->{obj}->release;
	my @range_vals = (@{$ipo->{xrange}}, @{$ipo->{yrange}});
	$me->{obj}->env(@range_vals, $po) if grep defined, @range_vals;
    }

    # ppo is "post-plot options", which are really a mix of plot and curve options.
    # Currently we don't parse any plot options into it (they're handled by the "env"
    # call) but if we end up doing so, it should go here.  The linestyle and color
    # are curve options that are autoincremented each curve.
    my %ppo = ();
    while (@_) {
	my ($co, @data) = @{shift()};
	my @extra_opts = ();
	if ( defined $co->{style} ) {
	    $me->{curvestyle} = int($co->{style}) + 1;
	} else {
	    $me->{curvestyle}++;
	}
	$ppo{ color } = $me->{curvestyle}-1 % 7 + 1;
	$ppo{ linestyle } = ($me->{curvestyle}-1) % 5 + 1;
	$ppo{ linewidth } = int($co->{width}) if $co->{width};
	our $pgplot_methods;
	my $pgpm = $pgplot_methods->{$co->{with}};
	die "Unknown curve option 'with $co->{with}'!" unless($pgpm);
	my @ppo_added;
	if ($pgpm eq 'fits_imag') {
	  $ppo{$_} = $po->{$_} for @ppo_added = grep defined $po->{$_}, qw(justify title);
	}
	if($pgpm eq 'imag') {
	    @ppo{keys %color_opts} = values %color_opts;
	    $ppo{ drawwedge } = ($ipo->{wedge} != 0);
	    # Extract transform parameters from the corners of the image...
	    my $xcoords = shift(@data);
	    my $ycoords = shift(@data);
	    my $datum_pix = [0,0];
	    my $datum_sci = [$xcoords->at(0,0), $ycoords->at(0,0)];
	    my $t1 = ($xcoords->slice("(-1),(0)") - $xcoords->slice("(0),(0)")) / ($xcoords->dim(0)-1);
	    my $t2 = ($xcoords->slice("(0),(-1)") - $xcoords->slice("(0),(0)")) / ($xcoords->dim(1)-1);
	    my $t4 = ($ycoords->slice("(-1),(0)") - $ycoords->slice("(0),(0)")) / ($ycoords->dim(0)-1);
	    my $t5 = ($ycoords->slice("(0),(-1)") - $ycoords->slice("(0),(0)")) / ($ycoords->dim(1)-1);
	    my $transform = pdl(
		$datum_sci->[0] - $t1 * $datum_pix->[0] - $t2 * $datum_pix->[1],
		$t1, $t2,
		$datum_sci->[1] - $t4 * $datum_pix->[0] - $t5 * $datum_pix->[1],
		$t4, $t5
		)->flat;
	    {   # sepia color table
		my $r = (xvals(256)/255)->sqrt;
		my $g = (xvals(256)/255);
		my $b = (xvals(256)/255)**2;
		$me->{obj}->ctab($g, $r, $g, $b);
	    }
	}
	$data[0] = $data[0]->log10 if $me->{logaxis} =~ m/x/i;
	$data[1] = $data[1]->log10 if $me->{logaxis} =~ m/y/i;
	if (ref $pgpm eq 'CODE') {
	  $pgpm->($me, $ipo, \@data, \%ppo);
	} else {
	  $me->{obj}->$pgpm(@data,\%ppo);
	}
	delete @ppo{@ppo_added} if @ppo_added;
	$me->{obj}->hold;
    }

    ##############################
    # End of curve plotting.
    # Now place the legend if necessary.
    if ($ipo->{legend}) {
	my $xp;
	my $xrdiff = $ipo->{xrange}->[1] - $ipo->{xrange}->[0];
	if( $ipo->{legend}=~ m/l/i ) {
	    $xp  = 0.03 * $xrdiff + $ipo->{xrange}->[0];
	} elsif($ipo->{legend} =~ m/r/i) {
	    $xp = 0.8 * $xrdiff + $ipo->{xrange}->[0];
	} else {
	    $xp = 0.4 * $xrdiff + $ipo->{xrange}->[0];
	}
	my $yp;
	my $yrdiff = $ipo->{yrange}->[1] - $ipo->{yrange}->[0];
	if( $ipo->{legend}=~ m/t/i ) {
	    $yp  = 0.95 * $yrdiff + $ipo->{yrange}->[0];
	} elsif($ipo->{legend} =~ m/b/i) {
	    $yp = 0.2 * $yrdiff + $ipo->{yrange}->[0];
	} else {
	    $yp = 0.6 * $yrdiff + $ipo->{yrange}->[0];
	}
	print "keys is [".join(",",@{$me->{keys}})."]; xp is $xp; yp is $yp\n";
	$me->{obj}->legend(
	    $me->{keys},
	    $xp, $yp,
	    { Color     => [ (xvals(0+@{$me->{keys}}) % 7 + 1)->list ],
	      LineStyle => [ (xvals(0+@{$me->{keys}}) % 5 + 1)->list ]
	    }
	    );
    }
    $me->{obj}->release;
}

sub DESTROY {
    my $me = shift;

    eval { # in case of global destruction
      $me->{obj}->release;
    };

    if (defined $me->{type} and $me->{type} =~ m/^f/i) {
	eval { $me->{obj}->close; };
	if ($me->{conv_fn}) {
	    wim(rim($me->{conv_fn}), $me->{opt}{output});
	    unlink($me->{conv_fn});
	}
    }
}

1;
