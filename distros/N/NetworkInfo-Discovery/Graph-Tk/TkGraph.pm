package TkGraph;

use Tk;
use Tk::Canvas;
use base "Graph::Undirected";
use Graph::Reader::XML;
use strict;
use warnings;

use vars qw($AUTOLOAD %ok_field);

# Authorized attribute fields
for my $attr ( qw(id canvas balloon  color size center velocityx velocityy x y dx dy) ) { $ok_field{$attr}++; } 

sub new {
    my $class = shift;
    my %args = @_;

    my $self = { };
    if (exists $args{'file'}) {
	$self = &read_graph($args{'file'}) ;
    }
    bless $self, $class;


    $self->canvas($args{canvas});

    return $self;
}


sub show_verts {
    my $self = shift;

    my @e = $self->edges;
    while (@e) {
	my ($u, $v) =  (shift @e, shift @e);

	my $id = $self->get_attribute("id", $u, $v);

	my $x1 = $self->get_attribute("x", $u);
	my $y1 = $self->get_attribute("y", $u);

	my $x2 = $self->get_attribute("x", $v);
	my $y2 = $self->get_attribute("y", $v);

	$self->canvas->coords($id,
	    $x1, $y1, 
	    $x2, $y2,
	    );
    }

    foreach my $v ($self->toposort) {
	$self->make_tk_node($v);
	my $id = $self->get_attribute("id", $v);
	my $nx = $self->get_attribute("x", $v);
	my $ny = $self->get_attribute("y", $v);
	my $size = $self->get_attribute("size", $v);

	$self->canvas->coords($id,
	    $nx-($size/2), $ny-($size/2),
	    $nx+($size/2), $ny+($size/2),
	    );
    }


}

sub circular_map {
    my $self = shift;
    $self->circular_map_verts;
    $self->map_edges;
}
sub random_map {
    my $self = shift;
    $self->random_map_verts;
    $self->map_edges;
}

sub circular_map_verts {
    my $self = shift;

    my @nodes = $self->vertices;
    my $gamma= 2* 3.14159 / ($#nodes+1);
    my $rayon = 100; 

    my $x;
    my $y;
    my $i=0;
    foreach my $v (@nodes) {
	$self->make_tk_node($v);
	
	$x = $rayon *cos($gamma * $i) + $rayon*2;
	$y = $rayon *sin($gamma * $i) + $rayon*2;

	$self->set_attribute("x", $v, $x);
	$self->set_attribute("y", $v, $y);
	$i++;
    }
}

sub random_map_verts {
    my $self = shift;

    my @nodes = $self->vertices;

    my $x;
    my $y;

    my $height = $self->canvas->cget(-height) ;
    my $width = $self->canvas->cget(-width) ;
    foreach my $v (@nodes) {
	$self->make_tk_node($v);

	my $minx = $self->get_attribute("size", $v) / 2;
	my $miny = $self->get_attribute("size", $v) / 2;
	my $maxx = $width -$minx;
	my $maxy = $height -$miny;

	$x = rand ($maxx-$minx) + $minx;
	$y = rand ($maxy-$miny) + $miny;

	$self->set_attribute("x", $v, $x);
	$self->set_attribute("y", $v, $y);
    }
    
    
}
sub map_edges {
    my $self = shift;

    #print " " . join("," , caller()) . "\n";
    my @e = $self->edges;
    while (@e) {
	my ($u, $v) =  (shift @e, shift @e);
	$self->make_tk_edge($u, $v);

	my $x1 = $self->get_attribute("x", $u);
	my $x2 = $self->get_attribute("x", $v);
	my $y1 = $self->get_attribute("y", $u);
	my $y2 = $self->get_attribute("y", $v);

	$self->set_attribute("x1", $u, $v, $x1);
	$self->set_attribute("x2", $u, $v, $x2);
	$self->set_attribute("y1", $u, $v, $y1);
	$self->set_attribute("y2", $u, $v, $y2);

    }

}

sub map_verts {
    my $self = shift;

    my $store_x = 30;
    my $store_y = 30;

    foreach my $v ($self->vertices) {
	if ($self->has_attribute("id", $v) ) {
	    # we have already displyd this once... use the id...
	    my $id = $self->get_attribute("id", $v);
	    my $nx = $self->get_attribute("x", $v);
	    my $ny = $self->get_attribute("y", $v);
	    my $size = $self->get_attribute("size", $v);
	
	    my @neighbors = $self->neighbors($v);

	    if (@neighbors) {
		my $degrees_per_neighbor = 360/($#neighbors+1);
    
		foreach (@neighbors) {
		    my $dx = 2 * $size * cos($degrees_per_neighbor);
		    my $dy = 2 * $size * sin($degrees_per_neighbor);
		    $degrees_per_neighbor += $degrees_per_neighbor;
		    $self->set_attribute("x", $_, $nx + $dx);
		    $self->set_attribute("y", $_, $ny + $dy);
		}
	    } else {
		$self->set_attribute("x", $v, $store_x);
		$self->set_attribute("y", $v, $store_y);

		$store_x += (2*$size);
	    }

	} else {
	    # make an oval, set some attrs
	    $self->make_tk_node($v);
	}
    }
}


sub make_tk_edge {
    my $self = shift;
    my $u = shift;
    my $v = shift;

    return 1 if ($self->has_attribute("id", $u, $v));

    my $x1 = 50;
    my $y1 = 40;
    my $x2 = 250;
    my $y2 = 240;
    my $color = "white";

    my $id = $self->canvas->createLine(
	$x1, $y1,
	$x2, $y2,
	-fill => $color,
    );

    $self->set_attribute("id",	   $u, $v, $id);
    $self->set_attribute("color",  $u, $v, $color);
}

sub make_tk_node {
    my $self = shift;
    my $v = shift;

    return 1 if ($self->has_attribute("id", $v));

    my $x = 250;
    my $y = 40;
    my $size = 20;
    my $center = $size/2;
    my $color = "green";

    my $id = $self->canvas->createOval(
	$x - $center, $y - $center,
	$x + $center, $y + $center,
	-fill => $color,
    );


    $self->set_attribute("id",	   $v, $id);
    $self->set_attribute("balloonid",$v, $b);
    $self->set_attribute("x",	   $v, $x);
    $self->set_attribute("y",	   $v, $y);
    $self->set_attribute("size",   $v, $size);
    $self->set_attribute("center", $v, $center);
    $self->set_attribute("color",  $v, $color);
}


sub read_graph {
    my $file = shift;
    
    my $reader = Graph::Reader::XML->new();
    my $graph = $reader->read_graph( $file );

    return $graph;
}

 sub AUTOLOAD {
     my $self = shift;
     my $attr = $AUTOLOAD;
     $attr =~ s/.*:://;
     return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
     warn "invalid attribute method: ->$attr()" unless $ok_field{$attr};
     $self->{uc $attr} = shift if @_;
     return $self->{uc $attr};
}
1;
