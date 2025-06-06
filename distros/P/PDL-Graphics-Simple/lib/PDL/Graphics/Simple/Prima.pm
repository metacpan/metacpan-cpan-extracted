######################################################################
######################################################################
######################################################################
###
###
### Prima backend for PDL::Graphics:Simple
###
### See the PDL::Graphics::Simple docs for details
###
### Prima setup is borrowed from D. Mertens' PDL::Graphics::Prima::Simple
###
##
#

package PDL::Graphics::Simple::Prima;

use strict;
use warnings;
use PDL;
use PDL::ImageND; # for polylines
use PDL::Options q/iparse/;
use File::Temp qw/tempfile/;

our $mod = {
    shortname => 'prima',
    module => 'PDL::Graphics::Simple::Prima',
    engine => 'PDL::Graphics::Prima',
    synopsis => 'Prima (interactive, fast, PDL-specific)',
    pgs_api_version=> '1.012',
};
PDL::Graphics::Simple::register( $mod );

our (@colors, @patterns, $types);

##########
# PDL::Graphics::Simple::Prima::check
# Checker
sub check {
    my $force = shift;
    $force = 0 unless(defined($force));

    return $mod->{ok} unless( $force or !defined($mod->{ok}));
    $mod->{ok} = 0; # makes default case simpler

    # Check Prima availability
    my $min_version = 0.18;
    eval { require PDL::Graphics::Prima; };
    if($@) {
	$mod->{msg} = "Couldn't load PDL::Graphics::Prima: ".$@;
	undef $@;
	return 0;
    }
    if ($PDL::Graphics::Prima::VERSION < $min_version) {
	$mod->{msg} = "Prima version $PDL::Graphics::Prima::VERSION is too low ($min_version required)";
	return 0;
    }

    eval { require PDL::Graphics::Prima::Simple; };
    if($@) {
	$mod->{msg} = "Couldn't load PDL::Graphics::Prima::Simple: ".$@;
	undef $@;
	return 0;
    }

    eval {
	require Prima::Application;
	Prima::Application->import();
    };
    if($@) {
	$mod->{msg} = "Couldn't load Prima application: ".$@;
	undef $@;
	return 0;
    }

    # Don't know if all these are actually needed; I'm stealing from the demo.
    # --CED
    eval {
	require Prima::Label;
	require Prima::PodView;
	require Prima::Buttons;
	require Prima::Utils;
	require Prima::Edit;
	require Prima::Const;
    };
    if($@){
	$mod->{msg} = "Couldn't load auxiliary Prima modules: ".$@;
	undef $@;
	return 0;
    }
    @colors = (
      cl::Black(), cl::Red(), cl::Green(), cl::Blue(), cl::Cyan(),
      cl::Magenta(), cl::Yellow(), cl::Brown(),
      cl::LightRed(), cl::LightGreen(), cl::LightBlue(), cl::Gray(),
    );
    @patterns = (
      lp::Solid(), lp::Dash(), lp::LongDash(), lp::ShortDash(), lp::DotDot(),
      lp::DashDot(), lp::DashDotDot(),
    );
    _load_types();
    $mod->{prima_version} = $Prima::VERSION;
    $mod->{ok} =1;
    return 1;
}


##############################
# New - constructor
our $new_defaults = {
    size => [6,4.5,'in'],
    type=>'i',
    output=>'',
    multi=>undef
};

## Much of this boilerplate is stolen from PDL::Graphics::Prima::Simple...
our $N_windows = 0;

sub new {
    my $class = shift;
    my $opt_in = shift;
    $opt_in = {} unless(defined($opt_in));
    my $opt = { iparse($new_defaults, $opt_in) };
    unless( check() ) {
	die "$mod->{shortname} appears nonfunctional: $mod->{msg}\n" unless(check(1));
    }

    my $size = PDL::Graphics::Simple::_regularize_size($opt->{size},'px');

    my $pw = Prima::Window->create( text => $opt->{output} || "PDL/Prima Plot",
				    size => [$size->[0], $size->[1]],
				    onCreate  => sub { $PDL::Graphics::Prima::Simple::N_windows++; },
				    onDestroy => sub { $PDL::Graphics::Prima::Simple::N_windows--;
						       PDL::Graphics::Prima::Simple::twiddling(0) if($PDL::Graphics::Prima::Simple::N_windows==0);
				    }
	);
    die "Couldn't create a Prima window!" unless(defined($pw));

    if($opt_in->{type} =~ m/^f/i) {
	$pw->hide;
    }
    my $me = { obj => $pw,
	       widgets => [],
	       next_plotno=>0,
	       multi=>$opt_in->{multi},
	       type=>$opt->{type},
	       output=>$opt->{output}
    };
    return bless($me, "PDL::Graphics::Simple::Prima");
}

