package SpringGraph;

=head1 NAME

SpringGraph - Directed Graph alternative to GraphViz

=head1 SYNOPSIS

use SpringGraph qw(calculate_graph draw_graph);


## object oriented interface ##

my $graph = new SpringGraph;

# add a node to the graph  (with optional label)

$graph->add_node('Paris', label =>'City of Love');

# add an edge to the graph (with optional label, and directed)

$graph->add_edge('London' => 'New York', label => 'Far', dir=>1);

# output the graph to a file

$graph->as_png($filename);

# get the graph as GD image object

$graph->as_gd;

## procedural interface ##

my %node = (
	    london => { label => 'London (Waterloo)'},
	    paris => { label => 'Paris' },
	    brussels => { label => 'Brussels'},
	   );

my %link = (
	    london => { paris => {style => 'dotted'}, 'new york' => {} }, # non-directed, dotted and plain lines
	    paris => { brussels => { dir => 1}  }, # directed from paris to brussels
	   );

my $graph = calculate_graph(\%node,\%link);

draw_graph($filename,\%node,\%link);

=head1 DESCRIPTION

SpringGraph.pm is a rewrite of the springgraph.pl script, which provides similar functionality to Neato and can read some/most dot files.

The goal of this module is to provide a compatible interface to VCG and/or GraphViz perl modules on CPAN. This module will also provide some extra features to provide more flexibility and power.

=head1 METHODS

=cut

use strict;
use Data::Dumper;
use GD;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(&calculate_graph &draw_graph);
our $VERSION = 0.05;

use constant PI => 3.141592653589793238462643383279502884197169399375105;

=head1 Class Methods

=head2 new

Constructor for the class, returns a new SpringGraph object

my $graph = SpringGraph->new;

=cut

sub new {
    my ($class) = @_;
    my $self = bless( {scale=> 1,nodes => {}, links=>{} }, ref $class || $class);
    return $self;
}

=head2 calculate_graph

returns a hashref of the nodes in the graph, populated with coordinates

my $graph = calculate_graph(\%node,\%link);

=cut

sub calculate_graph {
    my ($nodes,$links) = @_;
#    warn "calculate_graph called with : ", @_, "\n";
    my $scale = 1;
    my $push = 450;
    my $pull = .080;
    my $maxiter = 100;
    my $rate = 0.8;
    my $done = 0.3;
    my $continue = 5;
    my $iter = 0;
    my $movecount;

    my $self = bless ({}, 'SpringGraph');
    my %node = %{$self->_position_nodes_in_tree ($nodes,$links)};
    my %link = %$links;

    while($continue && ($iter <= $maxiter) ) {
	$continue = 0;
	$iter++;
	my ($xmove,$ymove) = (0,0);
#	warn "iter : $iter\n";
	foreach my $nodename (keys %$nodes) {
#	    warn "-- nodename : $nodename\n";
#	    warn "x : $node{$nodename}{x} --- y : $node{$nodename}{y}\n";
	    $node{$nodename}{oldx} = $node{$nodename}{x};
	    $node{$nodename}{oldy} = $node{$nodename}{'y'};
	}

	foreach my $source (keys %$nodes) {
	    my $movecount = 0;
	    my ($pullmove,$pushmove);
	    foreach my $dest (keys %$nodes) {
		my $xdist = $node{$source}{oldx} - $node{$dest}{oldx};
		my $ydist = $node{$source}{oldy} - $node{$dest}{oldy};
		my $dist = sqrt(abs($xdist)**2 + abs($ydist)**2);
		next if ($source eq $dest);
#		warn "--- source : $source / dest : $dest \n";
		my $wantdist = $dist;
		if ($dist <= 65) {
		    $wantdist = $push * 2;
#		    print "pushing apart $source and $dest - current dist : $dist, want dist $wantdist\n";
		} else {
		    if ($link{$source}{$dest} || $link{$dest}{$source}) {
			# $wantdist = $dist + ($push / ($dist + 5));
			if ($link{$source}{$dest}) {
			    $wantdist = $wantdist - ($pull * $dist);
			}
			if ($link{$dest}{$source}) {
			    $wantdist = $wantdist - ($pull * $dist);
			}
		    } else {
			$wantdist = $push * (0.65 - $pull) unless ($dist > 150);
			next if ($dist > 200);
		    }
		}
#		warn "xdist : $xdist / wantdist :$wantdist\n";
		my $percent = ($wantdist/($dist+1));
		my $wantxdist = ($xdist * $percent);
		my $wantydist = ($ydist * $percent ) + 5;
#		warn "percent : $percent /  want x dist :$wantxdist / want y dist :$wantydist\n";
		$xmove += ($xdist - $wantxdist)*$rate;
		$ymove += ($ydist - $wantydist)*$rate;
#		warn "xmove : $xmove / ymove : $ymove\n";
		$movecount++;
	    }
	    $xmove = $xmove / $movecount if ($movecount);
	    $ymove = $ymove / $movecount if ($movecount);
#	    warn "xmove : $xmove / ymove : $ymove\n";
	    $node{$source}{x} -= $xmove;
	    $node{$source}{'y'} -= $ymove;
	    if ($xmove >= $done or $ymove >= $done) {
		if ($xmove > $continue) {
		    $continue = $xmove;
		}
		if ($ymove > $continue) {
		    $continue = $ymove;
		}
	    }
	}
    }
    foreach my $source (keys %$nodes) {
	foreach my $color ('r', 'g', 'b') {
	    $node{$source}{$color} = 255 unless (defined $node{$source}{$color});
	}
    }
    return \%node;
}


