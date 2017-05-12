
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

use File::Temp qw/tempfile/;
use Time::HiRes qw/usleep/;
use PDL::Options q/iparse/;
use PDL;

eval 'use PDL::Graphics::PLplot';

our $mod = {
    shortname => 'plplot',
    module=>'PDL::Graphics::Simple::PLplot',
    engine => 'PDL::Graphics::PLplot',
    synopsis=> 'PLplot (nice plotting, sloooow images)',
    pgs_version=> '1.005'
};
PDL::Graphics::Simple::register( 'PDL::Graphics::Simple::PLplot' );

##########
# PDL::Graphics::Simple::PLplot::check
# Checker

sub check {
    my $force = shift;
    $force = 0 unless(defined($force));

    return $mod->{ok} unless( $force or !defined($mod->{ok}) );

    eval 'use PDL::Graphics::PLplot';
    if($@) {
	$mod->{ok} = 0;
	$mod->{msg} = $@;
	return 0;
    }

    # Module loaded OK, now try to extract valid devices from it.
    # We would use a pipe, but Microsoft Windows doesn't play nice
    # with them - so we use a temp file instead.
    my ($fh1, $gzinta) = tempfile('pgs_gzinta_XXXX');
    close $fh1;
    my ($fh2, $gzouta) = tempfile('pgs_gzouta_XXXX');
    close $fh2;

    open FOO, ">$gzinta" or die "Couldn't write to temp file";
    print FOO "1\n"; #Just one line
    close FOO;

    if($^O =~ /MSWin32/i) {
      eval {require Win32::Process};
      die "Win32::Process didn't load: $@"
        if $@;

      my $cmd_location = -e "\\Windows\\system32\\cmd.exe"
                            ? "\\Windows\\system32\\cmd.exe"
                            : cmd_location();

      Win32::Process::Create(
        $ProcessObj,
        $cmd_location,
        "cmd /c \"$^X -MPDL -MPDL::Graphics::PLplot -e \"PDL::Graphics::PLplot->new() \" <$gzinta >$gzouta\"",
        0,
        32, #NORMAL_PRIORITY_CLASS
        ".")|| die ErrorReport();
    }
    else {
      my $pid = fork();
      unless(defined($pid)) {
 	print STDERR "Fork failed in PLplot probe -- returning 0\n";
	return 0;
      }

      if( $pid==0 ) {   # assignment

	# Daughter: try to create a PLplot window with a bogus device, to stimulate a driver listing
	open STDOUT,">$gzouta";
	open STDERR,">&STDOUT";
	open STDIN, "<$gzinta";
	PDL::Graphics::PLplot->new(DEV=>'?');
	exit(0);
      }

      # Parent - snarf up the results from the daughter
      usleep(2e5);          # hang around for 0.2 seconds
      eval {kill 9,$pid;};  # kill it dead, just in case it buzzed or hung (I'm looking at you, Microsoft Windows)
      waitpid($pid,0);      # Clean up.
    }

    sleep 1 if $^O =~ /MSWin32/i; # Don't read $gzouta before it's written

    # Snarf up the file.
    open FOO, "<$gzouta";
    @lines = <FOO>;
    close FOO;

    unlink $gzinta;
    unlink $gzouta;

    $mod->{devices} = {};
    for my $l(@lines) {
	if( $l=~ m/^\s+\<\s*\d+\>\s+(\w+)/ ) {
	    $mod->{devices}->{$1} = 1;
	}
    }

    if( $mod->{devices}->{'xcairo'} ) {
	$mod->{disp_dev} = 'xcairo';
    } elsif( $mod->{devices}->{'xwin'} ) {
	$mod->{disp_dev} = 'xwin';
    } elsif( $mod->{devices}->{'wingcc'} ) {
	$mod->{disp_dev} = 'wingcc';
    } else {
	$mod->{ok} = 0;
	return 0;
    }

    our $guess_filetypes = {
	ps  =>  ['pscairo','psc', 'psttfc', 'ps'],
	svg =>  ['svgcairo','svg'],
	pdf => ['pdfcairo'],
	png => ['pngcairo']
    };

    our $filetypes;
    $filetypes = {};

    for $k(keys %{$guess_filetypes}) {
	VAL:for $v( @{$guess_filetypes->{$k}} ) {
	    if($mod->{devices}->{$v}) {
		$filetypes->{$k} = $v;
		last VAL;
	    }
	}
    }

    unless($filetypes->{ps}) {
	$mod->{ok} = 0;
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

    my $pgw;

    # Force a recheck on failure, in case the user fixed PLplot.
    unless(check()) {
	die "$mod->{shortname} appears nonfunctional\n" unless(check(1));
    }

    # Figure the device name and size to feed to PLplot.
    # size has already been regularized.
    my $conv_tempfile;
    my $dev;
    my @params;

    if( $opt->{type} =~ m/^i/i) {
	## Interactive devices
	$dev = $mod->{disp_dev};
	push(@params,  DEV => $dev );
	if($opt->{output}) {
	    push(@params, FILE=>$opt->{output});
	}


    } else {
	my $ext;
	## File devices

	if( $opt->{output} =~ m/\.(\w{2,4})$/ ) {
	    $ext = $1;
	} else {
	    $ext = 'png';
	    $opt->{output} .= ".png";
	}

	our $mod;
	unless(  $filetypes->{$ext}  and  $mod->{devices}->{$filetypes->{$ext}} ) {
	    ## Have to set up file conversion
	    my($fh);
	    ($fh, $conv_tempfile) = tempfile('pgs_pgplot_XXXX');
	    close $fh;
	    unlink $conv_tempfile; # just to be sure...
	    $conv_tempfile .= ".ps";
	    $dev = $filetypes->{ps};

	    push(@params, FILE=>$conv_tempfile);

	} else {
	    $dev = "$filetypes->{$ext}";
	    push(@params, FILE=>$opt->{output});
	}

	push(@params, DEV=>$dev);

    }

    my $size = PDL::Graphics::Simple::_regularize_size($opt->{size},'px');
    push(@params, PAGESIZE => [ $size->[0], $size->[1] ]);

    my $me = { opt=>$opt, conv_fn=>$conv_tempfile };

    if( defined($opt->{multi}) ) {
	push(@params, SUBPAGES => [$opt->{multi}->[0], $opt->{multi}->[1]] );
	$me->{multi_cur} = 0;
	$me->{multi_n} = $opt->{multi}->[0] * $opt->{multi}->[1];
    }

    my $creator = sub { my $w = PDL::Graphics::PLplot->new( @params );
			plsstrm($w->{STREAMNUMBER});
			plspause(0);
			return $w;
    };
    $pgw = eval { &$creator };
    print STDERR $@ if($@);

    $me->{creator} = $creator;
    $me->{obj} = $pgw;

    return bless($me, 'PDL::Graphics::Simple::PLplot');
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
    'lines'  => 'LINE',
    'bins'   => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	my $x = $data->[0];
	my $x1 = $x->range(  [[0],[-1]], [$x->dim(0)],  'e'  )->average;
	my $x2 = $x->range(  [[1],[0]],  [$x->dim(0)],  'e'  )->average;
	my $newx = pdl($x1,$x2)->mv(-1,0)->clump(2)->sever;

	my $y = $data->[1];
	my $newy = $y->dummy(0,2)->clump(2)->sever;

	$me->{obj}->xyplot($newx, $newy, PLOTTYPE=>'LINE', %{$ppo});
    },
    'points' => 'POINTS',
    'errorbars' => sub {
	my ($me, $ipo, $data, $ppo) = @_;
	$me->{obj}->xyplot($data->[0], $data->[1], %{$ppo}, YERRORBAR=>$data->[2]*2);
    },
    'limitbars'=> sub {
	my ($me, $ipo, $data, $ppo) = @_;
	$me->{obj}->xyplot($data->[0], 0.5*($data->[2]+$data->[3]), %{$ppo},
			   YERRORBAR=>($data->[3]-$data->[2])->abs,
			   PLOTTYPE=>'POINTS', SYMBOLSIZE=>0.0001, %$ppo);
	$me->{obj}->xyplot($data->[0], $data->[1], PLOTTYPE=>'LINE', %$ppo);
    },
    'image'  => sub {
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



	my $fill_width = 2;
	my $cont_color = 0;
	my $cont_width = 0;

	my $clevel = ((PDL->sequence($nsteps)*(($max - $min)/($nsteps-1))) + $min);
	my $grid = plAlloc2dGrid($data->[0], $data->[1]);
	
	plshades( $data->[2], $xmin, $xmax, $ymin, $ymax, $clevel, $fill_width, $cont_color, $cont_width, 0, 0, \&pltr2, $grid );
	plFreeGrid($grid);
	plflush();

	if($ipo->{wedge}) {
	    # Work around PLplot justify bug
	    local($obj->{JUST}) = 0;
	    $obj->colorkey($data->[2], 'v', VIEWPORT=>[0.93,0.96,0.15,0.85], TITLE=>"");
	}
    },
    'circles'=> sub {
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
    'labels'=>sub {
	my ($me, $ipo, $data, $ppo) = @_;

	# Call xyplot to make sure the axes get set up.
	$me->{obj}->xyplot( pdl(1.1)->asin, pdl(1.1)->asin, %{$ppo} );

	for $i(0..$data->[0]->dim(0)-1) {
	    my $j = 0;
	    $s = $data->[2]->[$i];
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

our @colors = qw/BLACK RED GREEN BLUE MAGENTA CYAN YELLOW TURQUOISE PINK AQUAMARINE LIGHTSEAGREEN GOLD2 BROWN VIOLET FORESTGREEN LIGHTGOLDENROD/;

##############################
# PDL::Graphics::Simple::PLplot::plot

sub plot {
    my $me = shift;
    my $ipo = shift;
    my $ppo = {};

    $ppo->{TITLE}  = $ipo->{title}   if(defined($ipo->{title}));
    $ppo->{XLAB}   = $ipo->{xtitle}  if(defined($ipo->{xtitle}));
    $ppo->{YLAB}   = $ipo->{ytitle}  if(defined($ipo->{ytitle}));
    $ppo->{ZRANGE} = $ipo->{crange}  if(defined($ipo->{crange}));

    unless( $ipo->{oplot} ) {
	$me->{style} = 0;

	$me->{logaxis} = $ipo->{logaxis};

	if($me->{opt}->{multi}) {
	    $me->{multi_cur}++;
	}

	plsstrm($me->{obj}->{STREAMNUMBER});
	pladv($me->{multi_cur} or 1);


	if(!defined($me->{multi_n}) or  !($me->{multi_n})   or  $me->{multi_n}==1 ) {

	    if($me->{opt}->{type}=~ m/^i/) {
		plsstrm($me->{obj}->{STREAMNUMBER});
		pleop();
		plclear();
		plbop();
	    }
	}

	if($ipo->{logaxis} =~ m/x/i) {
	    $me->{obj}->{XBOX} = 'bcnstl';
	    $ipo->{xrange} = [ log10($ipo->{xrange}->[0]), log10($ipo->{xrange}->[1]) ];
	}


	if($ipo->{logaxis} =~ m/y/i) {
	    $me->{obj}->{YBOX} = 'bcnstl';
	    $ipo->{yrange} = [ log10($ipo->{yrange}->[0]), log10($ipo->{yrange}->[1]) ];
	}

#	plenv( $ipo->{xrange}->[0], $ipo->{xrange}->[1], $ipo->{yrange}->[0],$ipo->{yrange}->[1], $ipo->{justify},  1);
	$me->{obj}->{BOX} = [ $ipo->{xrange}->[0], $ipo->{xrange}->[1], $ipo->{yrange}->[0],$ipo->{yrange}->[1]  ];
	$me->{obj}->{VIEWPORT} = [0.1,0.87,0.13,0.82]; # copied from defaults in PLplot.pm.  Blech.
	$me->{obj}->{JUST} = !!$ipo->{justify};


    }

    warn "P::G::S::PLplot: legends not implemented yet for PLplot" if($ipo->{legend});

    while(@_) {
	my ($co, @data) = @{shift()};
	my @extra_opts = ();

	if( defined($co->{style}) and $co->{style}) {
	    $me->{style} = $co->{style};
	} else {
	    $me->{style}++;
	}

	$ppo->{COLOR}     = $colors[$me->{style}%(@colors)];
	$ppo->{LINESTYLE} = (($me->{style}-1) % 8) + 1;

	if( defined($co->{width}) and $co->{width} ) {
	    $ppo->{LINEWIDTH} = $co->{width};
	}

	$plpm = $plplot_methods->{$co->{with}};
	die "Unknown curve option 'with $co->{with}'!" unless($plpm);

	my %plplot_opts = (%$ppo);
	my $plplot_opts = \%plplot_opts;

	if($me->{logaxis} =~ m/x/i) {
	    $data[0] = $data[0]->log10;
	}

	if($me->{logaxis} =~ m/y/i) {
	    $data[1] = $data[1]->log10;
	}

	if(ref($plpm) eq 'CODE') {
	    &$plpm($me, $ipo, \@data, $plplot_opts);
	} else {
	    my $str= sprintf('$me->{obj}->xyplot(@data,PLOTTYPE=>"%s",%s);%s',$plpm,'%plplot_opts',"\n");
	    eval $str;
	}
    }

    $me->{obj}->close if($me->{opt}->{type} =~ m/^f/i and !defined($me->{opt}->{multi}));

    my $file = ( ($me->{conv_fn}) ? $me->{conv_fn} : $me->{output} );

    if($me->{conv_fn}) {
	$a = rim($me->{conv_fn});
	wim($a->mv(1,0)->slice(':,-1:0:-1'), $me->{opt}->{output});
	unlink($me->{conv_fn});
    }
}

sub ErrorReport{
  print Win32::FormatMessage( Win32::GetLastError() );
}

sub cmd_location {
  use File::Spec;
  my @path = File::Spec->path();

  for my $p(@path) {
    if(-e "${p}\\cmd.exe") {return "${p}\\cmd.exe"}
  }
  die "Can't locate cmd.exe";
}