sub DESTROY {
    my $me = shift;
    if($me->{type} =~ m/f/i) {
	##############################
	# File-saving code...
	unless( $me->{multi} ) {

	    ##############################
	    # Save plot to file

	    if($me->{widgets}->[0]) {
		eval {$me->{widgets}->[0]->save_to_file($me->{output})};
		if($@) {
		    print $@;
		    undef $@;
		}
	    } else {
		print STDERR "No plot was sent to $me->{output}\n";
	    }
	} else {

	    ##############################
	    # Multiplot - save the plots individually, then splice them together.
	    # Lame, lame - I think this can be done in memory with Prima.
	    # But it gets us to a place where we are supporting stuff.

	    if(@{$me->{widgets}} < 1) {
		print STDERR "No plot was sent to $me->{output}\n";
	    } else {
		print STDERR "WARNING - multiplot support is experimental for the Prima engine\n";

		my ($h,$tmpfile) = tempfile('PDL-Graphics-Simple-XXXX');
		close $h;
		unlink($tmpfile);

		my $suffix;
		if($me->{output}=~ s/(\.\w{2,4})$//) {
		    $suffix = $1;
		} else {
		    $suffix = ".png";
		}
		$tmpfile .= $suffix;

		my $widget_dex = 0;
		my $im = undef;
		my $ztile = undef;
	      ROW:for my $row(0..$me->{multi}->[1]-1) {
		  my $imrow = undef;
		  for my $col(0..$me->{multi}->[0]-1) {

		      my $tile;

		      if($widget_dex < @{$me->{widgets}}) {
			  eval { $me->{widgets}->[$widget_dex++]->save_to_file($tmpfile) };
			  last ROW if($@);
			  $tile = rim($tmpfile);
			  $ztile = zeroes($tile)+255;
			  unlink($tmpfile);
		      } else {
			  # ztile is always initialized by first run through...
			  $tile = $ztile;
		      }

		      if(!defined($imrow)) {
			  $imrow = $tile;
		      } else {
			  $imrow = $imrow->glue(0,$tile);
		      }
		  } # end of row loop

		  if(!defined($im)) {
		      $im = $imrow;
		  } else {
		      $im = $imrow->glue(1,$im);
		  }
	      }
		unless($@) {
		    wim($im, $me->{output}.$suffix);
		} else {
		    print STDERR $@;
		    undef $@;
		}
	    }
	}
    }

    eval { # in case of global destruction
      $me->{obj}->hide;
      $me->{obj}->destroy;
    };
}

##############################
# apply method makes sepiatone values for input data,
# to match the style of PDL::Graphics::Prima::Palette,
# in order to make the Matrix plot type happy (for 'with=>image').
@PDL::Graphics::Simple::Prima::Sepia_Palette::ISA = 'PDL::Graphics::Prima::Palette';
sub PDL::Graphics::Simple::Prima::Sepia_Palette::apply {
    my $h = shift;
    my $data = shift;
    my ($min, $max) = @$h{qw(min max)};
    my $g = ($min==$max)? $data->zeroes : (($data->double - $min)/($max-$min))->clip(0,1);
    my $r = $g->sqrt;
    my $b = $g*$g;
    return (pdl($r,$g,$b)*255.999)->floor->mv(-1,0)->rgb_to_color;
}