=head2 draw_graph

outputs the graph as a png file either to the file specified by the filename or to STDOUT

takes filename, hashref of nodes and list of edges

draw_graph($filename,\%node,\%link);


=cut

sub draw_graph {
    my ($filename,$nodes,$links) = @_;
    &draw(1,$nodes,$links,filename=>$filename);
    return;
}

=head1 Object Methods

=head2 add_node

adds a node to a graph

takes the name of the node and any attributes such as label

# just like GraphViz.pm :)
$graph->add_node('Paris', label =>'City of Love');

=cut

sub add_node {
    my ($self,$name,%attributes) = @_;
    ($attributes{height},$attributes{width}) = get_node_size($attributes{type},$attributes{label}||$name);
    if ( ref $self->{nodes}{$name}) {
	foreach (keys %attributes) {
	    $self->{nodes}{$name}{$_} = $attributes{$_};
	}
    } else {
	$self->{nodes}{$name} = { %attributes };
    }
    $self->{nodes}{$name}{label} ||= $name;
    $self->{nodes}{$name}{type} ||= 'plain';
    $self->{nodes}{$name}{name} = $name;
    $self->{nodes}{$name}{weight} ||= 1;

    ($self->{nodes}{$name}{height},$self->{nodes}{$name}{width}) = get_node_size($self->{nodes}{$name}{type},$self->{nodes}{$name}{label});

    return;
}

=head2 add_edge

adds an edge to a graph

takes the source and destination of the edge and
attributes such as style (dotted or dashed), or
if the line is directed or not

$graph->add_edge('London' => 'New York', dir  => 1, style=>'dashed');

=cut

sub add_edge {
    my ($self,$source,$dest,%attributes) = @_;
    $self->add_node($source) unless ($self->{nodes}{$source});
    $self->add_node($dest) unless ($self->{nodes}{$dest});
    $self->{links}{$source}{$dest} = {%attributes};
    $self->{nodes}{$dest}{weight}++;
    return;
}


=head2 as_png

prints the image of the graph in PNG format

takes an optional filename or outputs directly to STDOUT

$graph->as_png($filename);

=cut

sub as_png {
    my ($self,$filename) = @_;
    calculate_graph($self->{nodes},$self->{links});
    draw(1,$self->{nodes},$self->{links},filename=>$filename);
    return;
}

=head2 as_gd

returns the GD image object of the graph

my $gd_im = $graph->as_gd;

=cut

sub as_gd {
    my $self = shift;
    calculate_graph($self->{nodes},$self->{links});
    my $im = draw(1,$self->{nodes},$self->{links},gd=>1);
    return $im;
}

=head2 as_gd

returns the image of the graph in a string in the format specified or PNG

my $graph_png = $graph->as_image('png');

=cut

sub as_image {
    my ($self,$format) = @_;
    calculate_graph($self->{nodes},$self->{links});
    my $im = draw(1,$self->{nodes},$self->{links},image=>1,image_format=>$format);
    return $im;
}

################################################################################
# internal functions

