package SVGGraph::Pie;

use strict;
use vars qw($VERSION);
$VERSION = '0.06';
use constant PI  => '3.141592654';
use constant GAP => 15;

use SVG;

sub _croak { require Carp; Carp::croak(@_) }
sub _carp  { require Carp; Carp::carp(@_)  }

sub new {
    my $self = shift;
    return bless {}, $self;
}

sub CreateGraph {
    my $self    = shift;
    my $options = shift;

    ## The rest are references to arrays of values, colors, lables
    my $values = shift;

    my $start;
    my @labelcolors;

    ## Option default settings
    my $imageheight = 500;
    my $imagewidth  = 500;
    my $radius      = 180;
    $imageheight = $$options{imageheight} if $$options{imageheight};
    $imagewidth  = $$options{imagewidth}  if $$options{imagewidth};
    $radius      = $$options{radius}      if $$options{radius};

    my $cx = int($imagewidth  / 2) - 50;
    my $cy = int($imageheight / 2);
    $cx = $$options{centerleft} if $$options{centerleft};
    $cy = $$options{centertop}  if $$options{centertop};

    my $borderwidth = 4;
    $borderwidth = $$options{borderwidth} if defined $$options{borderwidth};

    ## Calc total
    my $total;
    foreach (@$values) {
	$total += $_->{value};
    }

    ## Create SVG Object
    my $svg = SVG->new(
	width  => $imageheight,
	height => $imageheight,
	title  => ($$options{title} ? $$options{title} : ''),
    );

    ## Draw Lines
    $start = -90;

    my @separator_lines;
    my $pie = $svg->tag('g', id => "pie_chart", transform => "translate($cx,$cy)");

    for (my $i = 0; $i < @$values; $i++) {
	my $slice   = $values->[$i]->{value} / $total * 360;

	my $color = $values->[$i]->{color};
	if ($color eq "") {
	    $color = sprintf 'rgb(%d,%d,%d)',
		int(rand(256)), int(rand(256)), int(rand(256));
	}
	push @labelcolors, $color;

	my $do_arc = 0;
	my $radians = $slice * PI / 180;
	$do_arc++  if $slice > 180;

	my $ry = ($radius * sin($radians));
	my $rx = $radius * cos($radians);
	push(@separator_lines, $rx, $ry, $start);

	my $g = $pie->tag('g', id => "wedge_$i", transform => "rotate($start)");
	$g->path(
	    style => {'fill' => "$color"},
	    d => "M $radius,0 A $radius,$radius 0 $do_arc,1 $rx,$ry L 0,0 z"
	);

	$start += $slice;
    }

    ## Draw circle
    my $circlestyle = {'fill-opacity' => 0};
    if ($borderwidth) {
        $circlestyle->{stroke} = 'black';
        $circlestyle->{'stroke-width'} = $borderwidth;
    }

    $svg->circle(
	cx => $cx,
	cy => $cy,
	r  => $radius,
	style => $circlestyle,
    );

    ## Draw separater
    my $i = 0;
    while (my $start = pop(@separator_lines)) {
	$i++;
	my $separator_y = pop(@separator_lines);
	my $separator_x = pop(@separator_lines);
	my $g = $pie->tag('g', id => "line_$i", transform => "rotate($start)");
        my $linestyle = {};
        if ($borderwidth) {
            $linestyle->{stroke} = 'black';
            $linestyle->{'stroke-width'} = $borderwidth;
        }

	$g->line(
	    x1 => 0,
	    y1 => 0,
	    x2 => $separator_x,
	    y2 => $separator_y,
	    style => $linestyle,
	);
    }

    ## Title
    if ($$options{title}) {
	my $titlestyle = 'font-size:24;';
	$titlestyle = $$options{titlestyle} if $$options{titlestyle};
	$svg->text(
	    'x' => 20,
	    'y' => 40,
	    'style' => $titlestyle,
	)->cdata($$options{title});
    }

    ## Label
    if ($$options{label}) {
	my $labelleft = $cx + $radius + 10;
	$labelleft = $$options{labelleft} if $$options{labelleft};
	$start = $cy - $radius;
	$start = $$options{labeltop} if $$options{labeltop};

	for (my $i = 0; $i < @$values; $i++) {
	    $svg->rectangle(
		'x' => $labelleft,
		'y' => $start,
		'width' => 20,
		'height' => 20,
		'rx' => 5,
		'ry' => 5,
		'style' => {
		    fill => $labelcolors[$i],
		    stroke => 'black',
		},
	    );
	    $svg->text(
		'x' => $labelleft + 25,
		'y' => $start + GAP,
	    )->cdata($values->[$i]->{label});

	    $start += 25;
	}
    }

    return $svg->xmlify;
}

## private method
sub _round {
    my $decimal = shift;

    $decimal *= 10;
    $decimal = int($decimal + 0.5);
    $decimal /= 10;

    return $decimal;
}

1;
__END__

=head1 NAME

SVGGraph::Pie - Perl extension for Pie as SVG

=head1 SYNOPSIS

  use SVGGraph::Pie;

  my $svggraph = SVGGraph::Pie->new;
  $svggraph->CreateGraph(
      {
          imageheight => 500,
          imagewidth  => 500,
          centertop  => 250,
          centerleft => 250,
          radius => 200,
          title => 'Financial Results Q1 2002',
          titlestyle => 'font-size:24;fill:#FF0000;',
          borderwidth => 4, # border line's width
          label => 'true',  # Woud you like display label?
          labeltop  => '100',
          labelleft => '400',
      },
      [
          {value => 10, color => 'red'},
          {value => 20, color => 'blue'),
          ...
          ..
          .
      ],
  );

=head1 DESCRIPTION

SVGGraph::Pie allow you to create Piegraphs as SVG very easily.

=head1 EXAMPLES

  #!/usr/bin/perl -w

  use strict;
  use SVGGraph::Pie;

  my @values = (
      {value => 11, color => 'red'},
      {value => 23, color => 'rgb(200,0,0)'},
      {value => 39, color => 'rgb(150,0,0)'},
      {value => 13, color => 'rgb(100,0,0)'},
      {value => 44, color => 'rgb(100,0,50)'},
      {value => 50, color => 'rgb(50,0,100)'},
      {value => 60, color => 'rgb(0,0,100)'},
      {value => 12, color => 'rgb(0,0,150)'},
      {value => 39, color => 'rgb(0,0,200)'},
  );

  my $svggraph = SVGGraph::Pie->new;

  print "Content-type: image/svg-xml\n\n";
  print $svggraph->CreateGraph(
      {
          imageheight => 500,
          imagewidth  => 1000,
          radius => 200,
          title => 'Financial Results Q1 2002',
          titlestyle => 'font-size:24;fill:#FF0000;',
          borderwidth => 4,
          label => 'true',
      },
      \@values,
  );


=head1 AUTHOR

milano <milano@cpan.org>

=head1 SEE ALSO

SVG, SVGGraph

=cut
