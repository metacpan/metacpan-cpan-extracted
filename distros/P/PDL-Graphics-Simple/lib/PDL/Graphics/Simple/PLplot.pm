
######################################################################
######################################################################
######################################################################
###
###
### PLplot interface to PDL::Graphics::Simple
###
### See the PDL::Graphics::Simple docs for details
###
##
#

package PDL::Graphics::Simple::PLplot;

use strict;
use warnings;
use File::Temp qw/tempfile/;
use Time::HiRes qw/usleep/;
use PDL::Options q/iparse/;
use PDL;

our $mod = {
    shortname => 'plplot',
    module=>'PDL::Graphics::Simple::PLplot',
    engine => 'PDL::Graphics::PLplot',
    synopsis=> 'PLplot (nice plotting, sloooow images)',
    pgs_api_version=> '1.012',
};
PDL::Graphics::Simple::register( $mod );

my @DEVICES = qw(
  qtwidget wxwidgets xcairo xwin wingcc
);
our $guess_filetypes = {
    ps  =>  ['pscairo','psc', 'psttfc', 'ps'],
    svg =>  ['svgcairo','svg','svgqt'],
    pdf => ['pdfcairo','pdfqt'],
    png => ['pngcairo','pngqt']
};
our $filetypes;

##########
# PDL::Graphics::Simple::PLplot::check
# Checker

sub check {
    my $force = shift;
    $force = 0 unless(defined($force));

    return $mod->{ok} unless( $force or !defined($mod->{ok}) );

    eval { require PDL::Graphics::PLplot; PDL::Graphics::PLplot->import };
    if ($@) {
	$mod->{ok} = 0;
	$mod->{msg} = $@;
	return 0;
    }

    # Module loaded OK, now try to extract valid devices from it.
    my $plgDevs = plgDevs();
    $mod->{devices} = {map +($_=>1), keys %$plgDevs};

    if ( my ($good_dev) = $ENV{PDL_SIMPLE_DEVICE} || grep $mod->{devices}{$_}, @DEVICES ) {
	$mod->{disp_dev} = $good_dev;
    } else {
	$mod->{ok} = 0;
	$mod->{msg} = join("\n\t", "No suitable display device found among:",
          sort keys %{ $mod->{devices} }) . "\n";
	return 0;
    }

    $filetypes = {};
    for my $k (keys %{$guess_filetypes}) {
	VAL:for my $v ( @{$guess_filetypes->{$k}} ) {
	    if ($mod->{devices}->{$v}) {
		$filetypes->{$k} = $v;
		last VAL;
	    }
	}
    }

    unless ($filetypes->{ps}) {
	$mod->{ok} = 0;
	$mod->{msg} = "No PostScript found";
	return 0;
    }

    $mod->{ok} = 1;
    return 1;
}


##########
# PDL::Graphics::Simple::PLplot::new
our $new_defaults ={
    size => [8,6,'in'],
    type => '',
    output=>'',
    multi=>undef
};

sub new {
    my $pkg = shift;
    my $opt_in = shift;
    my $opt = { iparse( $new_defaults, $opt_in ) };

    # Force a recheck on failure, in case the user fixed PLplot.
    unless(check()) {
	die "$mod->{shortname} appears nonfunctional: $mod->{msg}\n" unless(check(1));
    }

    # Figure the device name and size to feed to PLplot.
    my $conv_tempfile;
    my $dev;
    my @params;
    if ( $opt->{type} =~ m/^i/i) {
	## Interactive devices
	$dev = $mod->{disp_dev};
	if ($opt->{output}) {
	    push(@params, FILE=>$opt->{output});
	}
    } else {
	my $ext;
	## File devices
	if ( $opt->{output} =~ m/\.(\w{2,4})$/ ) {
	    $ext = $1;
	} else {
	    $ext = 'png';
	    $opt->{output} .= ".png";
	}
	unless(  $filetypes->{$ext}  and  $mod->{devices}->{$filetypes->{$ext}} ) {
	    ## Have to set up file conversion
	    my($fh);
	    ($fh, $conv_tempfile) = tempfile('pgs_plplot_XXXX');
	    close $fh;
	    unlink $conv_tempfile; # just to be sure...
	    $conv_tempfile .= ".ps";
	    $dev = $filetypes->{ps};
	    push(@params, FILE=>$conv_tempfile);
	} else {
	    $dev = "$filetypes->{$ext}";
	    push(@params, FILE=>$opt->{output});
	}
    }
    push @params, DEV=>$dev;

    my $size = PDL::Graphics::Simple::_regularize_size($opt->{size},'px');
    push(@params, PAGESIZE => [ @$size[0,1] ]);

    my $me = { opt=>$opt, conv_fn=>$conv_tempfile };

    if ( defined($opt->{multi}) ) {
	push @params, SUBPAGES => [@{$opt->{multi}}[0,1]];
	$me->{multi_cur} = 0;
	$me->{multi_n} = $opt->{multi}[0] * $opt->{multi}[1];
    }

    $me->{obj} = my $w = PDL::Graphics::PLplot->new( @params );
    plsstrm($w->{STREAMNUMBER});
    plspause(0);
    return bless $me;
}