sub draw {
    my ($scale,$nodes,$links,%options) = @_;
    my %node = %$nodes;
    my %link = %$links;

    my ($maxx,$maxy);
    my ($minx,$miny);
    my ($maxxlength,$minxlength);
    my ($maxylength,$minylength);
    my $margin = 20;
    my $nodesize = 40;
    my @point = ();

    foreach my $nodename (keys %node) {
#	warn "getting maxx/minx for $nodename\n";
#	warn Dumper($nodename=>$node{$nodename});
	if (!(defined $maxx) or (($node{$nodename}{x} + (length($node{$nodename}{'label'}) * 8 + 16)/2) > $maxx + (length($node{$nodename}{'label'}) * 8 + 16)/2)) {
	    $maxx = $node{$nodename}{x};
	    $maxxlength = (length($node{$nodename}{'label'}) * 8 + 16)/2;
	}
	if (!(defined $minx) or (($node{$nodename}{x} - (length($node{$nodename}{'label'}) * 8 + 16)/2) < $minx - (length($node{$nodename}{'label'}) * 8 + 16)/2)) {
	    $minx = $node{$nodename}{x};
	    $minxlength = (length($node{$nodename}{'label'}) * 8 + 16)/2;
	}

	$maxy = $node{$nodename}{'y'} if (!(defined $maxy) or $node{$nodename}{'y'} > $maxy);
	$miny = $node{$nodename}{'y'} if (!(defined $miny) or $node{$nodename}{'y'} < $miny);
    }

    foreach my $nodename (keys %node) {
	$node{$nodename}{x} = ($node{$nodename}{x} - $minx) * $scale + $minxlength -1 ;
	$node{$nodename}{'y'} = ($node{$nodename}{'y'} - $miny) * $scale + $nodesize/2 - 1;
    }

    $maxx = (($maxx - $minx) * $scale + $minxlength + $maxxlength) * 1.25;
    $maxy = (($maxy - $miny) * $scale + $nodesize/2*2 + 40) * 1.2;
    my $im = new GD::Image($maxx,$maxy);
    my $white = $im->colorAllocate(255,255,255);
    my $blue = $im->colorAllocate(0,0,255);
    my $powderblue = $im->colorAllocate(176,224,230);
    my $black = $im->colorAllocate(0,0,0);
    my $darkgrey = $im->colorAllocate(169,169,169);
    $im->transparent($white);	# make white transparent

    foreach my $node (keys %node) {
	my $color = $white;
	if (defined $node{$node}{r} and defined $node{$node}{g} and defined $node{$node}{b}) {
	    $color = $im->colorResolve($node{$node}{r}, $node{$node}{g}, $node{$node}{b});
	}
	if (defined $node{$node}{shape} and $node{$node}{shape} eq 'record') {
	    $node{$node}{boundary} = addRecordNode ($im,$node{$node}{x},$node{$node}{'y'},$node{$node}{'label'},$maxx,$maxy);
	} else {
	    addPlainNode($im,$node{$node}{x},$node{$node}{'y'},$node{$node}{'label'});
	}
    }

    # draw lines
    foreach my $source (keys %node) {
	my ($topy,$boty) = ($node{$source}{'y'} -20,$node{$source}{'y'} + 20);
	foreach my $dest (keys %{$link{$source}}) {
#	    warn "source : $source / dest : $dest";
	    my ($destx,$desty) = ($node{$dest}{x},$node{$dest}{'y'}) ;
	    my ($sourcex,$sourcey) = ($node{$source}{x}, ( $node{$source}{'y'} < $node{$dest}{'y'} ) ? $boty : $topy );
	    my $colour = $darkgrey;
	    if ( defined $link{$source}{$dest}{style}) {
		$im->setStyle( getLineStyle($link{$source}{$dest}{style},$colour) );
		$colour = gdStyled;
	    }

	    if (defined $node{$dest}{boundary}) {
		$destx = ( $node{$source}{x} < $node{$dest}{x} )
		    ? $node{$dest}{boundary}[0] : $node{$dest}{boundary}[2] ;
		$desty = ( $node{$source}{'y'} < $node{$dest}{'y'} )
		    ? $node{$dest}{boundary}[1] : $node{$dest}{boundary}[3] ;
	    } else {
		$desty = $node{$dest}{'y'};

	    }

	    # position start of line if source is record node
	    if ($node{$source}{width} and $node{$source}{shape} eq 'record') {
#		warn "source node $source is a record and has a width of $node{$source}{width}\n";
		my ($width,$height) = ($node{$source}{width},$node{$source}{height});
#		warn "got width ($width) and height ($height) for source\n";
		if ($node{$source}{x} - ($height/2) < 0) {
		    $node{$source}{x} = 5 + $height/2;
		}
#		warn "source node has x of $node{$source}{x} and y of $node{$source}{'y'}\n";
		my $ydiff = ( $desty - $node{$source}{'y'} ) ? $node{$source}{'y'} - $desty: $desty - $node{$source}{'y'};
		my $xdiff = ( $destx < $node{$source}{x} ) ?  $node{$source}{x} - $destx : $destx - $node{$source}{x};
#		warn "xdiff : $xdiff, ydiff : $ydiff\n";
		my $tan_theta = ($desty - $node{$source}{'y'}) / ( $destx - $node{$source}{x} );
#		warn "got tan of angle : $tan_theta : which is ($desty - $node{$source}{y}) / ( $destx - $node{$source}{x} ) \n";


		my $xx = ( $node{$source}{x} > $destx) ? ( 0 - ($width / 2)) : ( 0 + ($width / 2));
		my $yy = ( $node{$source}{'y'} > $desty) ? ( 0 - ($height / 2)) : ( 0 + ($height / 2));

#		warn "xx : $xx, yy : $yy\n";

		my $exitx = $yy / $tan_theta ;

#		warn "got exitx : $exitx\n";
		if (($xx > 0 and $exitx > $xx) or (($xx < 0) and $exitx < $xx) ) {
		    $tan_theta = ($destx - $node{$source}{x}) / ( $desty - $node{$source}{'y'} );
		    my $exity = $xx / $tan_theta;
#		    warn "got exity : $exity\n";
		    $sourcex = $node{$source}{x} + $xx;
		    if ($xx > 0) { $sourcex+=2; } else { $sourcex-=2; }
		    $sourcey = int($node{$source}{'y'} + $exity);
		} else {
		    $sourcex = int($node{$source}{x} + $exitx);
		    $sourcey = $node{$source}{'y'} + $yy;
		    if ($yy > 0) { $sourcey+=2; } else { $sourcey-=2; }
		}
#		warn "sourcex : $sourcex / sourcey : $sourcey\n";

	    }
	    # draw line
	    $im->line($sourcex,$sourcey, $destx, $desty, $colour);
	    unless (defined $node{$dest}{boundary}) { # cheat and redraw plain node over line
		addPlainNode($im,$node{$dest}{x},$node{$dest}{'y'},$node{$dest}{'label'});
	    }

	    # add arrowhead
	    if ($link{$source}{$dest}{dir}) {
		addArrowHead ($im,$sourcex,$destx,$sourcey,$desty,$node{$dest}{shape},$node{$dest}{'label'});
	    }
	}
    }

    # output the image
    if ($options{gd}) {
	return $im;
    }
    if ($options{image}) {
	if ($im->can($options{image_format})) {
	    my $format = $options{image_format};
	    return $im->$format();
	} else {
	    return $im->png;
	}
    }
    if ($options{filename}) {
	open (OUTFILE,">$options{filename}") or die "couldn't open $options{filename} : $!\n";
	binmode OUTFILE;
	print OUTFILE $im->png;
	close OUTFILE;
    } else {
	binmode STDOUT;
	print $im->png;
    }
    return; # maybe we should return something.. nah
}