##############################
# Plot types
#
# This probably needs a little more smarts.
# Currently each entry is either a ppair::<foo> return or a sub that implements
# the plot type in terms of others.
sub _load_types {
  $types = {
    lines => 'Lines',

    points => [ map ppair->can($_)->(), qw/Blobs Triangles Squares Crosses Xs Asterisks/ ],

    bins => sub {
      my ($me, $plot, $block, $cprops) = @_;
      my ($x, $y) = @$block;
      my $x1 = $x->range( [[0],[-1]], [$x->dim(0)], 'e' )->average;
      my $x2 = $x->range( [[1],[0]],  [$x->dim(0)], 'e' )->average;
      my $newx = pdl($x1, $x2)->mv(-1,0)->clump(2)->sever;
      my $newy = $y->dummy(0,2)->clump(2)->sever;
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
          ds::Pair($newx,$newy,plotType=>ppair::Lines(), @$cprops);
    },

    # as of 1.012, known to not draw all its lines(!) overplotting an image
    # draws them all without an image in same plot() call, or separate plot()
    contours => sub {
      my ($me, $plot, $block, $cprops) = @_;
      my ($vals, $cvals) = @$block;
      for my $thresh ($cvals->list) {
        my ($pi, $p) = contour_polylines($thresh, $vals, $vals->ndcoords);
        next if $pi->at(0) < 0;
        $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
          ds::Pair($_->dog, plotType=>ppair::Lines(), @$cprops)
            for path_segs($pi, $p->mv(0,-1));
      }
    },

    polylines => sub {
      my ($me, $plot, $block, $cprops) = @_;
      my ($xy, $pen) = @$block;
      my $pi = $pen->eq(0)->which;
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
        ds::Pair($_->dog, plotType=>ppair::Lines(), @$cprops)
          for path_segs($pi, $xy->mv(0,-1));
    },

    image => sub {
      my ($me, $plot, $data, $cprops, $co, $ipo) = @_;
      my ($xmin, $xmax) = $data->[0]->minmax;
      my $dx = 0.5 * ($xmax-$xmin) / ($data->[0]->dim(0) - (($data->[0]->dim(0)==1) ? 0 : 1));
      $xmin -= $dx;
      $xmax += $dx;
      my ($ymin, $ymax) = $data->[1]->minmax;
      my $dy = 0.5 * ($ymax-$ymin) / ($data->[0]->dim(1) - (($data->[1]->dim(1)==1) ? 0 : 1));
      $ymin -= $dy;
      $ymax += $dy;
      my $dataset;
      my $imdata = $data->[2];
      my @bounds = (x_bounds=>[ $xmin, $xmax ], y_bounds=>[ $ymin, $ymax ]);
      if ($imdata->ndims > 2) {
        $imdata = $imdata->mv(-1,0) if $imdata->dim(0) != 3;
        $dataset = ds::Image($imdata, @bounds);
      } else {
        my $crange = $me->{ipo}{crange};
        my ($cmin, $cmax) = defined($crange) ? @$crange : ();
        $cmin //= $imdata->min;
        $cmax //= $imdata->max;
        my $palette = PDL::Graphics::Simple::Prima::Sepia_Palette->new(
          min => $cmin, max => $cmax, data => $imdata,
        );
        $dataset = ds::Grid($imdata,
          @bounds,
          plotType=>pgrid::Matrix($ipo->{wedge} ? () : (palette => $palette)),
        );
        $plot->color_map($palette) if $ipo->{wedge};
      }
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } = $dataset;
    },

    circles => sub {
      my ($me, $plot, $data, $cprops) = @_;
      our $cstash;
      unless(defined($cstash)) {
        my $ang = PDL->xvals(362)*3.14159/180;
        $cstash = {c => $ang->cos, s => $ang->sin};
        $cstash->{s}->slice("361") .= $cstash->{c}->slice("361") .= PDL->pdl(1.1)->acos; # NaN
      }
      my $dr = $data->[2]->flat;
      my $dx = ($data->[0]->flat->dummy(0,1) + $dr->dummy(0,1)*$cstash->{c})->flat;
      my $dy = ($data->[1]->flat->dummy(0,1) + $dr->dummy(0,1)*$cstash->{s})->flat;
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
        ds::Pair( $dx, $dy, plotType=>ppair::Lines(), @$cprops);
    },

    labels => sub {
      my ($me,$plot,$block,$cprops,$co,$ipo) = @_;
      my ($x, $y) = map $_->flat->copy, @$block[0,1]; # copy as mutate below
      my @labels = @{$block->[2]};
      my @lrc = ();
      for my $i(0..$x->dim(0)-1) {
        my $j =0;
        if($labels[$i] =~ s/^([\<\|\> ])//) {
          my $ch = $1;
          if($ch =~ m/[\|\>]/) {
            my $tw = $plot->get_text_width($labels[$i]);
            $tw /= 2 if($ch eq '|');
            $x->slice("($i)") .=
              $plot->x->pixels_to_reals(
                $plot->x->reals_to_pixels( $x->slice("($i)") ) - $tw
              );
          }
        }
      }
      $plot->dataSets()->{1+keys(%{$plot->dataSets()})} =
        ds::Note(
          map pnote::Text($labels[$_],x=>$x->slice("($_)"),y=>$y->slice("($_)")), 0..$#labels
        );
    },

    limitbars => sub {
      # Strategy: make T-errorbars out of the x/y/height data and generate a Line
      # plot.  The T-errorbar width is 4x the LineWidth (+/- 2x).
      my ($me, $plot, $block, $cprops, $co, $ipo) = @_;
      my $x = $block->[0]->flat;
      my $y = $block->[1]->flat;
      my $ylo = $block->[2]->flat;
      my $yhi = $block->[3]->flat;
      # Calculate T bar X ranges
      my $of = ($co->{width}||1) * 2;
      my $xp = $plot->x->reals_to_pixels($x);
      my $xlo = $plot->x->pixels_to_reals(  $xp - $of );
      my $xhi = $plot->x->pixels_to_reals(  $xp + $of );
      my $nan = PDL->new_from_specification($x->dim(0));  $nan .= asin(pdl(1.1));
      my $xdraw = pdl($xlo,$xhi,$x,  $x,  $xlo,$xhi,$nan)->mv(1,0)->flat;
      my $ydraw = pdl($ylo,$ylo,$ylo,$yhi,$yhi,$yhi,$nan)->mv(1,0)->flat;
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
          ds::Pair($xdraw,$ydraw,plotType=>ppair::Lines(), @$cprops);
      $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } =
          ds::Pair($x,$y,plotType=>$types->{points}->[ ($me->{curvestyle}-1) %(0+@{$types->{points}}) ], @$cprops);
    },

    errorbars => sub {
      # Strategy: make T-errorbars out of the x/y/height data and generate a Line
      # plot.  The T-errorbar width is 4x the LineWidth (+/- 2x).
      my ($me, $plot, $block, $cprops, $co, $ipo) = @_;
      my $halfwidth = $block->[2]->flat;
      $block->[2] = $block->[1] - $halfwidth;
      $block->[3] = $block->[1] + $halfwidth;
      $types->{limitbars}->($me, $plot, $block, $cprops, $co, $ipo);
    },
  };
}