sub DESTROY {
    # Make sure X11 windows disappear when destroyed...
    my $me = shift;
    if( $me->{opt}->{type} =~ m/^i/i   and  defined($me->{obj}) ) {
	$me->{obj}->close;
	delete $me->{obj};
    }
}

# if the value is a string, it's a PLOTTYPE parameter sent to xplot.  Otherwise
# it's a plotting sub...
our $plplot_methods = {
    lines => 'LINE',
    bins => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	my $x = $data->[0];
	my $x1 = $x->range(  [[0],[-1]], [$x->dim(0)],  'e'  )->average;
	my $x2 = $x->range(  [[1],[0]],  [$x->dim(0)],  'e'  )->average;
	my $newx = pdl($x1,$x2)->mv(-1,0)->clump(2)->sever;
	my $y = $data->[1];
	my $newy = $y->dummy(0,2)->clump(2)->sever;
	$me->{obj}->xyplot($newx, $newy, PLOTTYPE=>'LINE', %{$ppo});
    },
    points => 'POINTS',
    errorbars => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	$me->{obj}->xyplot(@$data[0,1], %$ppo, YERRORBAR=>$data->[2]*2);
    },
    limitbars => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	$me->{obj}->xyplot($data->[0], 0.5*($data->[2]+$data->[3]), %$ppo,
			   YERRORBAR=>($data->[3]-$data->[2])->abs,
			   PLOTTYPE=>'POINTS', SYMBOLSIZE=>0.0001, %$ppo);
	$me->{obj}->xyplot($data->[0], $data->[1], PLOTTYPE=>'LINE', %$ppo);
    },
    contours => sub {
	my ($me,$ipo,$data,$ppo) = @_;
	my ($vals, $cvals) = @$data;
	my $obj = $me->{obj};
	plsstrm($obj->{STREAMNUMBER});
	$obj->setparm(%$ppo);
	pllsty($ppo->{LINESTYLE});
	plwidth($ppo->{LINEWIDTH}) if $ppo->{LINEWIDTH};
	my ($nx,$ny) = $vals->dims;
	$obj->_setwindow;
	$obj->_drawlabels;
	my $grid = plAlloc2dGrid($vals->xvals, $vals->yvals);
	plcont($vals, 1, $nx, 1, $ny, $cvals, \&pltr2, $grid);
	plFree2dGrid($grid);
    },
    image => sub {
	my ($me,$ipo,$data,$ppo) = @_;

	# Hammer RGB into greyscale
	if($data->[2]->dims>2) {
	    $data->[2] = $data->[2]->mv(2,0)->average;
	}

	my ($immin,$immax) = $data->[2]->minmax;
	$ppo->{ZRANGE} = [] unless defined($ppo->{ZRANGE});
	$ppo->{ZRANGE}->[0] = $immin unless defined($ppo->{ZRANGE}->[0]);
	$ppo->{ZRANGE}->[1] = $immax unless defined($ppo->{ZRANGE}->[1]);

	my $xmin = $data->[0]->min - 0.5 * ($data->[0]->max - $data->[0]->min) / $data->[0]->dim(0);
	my $xmax = $data->[0]->max + 0.5 * ($data->[0]->max - $data->[0]->min) / $data->[0]->dim(0);
	my $ymin = $data->[1]->min - 0.5 * ($data->[1]->max - $data->[1]->min) / $data->[1]->dim(1);
	my $ymax = $data->[1]->max + 0.5 * ($data->[1]->max - $data->[1]->min) / $data->[1]->dim(1);
	my $min = ($ipo->{crange} and defined($ipo->{crange}->[0])) ? $ipo->{crange}->[0] : $data->[2]->min;
	my $max = ($ipo->{crange} and defined($ipo->{crange}->[1])) ? $ipo->{crange}->[1] : $data->[2]->max;

	my $nsteps = 128;

	my $obj = $me->{obj};

	plsstrm($obj->{STREAMNUMBER});
	$obj->setparm(%$ppo);
	my($nx,$ny) = $data->[0]->dims;

	$obj->_setwindow;
	$obj->_drawlabels;

	plcol0(1);
	plbox ($obj->{XTICK}, $obj->{NXSUB}, $obj->{YTICK}, $obj->{NYSUB},
	       $obj->{XBOX}, $obj->{YBOX}); # !!! note out of order call

	# Set color map
	my $r = (xvals(128)/127)->sqrt;
	my $g = (xvals(128)/127);
	my $b = (xvals(128)/127)**2;
	plscmap1l( 1, xvals(128)/127, $r, $g, $b, ones(128));

	my ($fill_width, $cont_color, $cont_width) = (2, 0, 0);
	my $clevel = ((PDL->sequence($nsteps)*(($max - $min)/($nsteps-1))) + $min);
	my $grid = plAlloc2dGrid($data->[0], $data->[1]);
	plshades( $data->[2], $xmin, $xmax, $ymin, $ymax, $clevel, $fill_width, $cont_color, $cont_width, 0, 0, \&pltr2, $grid );
	plFree2dGrid($grid);

	if($ipo->{wedge}) {
	    # Work around PLplot justify bug
	    local($obj->{JUST}) = 0;
	    $obj->colorkey($data->[2], 'v', VIEWPORT=>[0.93,0.96,0.15,0.85], TITLE=>"");
	}
    },
    circles => sub {
	my ($me,$ipo,$data,$ppo) = @_;
	my $ang = PDL->xvals(362)*3.14159/180;
	my $c = $ang->cos;
	my $s = $ang->sin;
	$s->slice("361") .= $c->slice("361") .= PDL->pdl(1.1)->acos; # NaN
	my $dr = $data->[2]->flat;
	my $dx = ($data->[0]->flat->slice("*1") + $dr->slice("*1") * $c)->flat;
	my $dy = ($data->[1]->flat->slice("*1") + $dr->slice("*1") * $s)->flat;
	$me->{obj}->xyplot( $dx, $dy, PLOTTYPE=>'LINE',%{$ppo});
    },
    polylines => sub {
      require PDL::ImageND;
      my ($me,$ipo,$data,$ppo) = @_;
      my ($xy, $pen) = @$data;
      my $pi = $pen->eq(0)->which;
      $me->{obj}->xyplot($_->dog, PLOTTYPE=>'LINE', %$ppo)
        for PDL::ImageND::path_segs($pi, $xy->mv(0,-1));
    },
    labels => sub {
	my ($me, $ipo, $data, $ppo) = @_;

	# Call xyplot to make sure the axes get set up.
	$me->{obj}->xyplot( pdl(1.1)->asin, pdl(1.1)->asin, %{$ppo} );

	for my $i (0..$data->[0]->dim(0)-1) {
	    my $j = 0;
	    my $s = $data->[2]->[$i];
	    if ($s =~ s/^([\<\|\> ])//) {
		$j = 1   if($1 eq '>');
		$j = 0.5 if($1 eq '|');
	    }
	    $me->{obj}->text($s, TEXTPOSITION=>[ $data->[0]->at($i),   $data->[1]->at($i),
						 1,0,
						 $j
			     ],
		);
	}
    }
};