sub addRecordNode {
    my ($im,$x,$y,$string,$maxx,$maxy) = @_;
    my $white = $im->colorAllocate(255,255,255);
    my $blue = $im->colorAllocate(0,0,255);
    my $powderblue = $im->colorAllocate(176,224,230);
    my $black = $im->colorAllocate(0,0,0);
    my $darkgrey = $im->colorAllocate(169,169,169);
    my $red = $im->colorAllocate(255,0,0);

    # split text on newline, or |
    my @record_lines = split(/\s*([\n\|])\s*/,$string);

    my $margin = 3;
    my ($height,$width) = (0,0);
    foreach my $line (@record_lines) {
    LINE: {
	    if ($line eq '|') {
		$height += 4;
		last LINE;
	    }
	    if ($line eq "\n") {
		last LINE;
	    }
	    $height += 18;
	    my $this_width = get_width($line);
	    $width = $this_width if ($width < $this_width );
	} # end of LINE
    }

    $height += $margin * 2;
    $width += $margin * 2;

    my $topx = $x - ($width / 2);
    my $topy = $y - ($height / 2);
    $topy = 5 if ($topy <= 0);
    $topx = 5 if ($topx <= 0);

    if (($topy + $height ) > $maxy) {
	$topy = $maxy - $height;
    }

#    warn "height : $height, width : $width, start x : $topx, start y : $topy\n";

    # notes (gdSmallFont):
    # - 5px wide, 1px gap between words
    # - 2px up, 2px down, 6px middle

    $im->rectangle($topx,$topy,$topx+$width,$topy+$height,$black);
    $im->fillToBorder($x, $y, $black, $white);

    my ($curx,$cury) = ($topx + $margin, $topy + $margin);
    foreach my $line (@record_lines) {
	next if ($line =~ /\n/);
#	warn "line : $line \n";
	if ($line eq '|') {
	    $im->line($topx,$cury,$topx+$width,$cury,$black);
	    $cury += 4;
	} else {
	    $im->string(gdLargeFont,$curx,$cury,$line,$black);
	    $cury += 18;
	}
#	warn "current x : $curx, current y : $cury\n";
    }

    # Put a black frame around the picture
    my $boundary = [$topx,$topy,$topx+$width,$topy+$height];
    return $boundary;
}

sub get_width {
#    warn "get_width called with ", @_, "\n";
    my $string = shift;
    my $width = ( length ($string) * 9) - 2;
#    warn "width : $width\n";
    return $width;
}


sub get_node_size {
    my ($type,$string) = @_;
    # split text on newline, or |
    my ($height,$width);
    if ( lc($type) eq 'record' ) {
	my @record_lines = split(/\s*([\n\|])\s*/,$string);
	my $margin = 3;
	my ($height,$width) = (0,0);
	foreach my $line (@record_lines) {
	LINE: {
		if ($line eq '|') {
		    $height += 4;
		    last LINE;
		}
		if ($line eq "\n") {
		    last LINE;
		}
		$height += 18;
		my $this_width = get_width($line);
		$width = $this_width if ($width < $this_width );
	    }			# end of LINE
	}

	$height += $margin * 2;
	$width += $margin * 2;
    } else {
	my $longeststring = 1;
	my @lines = split(/\s*\n\s*/,$string);
	foreach (@lines) {
	    $longeststring = length($_) if (length($_) > $longeststring );
	}
	$height = 40 + (18 * (scalar @lines - 1));
	$width = length($longeststring) * 8 + 16;
    }
    return ($height,$width);
}

