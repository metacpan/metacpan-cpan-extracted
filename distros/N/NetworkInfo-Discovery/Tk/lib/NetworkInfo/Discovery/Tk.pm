package NetworkInfo::Discovery::Tk;

use Tk;
use Tk::Canvas;
use NetworkInfo::Discovery::Register;
use base "NetworkInfo::Discovery::Register";

use strict;
use warnings;

use vars qw($AUTOLOAD %ok_field);

# Authorized attribute fields
for my $attr ( qw(id canvas balloon  color size center velocityx velocityy x y dx dy) ) { $ok_field{$attr}++; } 

sub new {
    my $proto = shift;
    my %args = @_;

    my $class = ref($proto) || $proto;

    my $self  = {
    };

    bless ($self, $class);

    $self->{'canvas'} = $args{canvas} if (exists $args{canvas});
    $self->{'file'} = $args{file} if (exists $args{file});
    $self->{'autosave'} = $args{autosave} if (exists $args{autosave});

    if ($self->file && -r $self->file) {
	$self = $self->read_register( );
	bless ($self, $class);
    }


    return $self;
}

sub show_verts {
    my $self = shift;

#    my @e = $self->edges;
#    while (@e) {
#	my ($u, $v) =  (shift @e, shift @e);
    #
#	my $id = $self->get_attribute("id", $u, $v);
    #
#	my $x1 = $self->get_attribute("x", $u);
#	my $y1 = $self->get_attribute("y", $u);
    #
#	my $x2 = $self->get_attribute("x", $v);
#	my $y2 = $self->get_attribute("y", $v);
    #
#	$self->canvas->coords($id,
#	    $x1, $y1, 
#	    $x2, $y2,
#	    );
#    }

    for (my $i = 0 ; $i < @{$self->{interfaces}} ; $i++) {
	$self->make_tk_node($i);

	my $id = $self->{interfaces}->[$i]->{"id"};
	my $nx = $self->{interfaces}->[$i]->{"x"};
	my $ny = $self->{interfaces}->[$i]->{"y"};
	my $size=$self->{interfaces}->[$i]->{"size"};

	$self->canvas->coords($id,
	    $nx-($size/2), $ny-($size/2),
	    $nx+($size/2), $ny+($size/2),
	    );
    }


}

sub circular_map {
    my $self = shift;
    $self->circular_map_verts;
    $self->dump_us();
#    $self->map_edges;
}
sub random_map {
    my $self = shift;
    $self->random_map_verts;
#    $self->map_edges;
}

sub circular_map_verts {
    my $self = shift;

    my $gamma= 2* 3.14159 / (@{$self->{interfaces}});
    my $rayon = 100; 

    for (my $i = 0 ; $i < @{$self->{interfaces}} ; $i++) {
	$self->make_tk_node($i);
	
	my $x = $rayon *cos($gamma * $i) + $rayon*2;
	my $y = $rayon *sin($gamma * $i) + $rayon*2;

	$self->{interfaces}->[$i]->{"x"} = $x;
	$self->{interfaces}->[$i]->{"y"} = $y;
    }
}

sub random_map_verts {
    my $self = shift;

    my $x;
    my $y;

    my $height = $self->canvas->cget(-height) ;
    my $width = $self->canvas->cget(-width) ;
    for (my $i = 0 ; $i < @{$self->{interfaces}} ; $i++) {
	$self->make_tk_node($i);

	my $minx = $self->{interfaces}->[$i]->{"size"} / 2;
	my $miny = $self->{interfaces}->[$i]->{"size"} / 2;
	my $maxx = $width -$minx;
	my $maxy = $height -$miny;

	$x = rand ($maxx-$minx) + $minx;
	$y = rand ($maxy-$miny) + $miny;

	$self->{interfaces}->[$i]->{"x"} = $x;
	$self->{interfaces}->[$i]->{"y"} = $y;
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
    my $index = shift;

    return 1 if (exists $self->{interfaces}->[$index]->{id});

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


    $self->{interfaces}->[$index]->{"id"} =$id;
    $self->{interfaces}->[$index]->{"balloonid"} = $b;
    $self->{interfaces}->[$index]->{"x"} = $x;
    $self->{interfaces}->[$index]->{"y"} = $y;
    $self->{interfaces}->[$index]->{"size"} = $size;
    $self->{interfaces}->[$index]->{"center"} = $center;
    $self->{interfaces}->[$index]->{"color"} =$color;
}


 sub AUTOLOAD {
     my $self = shift;
     my $attr = $AUTOLOAD;
     $attr =~ s/.*:://;
     return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
     warn "invalid attribute method: ->$attr()" unless $ok_field{$attr};
     $self->{lc $attr} = shift if @_;
     return $self->{lc $attr};
}
1;