our @colors = qw/BLACK RED GREEN BLUE MAGENTA CYAN YELLOW TURQUOISE PINK AQUAMARINE LIGHTSEAGREEN GOLD2 BROWN/;

##############################
# PDL::Graphics::Simple::PLplot::plot

sub plot {
    my $me = shift;
    my $ipo = shift;
    my $ppo = {};

    $ppo->{TITLE}  = $ipo->{title}   if(defined($ipo->{title}));
    $ppo->{XLAB}   = $ipo->{xlabel}  if(defined($ipo->{xlabel}));
    $ppo->{YLAB}   = $ipo->{ylabel}  if(defined($ipo->{ylabel}));
    $ppo->{ZRANGE} = $ipo->{crange}  if(defined($ipo->{crange}));

    unless( $ipo->{oplot} ) {
	$me->{style} = 0;
	$me->{logaxis} = $ipo->{logaxis};
	plsstrm($me->{obj}{STREAMNUMBER});
	$me->{multi_cur} %= $me->{multi_n}, $me->{multi_cur}++
	  if $me->{opt}{multi};
	pladv($me->{multi_cur} || 1);
	if (!$me->{multi_n} or $me->{multi_cur}==1) {
	    if ($me->{opt}->{type}=~ m/^i/) {
		pleop();
		plclear();
		plbop();
	    }
	}
	if($ipo->{logaxis} =~ m/x/i) {
	    $me->{obj}{XBOX} = 'bcnstl';
	    $ipo->{xrange} = [ map log10($_), @{$ipo->{xrange}}[0,1] ];
	}
	if($ipo->{logaxis} =~ m/y/i) {
	    $me->{obj}{YBOX} = 'bcnstl';
	    $ipo->{yrange} = [ map log10($_), @{$ipo->{yrange}}[0,1] ];
	}
	$me->{obj}{BOX} = [ @{$ipo->{xrange}}[0,1], @{$ipo->{yrange}}[0,1] ];
	$me->{obj}{VIEWPORT} = [0.1,0.87,0.13,0.82]; # copied from defaults in PLplot.pm.  Blech.
	$me->{obj}{JUST} = !!$ipo->{justify};
    }

    warn "P::G::S::PLplot: legends not implemented yet for PLplot" if($ipo->{legend});

    while (@_) {
	my ($co, @data) = @{shift()};
	my @extra_opts = ();
	if (defined $co->{style}) {
	    $me->{style} = $co->{style};
	} else {
	    $me->{style}++;
	}
	$ppo->{COLOR}     = $colors[$me->{style}%(@colors)];
	$ppo->{LINESTYLE} = (($me->{style}-1) % 8) + 1;
	$ppo->{LINEWIDTH} = $co->{width} if $co->{width};
	my $with = $co->{with};
	if ($with eq 'fits') {
	  ($with, my $new_opts, my $new_img, my @coords) = PDL::Graphics::Simple::_fits_convert($data[0], $ipo);
	  $data[-1] = $new_img;
	  unshift @data, @coords;
	  $ppo->{XLAB} = delete $new_opts->{xlabel};
	  $ppo->{YLAB} = delete $new_opts->{ylabel};
	  $me->{obj}{BOX} = [ @{$new_opts->{xrange}}[0,1], @{$new_opts->{yrange}}[0,1] ];
	}
	die "Unknown curve option 'with $with'!"
	  unless my $plpm = $plplot_methods->{$with};
	$data[0] = $data[0]->log10 if $me->{logaxis} =~ m/x/i;
	$data[1] = $data[1]->log10 if $me->{logaxis} =~ m/y/i;
	if (ref($plpm) eq 'CODE') {
	    $plpm->($me, $ipo, \@data, $ppo);
	} else {
	    $me->{obj}->xyplot(@data,PLOTTYPE=>$plpm,%$ppo);
	}
	plflush();
    }

    $me->{obj}->close if $me->{opt}{type} =~ m/^f/i and !defined $me->{opt}{multi};

    if ($me->{conv_fn}) {
	my $im = rim($me->{conv_fn});
	wim($im->mv(1,0)->slice(':,-1:0:-1'), $me->{opt}{output});
	unlink($me->{conv_fn});
    }
}

1;