sub addPlainNode {
    my ($im,$x,$y,$string,$color) = @_;
    my $white = $im->colorAllocate(255,255,255);
    my $blue = $im->colorAllocate(0,0,255);
    my $powderblue = $im->colorAllocate(176,224,230);
    my $black = $im->colorAllocate(0,0,0);
    my $darkgrey = $im->colorAllocate(169,169,169);

    $color ||= $white;
    $im->arc($x,$y,(length($string) * 8 + 16),40,0,360,$black);
    $im->fillToBorder($x, $y, $black, $color);
    $im->string( gdLargeFont, ($x - (length($string)) * 8 / 2), $y-8, $string, $black);
    return;
}


sub addArrowHead {
    my ($im,$sourcex,$destx,$sourcey,$desty,$nodetype,$nodetext) = @_;
    my @point = ();
    my $darkgrey = $im->colorAllocate(169,169,169);
    my $white = $im->colorAllocate(255,255,255);
    my $blue = $im->colorAllocate(0,0,255);
    my $powderblue = $im->colorAllocate(176,224,230);
    my $black = $im->colorAllocate(0,0,0);
    my $red = $im->colorAllocate(255,0,0);

    my $arrowlength = 10; # pixels
    my $arrowwidth = 10;
    my $height = (defined $nodetype and $nodetype eq 'record') ? 5 : 20 ;
    my $width = (defined $nodetype and $nodetype eq 'record') ? 5 : (length($nodetext) * 8 + 16)/2;;

    # I'm pythagorus^Wspartacus!
    my $xdist = $sourcex - $destx;
    my $ydist = $sourcey - $desty;
    my $dist = sqrt( abs($xdist)**2 + abs($ydist)**2 );
    my $angle = &acos($xdist/$dist);

    $dist = sqrt( ($height**2 * $width**2) / ( ($height**2 * (cos($angle)**2) ) + ($width**2 * (sin($angle)**2) ) ));

    my ($x,$y);
    my $xmove = cos($angle)*($dist+$arrowlength-3);
    my $ymove = sin($angle)*($dist+$arrowlength-3);

    if (defined $nodetype and $nodetype eq 'record') {
	$point[2]{x} = $xmove;
	$point[2]{'y'} = $ymove;

	$dist = 4;
	$xmove = $xmove + cos($angle)*$dist;
	$ymove = $ymove + sin($angle)*$dist;

	$angle = $angle + PI/2;
	$dist = $arrowwidth/2;
	$xmove = $xmove + cos($angle)*$dist;
	$ymove = $ymove + sin($angle)*$dist;

	$point[0]{x} = $xmove;
	$point[0]{'y'} = $ymove;

	$angle = $angle + PI;
	$dist = $arrowwidth;
	$xmove = $xmove + cos($angle)*$dist;
	$ymove = $ymove + sin($angle)*$dist;
	$point[1]{x} = $xmove;
	$point[1]{'y'} = $ymove;

	foreach my $num (0 .. 2) {
	    $point[$num]{'y'} = - $point[$num]{'y'} if $ydist < 0;
	}

	$im->line( $destx, $desty, $destx+$point[0]{x}, $desty+$point[0]{'y'}, $darkgrey );
	$im->line( $destx+$point[0]{x}, $desty+$point[0]{'y'}, $destx+$point[1]{x}, $desty+$point[1]{'y'}, $darkgrey );
	$im->line( $destx+$point[1]{x}, $desty+$point[1]{'y'},$destx, $desty, $darkgrey);

	$x = int(($point[1]{x} + $point[0]{x}) / 2.5);
	$y = int(($point[1]{'y'} + $point[0]{'y'}) / 2.5);
	#    $im->setPixel($destx + $x, $desty + $y, $red);

    } else {
        $dist = sqrt( abs($sourcex - $destx)**2 +  abs($sourcey-$desty)**2 );
	$xdist = $sourcex - $destx;
	$ydist = $sourcey - $desty;
	$angle = &acos($xdist/$dist);
        $dist = sqrt( ($height**2 * $width**2) / ( ($height**2 * (cos($angle)**2) ) + ($width**2 * (sin($angle)**2) ) ));
        $xmove = cos($angle)*$dist;
        $ymove = sin($angle)*$dist;

        $point[0]{x} = $xmove;
        $point[0]{'y'} = $ymove;

        $xmove = cos($angle)*($dist+$arrowlength-3);
	$ymove = sin($angle)*($dist+$arrowlength-3);
	$point[3]{x} = $xmove;
	$point[3]{'y'} = $ymove;

	$dist = 4;
	$xmove = $xmove + cos($angle)*$dist;
	$ymove = $ymove + sin($angle)*$dist;

	$angle = $angle + PI/2;
        $dist = $arrowwidth/2;
        $xmove = $xmove + cos($angle)*$dist;
        $ymove = $ymove + sin($angle)*$dist;

        $point[1]{x} = $xmove;
        $point[1]{'y'} = $ymove;
        $angle = $angle + PI;
        $dist = $arrowwidth;
        $xmove = $xmove + cos($angle)*$dist;
        $ymove = $ymove + sin($angle)*$dist;

        $point[2]{x} = $xmove;
        $point[2]{'y'} = $ymove;
        for my $num (0 .. 3)
        {
          $point[$num]{'y'} = - $point[$num]{'y'} if $ydist < 0;
        }
        $im->line($destx+$point[0]{x},$desty+$point[0]{'y'},$destx+$point[1]{x},$desty+$point[1]{'y'},$darkgrey);
        $im->line($destx+$point[1]{x},$desty+$point[1]{'y'},$destx+$point[2]{x},$desty+$point[2]{'y'},$darkgrey);
        $im->line($destx+$point[2]{x},$desty+$point[2]{'y'},$destx+$point[0]{x},$desty+$point[0]{'y'},$darkgrey);

	$x = int(($point[0]{x} + $point[1]{x} + $point[2]{x}) / 3.1);
	$y = int(($point[0]{'y'} + $point[1]{'y'}  + $point[2]{'y'}) / 3.1);
    }
#    $im->setPixel($destx + $x, $desty + $y, $red);
    $im->fillToBorder($destx + $x, $desty + $y, $darkgrey, $darkgrey);
    return;
}