##############################
# Plot subroutine
#
#
sub plot {
    my $me = shift;
    my $ipo = shift;

    $me->{ipo} = $ipo;

    if(defined($ipo->{legend})) {
	printf(STDERR "WARNING: Ignoring 'legend' option (Legends not yet supported by PDL::Graphics::Simple::Prima v%s)",$PDL::Graphics::Simple::VERSION);
    }

    my $plot;

    if ($ipo->{oplot} and defined($me->{last_plot})) {
	$plot = $me->{last_plot};
    } else {
	$me->{curvestyle} = 0;

	if ($me->{multi}) {
	    # Multiplot - handle logic and plot placement

	    # Advance to the next plot position. Erase the window if necessary.
	    if ($me->{next_plotno}  and  $me->{next_plotno} >= $me->{multi}->[0] * $me->{multi}->[1]) {
		map {$_->destroy} @{$me->{widgets}};
		$me->{widgets} = [];
		$me->{next_plotno} = 0;
	    }

	    my $pno = $me->{next_plotno};
	    $plot = $me->{obj}->insert('Plot',
				       place => {
					   relx      => ($pno % $me->{multi}->[0])/$me->{multi}->[0],
					   relwidth  => 1.0/$me->{multi}->[0],
					   rely      => 1.0 - (1 + int($pno / $me->{multi}->[0]))/$me->{multi}->[1],
					   relheight => 1.0/$me->{multi}->[1],
					   anchor    => 'sw'});
	    $plot->titleFont(size => 12);

	    $me->{next_plotno}++;
	} else {
	    # No multiplot - just instantiate a plot (and destroy any widgets from earlier)
	    $_->destroy for @{$me->{widgets}};
	    $me->{widgets} = [];
	    $plot = $me->{obj}->insert('Plot',
				       pack=>{fill=>'both',expand=>1}
		);
	    $plot->titleFont(size => 14);
	}
    }

    push(@{$me->{widgets}}, $plot);
    $me->{last_plot} = $plot;

    for my $block (@_) {
      my $co = $block->[0];
      if ($co->{with} eq 'fits') {
	($co->{with}, my $new_opts, my $new_img, my @coords) = PDL::Graphics::Simple::_fits_convert($block->[1], $ipo);
	$block = [ $co, @coords, $new_img ];
	@$ipo{keys %$new_opts} = values %$new_opts;
      }
    }

    if (!$ipo->{oplot}) {
      ## Set global plot options: titles, axis labels, and ranges.
      $plot->hide;
      $plot->lock;
      $plot->title(     $ipo->{title}   )  if(defined($ipo->{title}));
      $plot->x->label(  $ipo->{xlabel}  )  if(defined($ipo->{xlabel}));
      $plot->y->label(  $ipo->{ylabel}  )  if(defined($ipo->{ylabel}));

      $plot->x->scaling(sc::Log()) if($ipo->{logaxis}=~ m/x/i);
      $plot->y->scaling(sc::Log()) if($ipo->{logaxis}=~ m/y/i);

      $plot->x->min($ipo->{xrange}[0]) if(defined($ipo->{xrange}) and defined($ipo->{xrange}[0]));
      $plot->x->max($ipo->{xrange}[1]) if(defined($ipo->{xrange}) and defined($ipo->{xrange}[1]));
      $plot->y->min($ipo->{yrange}[0]) if(defined($ipo->{yrange}) and defined($ipo->{yrange}[0]));
      $plot->y->max($ipo->{yrange}[1]) if(defined($ipo->{yrange}) and defined($ipo->{yrange}[1]));

      ##############################
      # I couldn't find a way to scale the plot to make the plot area justified, so
      # we cheat and adjust the axis values instead.
      # This is a total hack, but at least it produces justified plots.
      if ($ipo->{justify}) {
        my ($dmin,$pmin,$dmax,$pmax,$xscale,$yscale);

        ($dmin,$dmax) = $plot->x->minmax;
        $pmin = $plot->x->reals_to_pixels($dmin);
        $pmax = $plot->x->reals_to_pixels($dmax);
        $xscale = ($pmax-$pmin)/($dmax-$dmin);

        ($dmin,$dmax) = $plot->y->minmax;
        $pmin = $plot->y->reals_to_pixels($dmin);
        $pmax = $plot->y->reals_to_pixels($dmax);
        $yscale = ($pmax-$pmin)/($dmax-$dmin);

        my $ratio = $yscale / $xscale;
        if($ratio > 1) {
            # More Y pixels per datavalue than X pixels.  Hence we expand the Y range.
            my $ycen = ($dmax+$dmin)/2;
            my $yof =  ($dmax-$dmin)/2;
            my $new_yof = $yof * $yscale/$xscale;
            $plot->y->min($ycen-$new_yof);
            $plot->y->max($ycen+$new_yof);
        } elsif($ratio < 1) {
            # More X pixels per datavalue than Y pixels.  Hence we expand the X range.
            ($dmin,$dmax) = $plot->x->minmax;
            my $xcen = ($dmax+$dmin)/2;
            my $xof =  ($dmax-$dmin)/2;
            my $new_xof = $xof * $xscale/$yscale;
            $plot->x->min($xcen-$new_xof);
            $plot->x->max($xcen+$new_xof);
        }
      }
    }

    ##############################
    # Rubber meets the road -- loop over data blocks and
    # ship out each curve to the appropriate dispatcher in the $types table
    for my $block (@_) {
      my ($co, @rest) = @$block;

      # Parse out curve style (for points type selection)
      if (defined $co->{style}) {
        $me->{curvestyle} = $co->{style};
      } else {
        $me->{curvestyle}++;
      }

      my $cprops = [
        color        => $colors[   ($me->{curvestyle}-1) % @colors ],
        linePattern  => $patterns[ ($me->{curvestyle}-1) % @patterns ],
        lineWidth    => $co->{width} || 1
      ];

      my $with = $co->{with};
      my $type = $types->{$with};
      die "$with is not yet implemented in PDL::Graphics::Simple for Prima.\n"
          if !defined $type;
      if ( ref($type) eq 'CODE' ) {
        $type->($me, $plot, \@rest, $cprops, $co, $ipo);
      } else {
        my $pt = ref($type) eq 'ARRAY' ? $type->[ ($me->{curvestyle}-1) % (0+@{$type}) ] : ppair->can($type)->();
        $plot->dataSets()->{ 1+keys(%{$plot->dataSets()}) } = ds::Pair(@rest, plotType => $pt, @$cprops);
      }
    }

    if ($me->{type} !~ m/f/i) {
	$plot->show;
	$plot->unlock;
    } else {
	# Belt-and-suspenders to stay hidden
	$plot->hide;
	$me->{obj}->hide;
    }

    ##############################
    # Another lame kludge.  Run the event loop for 50 milliseconds, to enable a redraw,
    # then exit it.
    Prima::Timer->create(
	onTick=>sub{$_[0]->stop; die "done with event loop\n"},
	timeout=>50
	)->start;
    eval { no warnings 'once'; $::application->go };
    die unless $@ =~ /^done with event loop/;
    undef $@;
}

1;