sub getLineStyle {
    my ($style,$colour) = (lc(shift),@_);

    my @colors = ();
 STYLE: {
	if ($style eq 'dashed') {
	    @colors = ($colour,$colour,$colour,$colour,$colour,gdTransparent,gdTransparent);
	    last;
	}
	if ($style eq 'dotted') {
	    @colors = ($colour,$colour,gdTransparent,gdTransparent);
	    last;
	}
	warn "unrecognised line style : $style\n";
    }
    return @colors;
}

# from perlfunc(1)
sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }

sub _position_nodes_in_tree {
    my ($self,$nodes,$links) = @_;
#    warn "calculate_graph called with : ", @_, "\n";
    my %node = %$nodes;
    my %link = %$links;

    my @edges = ();
    my @rows  = ();
    my @row_heights = ();
    my @row_widths = ();

    foreach my $nodename (keys %node) {
#	warn "handling node : $nodename\n";
	$node{$nodename}{label} ||= $nodename;
	# count methods and attributes to give height
	my @record_lines = split(/\s*([\n\|])\s*/,$node{$nodename}{label});
	my $margin = 3;
	my ($height,$width) = (0,0);
	foreach my $line (@record_lines) {
	LINE: {
		if ($line eq '|') {
		    $height += 4;
		    last LINE;
		}
		if ($line eq "\n") {
		    last LINE;
		}
		$height += 18;
		my $this_width = get_width($line);
		$width = $this_width if ($width < $this_width );
	    } # end of LINE
	}

	$node{$nodename}{height} = $height;
	$node{$nodename}{width} = $width;
	$node{$nodename}{children} = [];
	$node{$nodename}{parents} = [];
	$node{$nodename}{center} = [];
	$node{$nodename}{weight} = 0;
    }

#    warn "getting links..\n";
    foreach my $source (keys %link) {
#	warn "source : $source\n";
	foreach my $dest (keys %{$link{$source}}) {
#	    warn "dest : $dest\n";
#	    warn "dest node : $node{$dest} -- source node : $node{$source}\n";
	    push (@edges, { to => $dest, from => $source });
	}
    }

    # first pass (build network of edges to and from each node)
    foreach my $edge (@edges) {
	my ($from,$to) = ($edge->{from},$edge->{to});
#	warn "handling edge : $edge -- from : $from / to : $to\n";
	push(@{$node{$to}{parents}},$from);
	push(@{$node{$from}{children}},$to);
    }

    # second pass (establish depth ( ie verticle placement of each node )
#    warn "getting depths for nodes\n";
    foreach my $node (keys %node) {
#	warn ".. node : $node\n";
	my $depth = 0;
	foreach my $parent (@{$node{$node}{parents}}) {
#	    warn "parent : $parent\n";
	    my $newdepth = get_depth($parent,$node,\%node);
	    $depth = $newdepth if ($depth < $newdepth);
	}
	$node{$node}{depth} = $depth;
#	warn "depth for node $node : $depth\n";
	push(@{$rows[$depth]},$node)
    }

    # calculate height and width of diagram in discrete steps
    my $i = 0;
    my $widest_row = 0;
    my $total_height = 0;
    my $total_width = 0;
    my @fixedrows = ();
    foreach my $row (@rows) {
	unless (ref $row) { $row = []; next }
	my $tallest_node_height = 0;
	my $widest_node_width = 0;
	$widest_row = scalar @$row if ( scalar @$row > $widest_row );
	my @newrow = ();
#	warn Dumper(ThisRow=>$row);
	foreach my $node (@$row) {
#	    warn " adding $node node to row \n";
	    next unless (defined $node && defined $node{$node});
	    $tallest_node_height = $node{$node}{height}	if ($node{$node}{height} > $tallest_node_height);
	    $widest_node_width = $node{$node}{width} if ($node{$node}{width} > $widest_node_width);
	    push (@newrow,$node);
	}
	push(@fixedrows,\@newrow);
	$row_heights[$i] = $tallest_node_height + 0.5;
	$row_widths[$i] = $widest_node_width;
	$total_height += $tallest_node_height + 0.5 ;
	$total_width += $widest_node_width;
	$i++;
    }
    @rows = @fixedrows;

    # prepare table of available positions
    my @positions;
    foreach (@rows) {
	my %available;
	@available{(0 .. ($widest_row + 1))} = 1 x ($widest_row + 1);
	push (@positions,\%available);
    }

    my %done = ();
    $self->{_dia_done} = \%done;
    $self->{_dia_nodes} = \%node;
    $self->{_dia_positions} = \@positions;
    $self->{_dia_rows} = \@rows;
    $self->{_dia_row_heights} = \@row_heights;
    $self->{_dia_row_widths} = \@row_widths;
    $self->{_dia_total_height} = $total_height;
    $self->{_dia_total_width} = $total_width;
    $self->{_dia_widest_row} = $widest_row;

    #
    # plot (relative) position of nodes (left to right, follow branch)
    my $side;
    return 0 unless (ref $rows[0]);

    my $row_count = 0;
    foreach my $row (@rows) {
	my @thisrow = sort {$node{$b}{weight} <=> $node{$a}{weight} } @{$row};
	unshift (@thisrow, pop(@thisrow)) unless (scalar @thisrow < 3);
	my $increment = $widest_row / ((scalar @thisrow || scalar $rows[$row_count + 1]) + 1 );
	my $pos = $increment;
#	warn "widest_row : $widest_row // pos : $pos // incremenet : $increment\n";
#	warn "total height : $self->{_dia_total_height}\n";
	my $y = 40 + ( ( $self->{_dia_total_height} / 2) - 5 );

	foreach my $node ( @thisrow ) {
	    next if ($self->{_dia_done}{$node});
#	    warn "handling node ($node) in row $row_count \n";
#	    warn "( $self->{_dia_row_widths}[$row_count] * $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$row_count])\n";
	    my $x = ($self->{_dia_row_widths}[$row_count] * $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$row_count]);
	    $node{$node}{x} = $x;
	    $node{$node}{'y'} = $y;
#	    warn Dumper(nodex=>$node{$node}{x},nodey=>$node{$node}{'y'});
	    if (ref $rows[$row_count + 1] && scalar @{$node{$node}{children}} && scalar @{$rows[$row_count + 1]})  {
		my @sorted_children = sort {
		    $node{$b}{weight} <=> $node{$a}{weight}
		} @{$node{$node}{children}};
		unshift (@sorted_children, pop(@sorted_children));
		my $child_increment = $widest_row / (scalar @{$rows[$row_count + 1]});
#		warn "child_increment : $child_increment = $widest_row / ".scalar @{$rows[$row_count + 1]}."\n";
		my $childpos = $child_increment;
		foreach my $child (@sorted_children) {
#		    warn "child : $child\n";
		    next unless ($child);
		    my $side;
		    if ($childpos <= ( $widest_row * 0.385 ) ) {
			$side = 'left';
		    } elsif ( $childpos <= ($widest_row * 0.615 ) ) {
			$side = 'center';
		    } else {
			$side = 'right';
		    }
		    plot_branch($self,$node{$child},$childpos,$side);
		    $childpos += $child_increment;
		}
	    }
	    $node{$node}{pos} = $pos;
#	    warn "position for node $node : $pos\n";
	    $pos += $increment;
	    $self->{_dia_done}{$node} = 1;
	}
    }
    return \%node;
}

#
## Functions used by _layout_dia_new method
#

# recursively calculate the depth of a node by following edges to its parents
sub get_depth {
    my ($node,$child,$nodes) = @_;
    my $depth = 0;
    $nodes->{$node}{weight}++;
    if (exists $nodes->{$node}{depth}) {
	$depth = $nodes->{$node}{depth} + 1;
    } else {
	$nodes->{$node}{depth} = 1;
	my @parents = @{$nodes->{$node}{parents}};
	if (scalar @parents > 0) {
	    foreach my $parent (@parents) {
		my $newdepth = get_depth($parent,$node,$nodes);
		$depth = $newdepth if ($depth < $newdepth);
	    }
	    $depth++;
	} else {
#	    $depth = 1;
	    $nodes->{$node}{depth} = 0;
	}
    }
    return $depth;
}

# recursively plot the branches of a tree
sub plot_branch {
    my ($self,$node,$pos,$side) = @_;
#    warn "plotting branch : $node->{label} , $pos, $side\n";

    my $depth = $node->{depth};
#    warn "depth : $depth\n";
    my $offset = rand(40);
    my $h = 0;
    while ( $h < $depth ) {
#	warn "row $h height : $self->{_dia_row_heights}[$h]\n";
	$offset += ($self->{_dia_row_heights}[$h++] || 40 ) + 10;
#	warn "offset now $offset\n";
    }

    #  warn Dumper(node=>$node);
    my ($parents,$children) = ($node->{parents},$node->{children});
    if ( $self->{_dia_done}{$node->{name}} && (scalar @$children < 1) ) {
	if (scalar @$parents > 1 ) {
	    $self->{_dia_done}{$node}++;
	    my $sum = 0;
	    foreach my $parent (@$parents) {
#		warn "[ plot branch ] parent : $parent \n";
		return 0 unless (exists $self->{_dia_nodes}{$parent}{pos});
		$sum += $self->{_dia_nodes}{$parent}{pos};
	    }
	    $self->{_dia_positions}[$depth]{int($pos)} = 1;
	    my $newpos = ( $sum / scalar @$parents );
	    unless (exists $self->{_dia_positions}[$depth]{int($newpos)}) {
		# use wherever is free if position already taken
		my $best_available = $pos;
		my $diff = ($best_available > $newpos )
		    ? $best_available - $newpos : $newpos - $best_available ;
		foreach my $available (keys %{$self->{_dia_positions}[$depth]}) {
		    my $newdiff = ($available > $newpos ) ? $available - $newpos : $newpos - $available ;
		    if ($newdiff < $diff) {
			$best_available = $available;
			$diff = $newdiff;
		    }
		}
		$pos = $best_available;
	    } else {
		$pos = $newpos;
	    }
	}
	my $y = 40 + ( ( $self->{_dia_total_height} / 2) - 4 ) + $offset;
#	print "y : $y\n";
	my $x = ( $self->{_dia_row_widths}[$depth] * $self->{_dia_widest_row} / 2)
	    + ($pos * $self->{_dia_row_widths}[$depth]);
	#    my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
	$node->{x} = int($x);
	$node->{'y'} = int($y);
	$node->{pos} = $pos;
	delete $self->{_dia_positions}[$depth]{int($pos)};
	return 0;
    } elsif ($self->{_dia_done}{$node}) {
	return 0;
    }

    unless (exists $self->{_dia_positions}[$depth]{int($pos)}) {
	my $best_available;
	my $diff = $self->{_dia_widest_row} + 5;
	foreach my $available (keys %{$self->{_dia_positions}[$depth]}) {
	    $best_available ||= $available;
	    my $newdiff = ($available > $pos ) ? $available - $pos : $pos - $available ;
	    if ($newdiff < $diff) {
		$best_available = $available;
		$diff = $newdiff;
	    }
	}
	$pos = $best_available;
    }

    delete $self->{_dia_positions}[$depth]{int($pos)};

    my $y = 15 + rand(15) + ( ( $self->{_dia_total_height} / 2) - 1 ) + $offset;
    my $x = 0 + ( $self->{_dia_row_widths}[0] * $self->{_dia_widest_row} / 2)
	+ ($pos * $self->{_dia_row_widths}[0]);
    #  my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
    #  my $x = 0 - ( ( $pos * $self->{_dia_row_widths}[0] ) / 2);
    $node->{x} = int($x);
    $node->{'y'} = int($y);

    $self->{_dia_done}{$node} = 1;
    $node->{pos} = $pos;

    if (scalar @{$node->{children}}) {
	my @sorted_children = sort {
	    $self->{_dia_nodes}{$b}{weight} <=> $self->{_dia_nodes}{$a}{weight}
	} @{$node->{children}};
	unshift (@sorted_children, pop(@sorted_children));
	my $child_increment = (ref $self->{_dia_rows}[$depth + 1]) ? $self->{_dia_widest_row} / (scalar @{$self->{_dia_rows}[$depth + 1]}): 0 ;
	my $childpos = 0;
	if ( $side eq 'left' ) {
	    $childpos = 0
	} elsif ( $side eq 'center' ) {
	    $childpos = $pos;
	} else {
	    $childpos = $pos + $child_increment;
	}
	foreach my $child (@{$node->{children}}) {
	    $childpos += $child_increment if (plot_branch($self,$self->{_dia_nodes}{$child},$childpos,$side));
	}
    } elsif ( scalar @$parents == 1 ) {
	my $y = 0 + ( ( $self->{_dia_total_height} / 2) - 1 ) + $offset;
	my $x = 0 + ( $self->{_dia_row_widths}[0] * $self->{_dia_widest_row} / 2)
	    + ($pos * $self->{_dia_row_widths}[0]);
	#      my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
	#      my $x = 0 - ( ( $pos * $self->{_dia_row_widths}[0] ) / 2);
	$node->{x} = int($x);
	$node->{'y'} = int($y);
    }
    return 1;
}


############################################################

=head1 SEE ALSO

GraphViz

springgraph.pl

http://www.chaosreigns.com/code/springgraph/

GD

=head1 AUTHOR

Aaron Trevena, based on original script by 'Darxus'

=head1 COPYRIGHT

Original Copyright 2002 Darxus AT ChaosReigns DOT com

Amendments and further development copyright 2004 Aaron Trevena

This software is free software. It is made available and licensed under the GNU GPL.

=cut

################################################################################

1;

