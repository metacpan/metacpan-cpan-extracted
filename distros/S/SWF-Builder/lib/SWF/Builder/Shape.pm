package SWF::Builder::Shape;

use strict;
use Carp;
use SWF::Element;
use SWF::Builder::ExElement;

our $VERSION="0.02";

####

@SWF::Builder::Shape::ISA = ('SWF::Builder::Shape::ExDraw');

sub new {
    my $class = shift;
    
    my $self = bless {
	_current_line_width => 1,
	_current_X => 0,
	_current_Y => 0,
	_prev_X    => 0,
	_prev_Y    => 0,
	_start_X   => 0,
	_start_Y   => 0,
	_pos_stack => [],
	_current_font => undef,
	_current_size => 12,
	_edges => SWF::Element::SHAPE->ShapeRecords->new,
	_bounds => SWF::Builder::ExElement::BoundaryRect->new,
    }, $class;
    
    $self->_init;
    $self->moveto(0,0);
}

sub _init {}

sub _set_bounds {
    my ($self, $x, $y) = @_;
    my $cw = $self->{_current_line_width} * 10;
    
    $self->{_bounds}->set_boundary($x-$cw, $y-$cw, $x+$cw, $y+$cw);
}

sub _get_stylerecord {
    my $self = shift;
    my $edges = $self->{_edges};
    my $r;
    if (ref($edges->[-1])=~/STYLECHANGERECORD$/) {
	$r = $edges->[-1];
    } else {
	$r = $edges->new_element;
	push @$edges, $r;
    }
    return $r;
}

sub get_bbox {
    return map{$_/20} @{shift->{_bounds}};
}

#### drawing elements ####
# handling _edges directly.
# based on TWIPS.

sub _set_style {
    my ($self, %param) = @_;
    my $r = $self->_get_stylerecord;
    
    for my $p (qw/ MoveDeltaX MoveDeltaY FillStyle0 FillStyle1 LineStyle /) {
	$r->$p($param{$p}) if exists $param{$p};
    }
    return $r;
}

sub _r_lineto_twips {
    my $self = shift;
    my $edges = $self->{_edges};    
    
    while (my($dx, $dy) = splice(@_, 0, 2)) {
	$dx = _round($dx);
	$dy = _round($dy);
	if ($dx or $dy) {
	    $self->{_prev_X} = $self->{_current_X};
	    $self->{_prev_Y} = $self->{_current_Y};
	    push @$edges, $edges->new_element( DeltaX => $dx, DeltaY => $dy );
	    $dx = ($self->{_current_X} += $dx);
	    $dy = ($self->{_current_Y} += $dy);
	    $self->_set_bounds($dx, $dy);
	}
    }
    $self;
}

sub _lineto_twips {
    my $self = shift;
    my $edges = $self->{_edges};    
    
    while (my($x, $y) = splice(@_, 0, 2)) {
	$x = _round($x);
	$y = _round($y);
	my $dx = $x-$self->{_current_X};
	my $dy = $y-$self->{_current_Y};
	if ($dx or $dy) {
	    $self->{_prev_X} = $self->{_current_X};
	    $self->{_prev_Y} = $self->{_current_Y};
	    push @$edges, $edges->new_element( DeltaX => $dx, DeltaY => $dy );
	    $self->{_current_X} = $x;
	    $self->{_current_Y} = $y;
	    $self->_set_bounds($x, $y);
	}
    }
    $self;
}

sub _r_curveto_twips {
    my $self = shift;
    my $edges = $self->{_edges};    
    
    while(my($cdx, $cdy, $adx, $ady) = splice(@_, 0, 4)) {
	my $curx = $self->{_current_X};
	my $cury = $self->{_current_Y};
	$cdx = _round($cdx);
	$cdy = _round($cdy);
	$adx = _round($adx);
	$ady = _round($ady);
	if ($cdx == 0 and $cdy == 0) {
	    if ($adx != 0 or $ady != 0) {
		push @$edges, $edges->new_element( DeltaX => $adx, DeltaY => $ady);
	    } else {
		next;
	    }
	} elsif ($adx == 0 and $ady == 0) {
	    push @$edges, $edges->new_element( DeltaX => $cdx, DeltaY => $cdy);
	} else {
	    push @$edges, $edges->new_element
		(
		 ControlDeltaX => $cdx,
		 ControlDeltaY => $cdy,
		 AnchorDeltaX  => $adx,
		 AnchorDeltaY  => $ady,
		 );
	}
	if ($adx or $ady) {
	    $self->{_prev_X} = $curx + $cdx;
	    $self->{_prev_Y} = $cury + $cdy;
	} else {
	    $self->{_prev_X} = $curx;
	    $self->{_prev_Y} = $cury;
	}
	$adx = $self->{_current_X} = $curx + $cdx + $adx;
	$ady = $self->{_current_Y} = $cury + $cdy + $ady;
	$self->_set_bounds($adx, $ady);
	$self->_set_bounds($curx+$cdx, $cury+$cdy, 1); # 1: off curve
    }
    $self;
}

sub _curveto_twips {
    my $self = shift;
    my $edges = $self->{_edges};    
    
    while(my ($cx, $cy, $ax, $ay) = splice(@_, 0, 4)) {
	my $curx = $self->{_current_X};
	my $cury = $self->{_current_Y};
	$cx = _round($cx);
	$cy = _round($cy);
	$ax = _round($ax);
	$ay = _round($ay);
	my $cdx = $cx-$curx;
	my $cdy = $cy-$cury;
	my $adx = $ax-$cx;
	my $ady = $ay-$cy;
	if ($cdx == 0 and $cdy == 0) {
	    if ($adx != 0 or $ady != 0) {
		push @$edges, $edges->new_element( DeltaX => $adx, DeltaY => $ady);
	    } else {
		next;
	    }
	} elsif ($adx == 0 and $ady == 0) {
	    push @$edges, $edges->new_element( DeltaX => $cdx, DeltaY => $cdy);
	} else {
	    push @$edges, $edges->new_element
		(
		 ControlDeltaX => $cdx,
		 ControlDeltaY => $cdy,
		 AnchorDeltaX  => $adx,
		 AnchorDeltaY  => $ady,
		 );
	}
	if ($adx or $ady) {
	    $self->{_prev_X} = $cx;
	    $self->{_prev_Y} = $cy;
	} else {
	    $self->{_prev_X} = $curx;
	    $self->{_prev_Y} = $cury;
	}
	$self->{_current_X} = $ax;
	$self->{_current_Y} = $ay;
	$self->_set_bounds($ax, $ay);
	$self->_set_bounds($cx, $cy, 1);  # 1: off curve
    }
    $self;
}

sub _null_edge {
    my $self = shift;

    push @{$self->{_edges}}, $self->{_edges}->new_element( DeltaX => 0, DeltaY => 0 );
    $self;
}

sub _r_moveto_twips {
    my ($self, $dx, $dy)=@_;
    
    $dx = _round($dx);
    $dy = _round($dy);
    $dx = $self->{_current_X} + $dx;
    $dy = $self->{_current_Y} + $dy;
    $self->_set_style(MoveDeltaX => $dx, MoveDeltaY => $dy);
    $self->{_start_X} = $self->{_prev_X} = $self->{_current_X} = $dx;
    $self->{_start_Y} = $self->{_prev_Y} = $self->{_current_Y} = $dy;
    $self->_set_bounds($dx, $dy);
    $self;
}

sub _moveto_twips {
    my ($self, $x, $y)=@_;
    
    $x = _round($x);
    $y = _round($y);
    $self->_set_style(MoveDeltaX => $x, MoveDeltaY => $y);
    $self->{_start_X} = $self->{_prev_X} = $self->{_current_X} = $x;
    $self->{_start_Y} = $self->{_prev_Y} = $self->{_current_Y} = $y;
    $self->_set_bounds($x, $y);
    $self;
}

sub _current_font {
    my ($self, $font) = @_;

    $self->{_current_font} = $font if defined $font;
    $self->{_current_font};
}

sub _current_size {
    my ($self, $size) = @_;

    $self->{_current_size} = $size if defined $size;
    $self->{_current_size};
}

sub _current_angle {
    my $self = shift;

    return atan2($self->{_current_Y} - $self->{_prev_Y}, $self->{_current_X} - $self->{_prev_X});
}


sub push_pos {
    my $self = shift;
    push @{$self->{_pos_stack}}, [$self->{_current_X}, $self->{_current_Y}];
    $self;
}

sub pop_pos {
    my $self = shift;
    $self->_moveto_twips( @{pop @{$self->{_pos_stack}}} );
    $self;
}

sub lineto_pop_pos {
    my $self = shift;
    $self->_lineto_twips( @{pop @{$self->{_pos_stack}}} );
    $self;
}

sub close_path {
    my $self = shift;

    $self->_lineto_twips( $self->{_start_X}, $self->{_start_Y} );
}

####

package SWF::Builder::Shape::ExDraw;

use warnings::register;

# based on pixels (20TWIPS).

sub get_pos {
    my $self = shift;
    return ($self->{_current_X}/20, $self->{_current_Y}/20);
}

#### basic drawing ####
# using SWF::Builder::Shape::_*_twips

sub r_lineto {
    my $self = shift;

  Carp::croak "Invalid count of coordinates" if @_ % 2;
    $self->_r_lineto_twips(map $_*20, @_);
}

sub lineto {
    my $self = shift;
    
  Carp::croak "Invalid count of coordinates" if @_ % 2;
    $self->_lineto_twips(map $_*20, @_);
}

sub r_curveto {
    my $self = shift;
    
  Carp::croak "Invalid count of coordinates" if @_ % 4;
    $self->_r_curveto_twips(map $_*20, @_);
}

sub curveto {
    my $self = shift;
    
  Carp::croak "Invalid count of coordinates" if @_ % 4;
    $self->_curveto_twips(map $_*20, @_);
}

sub moveto {
    my ($self, $x, $y)=@_;

    $self->_moveto_twips($x*20, $y*20);
}

sub r_moveto {
    my ($self, $dx, $dy)=@_;

    $self->_r_moveto_twips($dx*20, $dy*20);
}

my %style = ('none' => 0, 'fill' => 1, 'draw' => 1);
sub fillstyle {
    my ($self, $f) = @_;
    my $index;
    if (exists $style{$f}) {
	$index = $style{$f};
    } else {
	$index = $f;
    }
    $self->_set_style(FillStyle0 => $index);
    $self;
}
*fillstyle0 = \&fillstyle;

sub fillstyle1 {
    my ($self, $f) = @_;
    my $index;
    if (exists $style{$f}) {
	$index = $style{$f};
    } else {
	$index = $f;
    }
    $self->_set_style(FillStyle1 => $index);
    $self;
}

sub linestyle {
    my ($self, $f) = @_;
    my $index;
    if (exists $style{$f}) {
	$index = $style{$f};
    } else {
	$index = $f;
    }
    $self->_set_style(LineStyle => $index);
    $self;
}

sub font {
    my ($self, $font) = @_;
    
    Carp::croak "Invalid font" unless UNIVERSAL::isa($font, 'SWF::Builder::Character::Font') and $font->embed;
    $self->_current_font($font);
    $self;
}

sub size {
    my $self = shift;
    $self->_current_size(shift);
    $self;
}

sub text {
    my ($self, $font, $text) = @_;
    
    unless (defined $text) {
	$text = $font;
	$font = $self->_current_font;
    }
    Carp::croak "Invalid font" unless UNIVERSAL::isa($font, 'SWF::Builder::Character::Font') and eval{$font->embed};

    for my $c (split //, $text) {
	my $gshape = $self->transform( [scale => $self->_current_size / 51.2, translate => [$self->get_pos]] );
	my $adv = $font->_draw_glyph($c, $gshape);
	$gshape->moveto($adv, 0);
    }
    $self;
}

### extension drawing ###
# no-use _*_twips. using basic drawing.

use constant PI => 2*atan2(1,0);

sub box {
    my ($self, $x1, $y1, $x2, $y2) = @_;

    $self->moveto($x1,$y1)
	->lineto($x2, $y1)
	    ->lineto($x2,$y2)
		->lineto($x1, $y2)
		    ->lineto($x1, $y1);
}

sub rect {
    my ($self, $w, $h, $rx, $ry) = @_;

    unless (defined $rx) {
	$self->r_lineto($w,0)
	    ->r_lineto(0,$h)
	    ->r_lineto(-$w,0)
	    ->r_lineto(0,-$h);
    } else {
	$ry = $rx unless defined $ry;
	my $rcx = 0.414213562373095 * $rx;
	my $rcy = 0.414213562373095 * $ry;
	my $rax = 0.292893218813453 * $rx;
	my $ray = 0.292893218813453 * $ry;
	$w -= $rx+$rx;
	$h -= $ry+$ry;
	$self->r_moveto($rx, 0)
	    ->r_lineto($w,0)
	    ->r_curveto($rcx, 0, $rax, $ray, $rax, $ray, 0, $rcy)
	    ->r_lineto(0,$h)
	    ->r_curveto(0, $rcy, -$rax, $ray, -$rax, $ray, -$rcx, 0)
	    ->r_lineto(-$w,0)
	    ->r_curveto(-$rcx, 0, -$rax, -$ray, -$rax, -$ray, 0, -$rcy)
	    ->r_lineto(0,-$h)
	    ->r_curveto(0, -$rcy, $rax, -$ray, $rax, -$ray, $rcx, 0)
	    ->r_moveto(-$rx, 0);
    }
}

sub curve3to {
    require Math::Bezier::Convert;
    
    my $self = shift;
    my @p = Math::Bezier::Convert::cubic_to_quadratic($self->get_pos, @_);
    shift @p;
    shift @p;
    $self->curveto(@p);
}

sub r_curve3to {
    require Math::Bezier::Convert;

    my $self = shift;
    my @p;
    my ($cx, $cy) = $self->get_pos;

    push @p, $cx, $cy;
    while(my ($x, $y) = splice(@_, 0, 2)) {
	$cx += $x;
	$cy += $y;
	push @p, $cx, $cy;
    }
    @p = Math::Bezier::Convert::cubic_to_quadratic(@p);
    shift @p;
    shift @p;
    $self->curveto(@p);
}

sub circle {
    my ($self, $r) = @_;

    my $rc = 0.414213562373095 * $r;  # 
    my $ra = 0.292893218813453 * $r;
    $self->r_moveto(0, -$r)
	->r_curveto($rc, 0, $ra, $ra, $ra, $ra, 0, $rc, 0, $rc, -$ra, $ra, -$ra, $ra, -$rc, 0, -$rc, 0, -$ra, -$ra, -$ra, -$ra, 0, -$rc, 0, -$rc, $ra, -$ra, $ra, -$ra, $rc, 0)
	->r_moveto(0, $r);
}

sub ellipse {
    my ($self, $rx, $ry, $rot) = @_;

    $self->transform( [scale => [1, $ry/$rx], rotate => ($rot||0)] )
	     ->circle($rx)
	 ->end_transform;
}

sub transform {
    my ($self, $matrix, $sub) = @_;

    unless (UNIVERSAL::isa($matrix, 'SWF::Builder::ExElement::MATRIX')) { 
	$matrix = SWF::Builder::ExElement::MATRIX->new->init($matrix);
    }

    my $t = SWF::Builder::Shape::Transformer->new($self, $matrix);
    if (defined $sub) {
	$sub->($t);
	return $self;
    } else {
	return $t;
    }
}

sub arcto {
    my ($self, $startangle, $centralangle, $rx, $ry, $rot) = @_;

    return $self unless $centralangle and $rx;
    $rot ||= 0;
    $ry ||= $rx;

    my $ca = $centralangle * PI / 180;
    my $sa = $startangle * PI / 180;
    my $ra = $rot * PI / 180;

    if ($rx == $ry) {
	$sa += $ra;
	$self->_arcto_rad($sa, $ca, $rx, $ry);
    } else {
	$sa -= $ra;
	my $sa2 = $sa;

	if (($startangle - $rot) % 90 != 0) {
	    $sa = atan2($rx * sin($sa)/cos($sa), $ry);
	    if ($sa2 > PI/2 or $sa2 < -PI()/2) {
		$sa += PI*int(($sa2+PI*($sa2<=>0)/2)/PI);
	    }
	}

	if (($startangle + $centralangle - $rot) % 90 != 0) {
	    $ca += $sa2;
	    my $ca2 = $ca;
	    $ca = atan2($rx * sin($ca)/cos($ca), $ry);
	    if ($ca2 > PI/2 or $ca2 < -PI()/2) {
		$ca += PI*int(($ca2+PI*($ca2<=>0)/2)/PI);
	    }
	    $ca -= $sa;
	}
	if ($rot) {
	    $self->transform([rotate => $rot])
		->_arcto_rad($sa, $ca, $rx, $ry)
		    ->end_transform;
	} else {
	    $self->_arcto_rad($sa, $ca, $rx, $ry);
	}
    }
}
    
sub _arcto_rad {
    my ($self, $sa, $ca, $rx, $ry) = @_;
    my $c = int(abs($ca) / 0.785398163397448) + 1;
    $ca /= $c;
    my $tan_ca2 = sin($ca/2) / cos($ca/2);
    my $cos_ca1 = cos($ca) - 1;
    my $sin_tan = sin($ca) - $tan_ca2;
    my @p;
    for (;$c > 0; $c--, $sa += $ca) {
	my ($sin, $cos) = (sin($sa), cos($sa));
	push @p, ($rx * -$sin * $tan_ca2, $ry * $cos * $tan_ca2, 
		  $rx * ($cos * $cos_ca1 - $sin * $sin_tan),
		  $ry * ($sin * $cos_ca1 + $cos * $sin_tan));
			 
    }
    $self->r_curveto(@p);
}

sub radial_moveto {
    my ($self, $r, $theta) = @_;

    $theta = $self->_current_angle + $theta * PI / 180;
    $self->r_moveto($r * cos($theta), $r * sin($theta));
}

sub r_radial_moveto {
    my ($self, $r, $theta) = @_;

    $theta = $theta * PI / 180;
    $self->r_moveto($r * cos($theta), $r * sin($theta));
}

sub radial_lineto {
    my $self = shift;
    my @p;
    while ( my ($r, $theta) = splice(@_, 0, 2) ) {
	$theta = $theta * PI / 180;
	push @p, ($r * cos($theta), $r * sin($theta));
    }
    $self->r_lineto(@p);
}

sub r_radial_lineto {
    my $self = shift;
    my @p;
    my $theta = $self->_current_angle;
    while ( my ($r, $dtheta) = splice(@_, 0, 2) ) {
	$theta += $dtheta * PI / 180;
	push @p, ($r * cos($theta), $r * sin($theta));
    }
    $self->r_lineto(@p);
}

sub starshape {
    my ($self, $or, $points, $ir, $screw) = @_;

    $screw ||= 0;
    $points ||= 5;
    unless (defined $ir) {
	$ir = 0.381966011250105 * $or;
    } else {
	$ir = (0.5*$ir)**1.388483827 * $or;
    }

    my $step = 2*PI / $points;
    my $oa = -0.5 * PI;
    my $ia = $oa + 0.5*$step + $screw * PI / 180;
    my ($ox, $oy) = $self->get_pos;

    $self->r_moveto(0, -$or);

    for (1..$points) {
	$oa += $step;
	$self->lineto($ox + $ir * cos($ia), $oy + $ir * sin($ia), $ox + $or * cos($oa), $oy + $or * sin($oa));
	$ia += $step;
    }
    $self->r_moveto(0, $or);
}

{
    my $qrnnum = qr/(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?/o;
    my $qrnum = qr/(-?$qrnnum)/o;
    my $qrwsp = qr/[ \x09\x0d\x0a]/o;
    my $qrdlm = qr/(?:(?:$qrwsp+,?$qrwsp*)|(?:,$qrwsp*))/o;
    my $qrcoord = qr/$qrnum$qrdlm?$qrnum/o;
    my $qrn = qr/\A$qrnum(?:$qrdlm?$qrnum)*\Z/o;
    my $qrc1 = qr/\A$qrcoord(?:$qrdlm?$qrcoord)*\Z/o;
    my $qrc2 = qr/\A$qrcoord$qrdlm?$qrcoord(?:$qrdlm?$qrcoord$qrdlm?$qrcoord)*\Z/o;

    my %qr = 
	( M => $qrc1,
	  Z => qr/\A\Z/o,
	  L => $qrc1,
	  H => $qrn,
	  V => $qrn,
	  C => qr/\A$qrcoord$qrdlm?$qrcoord$qrdlm?$qrcoord(?:$qrdlm?$qrcoord$qrdlm?$qrcoord$qrdlm?$qrcoord)*\Z/o,
	  S => $qrc2,
	  Q => $qrc2,
	  T => $qrc1,
	  A => qr/\A$qrnum$qrdlm?$qrnum$qrdlm?$qrnum$qrdlm$qrnum$qrdlm$qrnum$qrdlm$qrnum$qrdlm?$qrnum(?:$qrdlm?$qrnum$qrdlm?$qrnum$qrdlm?$qrnum$qrdlm$qrnum$qrdlm$qrnum$qrdlm$qrnum$qrdlm?$qrnum)*\Z/o,
	  );

    sub path {
	my ($self, $path) = @_;
	my $pathobj;

	if ($path =~ s/\A$qrwsp*([Mm])([^MmZzLlHhVvCcSsQqTtAa]*)//o) {
	    my ($com, $param) = ($1, $2);
	    $param =~ s/\A$qrwsp+//o;
	    $param =~ s/$qrwsp+\Z//o;
	    $param =~ $qr{M} or Carp::croak "Invalid path command '$com$param'";
	    my @p = grep {defined $_} $param =~/$qrnum/og;
	    if ($com eq 'm') {
		for (my $i = 2; $i <= $#p; $i+=2) {
		    $p[$i] += $p[0];
		    $p[$i+1] += $p[1];
		}
	    }
	    $pathobj = bless {
		shape => $self,
		_subpath_origin => [@p[0,1]],
		_ref_cp => ['M', 0, 1],
		_current_X => $p[0],
		_current_Y => $p[1],
	    }, 'SWF::Builder::Shape::Path';
	    
	    $pathobj->M(@p);
	} else {
	    if (warnings::enabled()) {
	      warnings::warn("Path data should begin with 'm' or 'M'");
	    }
	    my ($x, $y) = $self->get_pos;
	    $pathobj = bless {
		shape => $self,
		_subpath_origin => [$x, $y],
		_ref_cp => ['M', 0, 1],
		_current_X => $x,
		_current_Y => $y,
	    }, 'SWF::Builder::Shape::Path';
	}

	while ($path =~ /([MmZzLlHhVvCcSsQqTtAa])([^MmZzLlHhVvCcSsQqTtAa]*)/g) {
	    my ($com, $param) = ($1, $2);
	    $param =~ s/\A$qrwsp+//o;
	    $param =~ s/$qrwsp+\Z//o;
	    $param =~ $qr{uc($com)} or Carp::croak "Invalid path command '$com$param'";
	    my @p = grep {defined $_} $param =~ /$qrnum/og;
	    $pathobj->$com(@p) if ($com eq lc $com);
	    $com = uc $com;
	    $pathobj->$com(@p);

	    $pathobj->{_current_X} = $p[-2];
	    $pathobj->{_current_Y} = $p[-1];
	    $pathobj->{_ref_cp}[0] = $com;
	}
	$self;
    }


    package SWF::Builder::Shape::Path;

    sub a {
	my $pathobj = shift;
	for (my $i = 5; $i <= $#_; $i+=7) {
	    $_[$i] += $pathobj->{_current_X};
	    $_[$i+1] += $pathobj->{_current_Y};
	}
    }

    sub h {
	my $pathobj = shift;
	for (my $i = 0; $i <= $#_; $i++) {
	    $_[$i] += $pathobj->{_current_X};
	}
    }

    sub v {
	my $pathobj = shift;
	for (my $i = 0; $i <= $#_; $i++) {
	    $_[$i] += $pathobj->{_current_Y};
	}
    }

    sub m {
	my $pathobj = shift;
	for (my $i = 0; $i <= $#_; $i+=2) {
	    $_[$i] += $pathobj->{_current_X};
	    $_[$i+1] += $pathobj->{_current_Y};
	}
    }

    *c = *q = *t = *s = *l = \&m;

    sub z {}

    sub M {
	my ($pathobj, $x, $y, @coords) = @_;
	$pathobj->{shape}->moveto($x, $y);
	@{$pathobj->{_subpath_origin}} = ($x, $y);
	if (@coords) {
	    $pathobj->L(@coords);
	}
    }

    sub Z {
	my $pathobj = shift;
	$pathobj->{shape}->lineto(@{$pathobj->{_subpath_origin}});
    }

    sub L {
	my $pathobj = shift;
	$pathobj->{shape}->lineto(@_);
    }

    sub H {
	my $pathobj = shift;
	my $y = $pathobj->{_current_Y};
	$pathobj->{shape}->lineto(map {($_, $y)} @_);
    }

    sub V {
	my $pathobj = shift;
	my $x = $pathobj->{_current_X};
	$pathobj->{shape}->lineto(map {($x, $_)} @_);
    }

    sub C {
	my $pathobj = shift;
	$pathobj->{_ref_cp}[1] = $_[-2]*2 - $_[-4];
	$pathobj->{_ref_cp}[2] = $_[-1]*2 - $_[-3];
	$pathobj->{shape}->curve3to(@_);
    }
    sub S {
	my $pathobj = shift;
	my @coords;
	
	if ($pathobj->{_ref_cp}[0] =~/[CS]/) {
	    push @coords, $pathobj->{_ref_cp}[1], $pathobj->{_ref_cp}[2];
	} else {
	    push @coords, $pathobj->{_current_X}, $pathobj->{_current_Y};
	}
	my ($dx, $dy);
	while (my ($cx, $cy, $x, $y) = splice(@_, 0, 4)) {
	    $dx = $x-$cx;
	    $dy = $y-$cy;
	    push @coords, $cx, $cy, $x, $y, $x+$dx, $y+$dy;
	}
	$pathobj->{_ref_cp}[2] = pop @coords;
	$pathobj->{_ref_cp}[1] = pop @coords;
	$pathobj->{shape}->curve3to(@coords);
    }

    sub Q {
	my $pathobj = shift;
	$pathobj->{_ref_cp}[1] = $_[-2]*2 - $_[-4];
	$pathobj->{_ref_cp}[2] = $_[-1]*2 - $_[-3];
	$pathobj->{shape}->curveto(@_);
    }

    sub T {
	my $pathobj = shift;
	my @coords;

	if ($pathobj->{_ref_cp}[0] =~/[QT]/) {
	    push @coords, $pathobj->{_ref_cp}[1], $pathobj->{_ref_cp}[2];
	} else {
	    push @coords, $pathobj->{_current_X}, $pathobj->{_current_Y};
	}
	my ($dx, $dy);
	while (my ($x, $y) = splice(@_, 0, 2)) {
	    $dx = $x-$coords[-2];
	    $dy = $y-$coords[-1];
	    push @coords, $x, $y, $x+$dx, $y+$dy;
	}
	$pathobj->{_ref_cp}[2] = pop @coords;
	$pathobj->{_ref_cp}[1] = pop @coords;
	$pathobj->{shape}->curveto(@coords);
    }

    use constant PI => 2*atan2(1,0);

    sub A {
	my $pathobj = shift;
	my $x1 = $pathobj->{_current_X};
	my $y1 = $pathobj->{_current_Y};
	
	while (my ($rx, $ry, $rot, $laf, $swf, $x2, $y2) = splice(@_, 0, 7)) {

	    next if ($x1 == $x2 and $y1 == $y2);

	    if ($rx == 0 or $ry == 0) {
		$pathobj->{shape}->lineto($x2, $y2);
		next;
	    }

	    $rx = abs($rx);
	    $ry = abs($ry);
	    $laf = !!$laf;
	    $swf = !!$swf;

	    my $ra = $rot * PI / 180;
	    my $sin = sin($ra);
	    my $cos = cos($ra);

	    my $dx = ($x1-$x2)/2;
	    my $dy = ($y1-$y2)/2;
	    my $x1p = $cos * $dx + $sin * $dy;
	    my $y1p = -$sin * $dx + $cos * $dy;
	    my ($cxp, $cyp);
	    my $lambda = ($x1p*$x1p)/($rx*$rx) + ($y1p*$y1p)/($ry*$ry);
	    if ($lambda > 1) {
		$rx *= sqrt($lambda);
		$ry *= sqrt($lambda);
		$cxp = $cyp = 0;
	    } else {
		my $k = sqrt(($rx*$rx*$ry*$ry-$rx*$rx*$y1p*$y1p-$ry*$ry*$x1p*$x1p) / ($rx*$rx*$y1p*$y1p+$ry*$ry*$x1p*$x1p));
		$k = -$k if $laf == $swf;
		$cxp = $k * $rx*$y1p/$ry;
		$cyp = $k * -$ry*$x1p/$rx;
	    }
	    my $cx = $cos * $cxp - $sin * $cyp + ($x1 + $x2)/2;
	    my $cy = $sin * $cxp + $cos * $cyp + ($y1 + $y2)/2;
	    my $ux = ($x1p - $cxp) / $rx;
	    my $uy = ($y1p - $cyp) / $ry;
	    my $u = sqrt($ux*$ux+$uy*$uy);
	    my $vx = (-$x1p - $cxp) / $rx;
	    my $vy = (-$y1p - $cyp) / $ry;
	    my $v = sqrt($vx*$vx+$vy*$vy);
	    my $uv1 = $ux / $u;
	    my $theta1 = atan2(sqrt(1-$uv1*$uv1), $uv1);
	    $theta1 = -$theta1 if $uy<0;
	    my $uvd = ($ux*$vx+$uy*$vy)/($u*$v);
	    my $dtheta = atan2(($lambda>1)?0:sqrt(1-$uvd*$uvd), $uvd);
	    $dtheta = -$dtheta if ($ux*$vy - $uy*$vx)<0;
	    if ($swf == 0 and $dtheta > 0) {
		$dtheta -= 2*PI;
	    } elsif ($swf == 1 and $dtheta < 0) {
		$dtheta += 2*PI;
	    }

	    $pathobj->{shape}->transform([rotate => $rot])
		                  ->_arcto_rad($theta1, $dtheta, $rx, $ry)
			     ->end_transform;
	} continue {
	    $x1 = $x2;
	    $y1 = $y2;
	}

    }
}


#####

{
    package SWF::Builder::Shape::Transformer;

    use warnings::register;

    @SWF::Builder::Shape::Transformer::ISA = ('SWF::Builder::Shape::ExDraw');

    sub new {
	my ($class, $shape, $matrix) = @_;

	 my $self = bless {
	    shape => $shape,
	    matrix => $matrix,
	    inv_matrix => undef,
	}, $class;
    }

    sub get_pos {
	my $self = shift;
	my $m = $self->{matrix};
	my $im = $self->{inv_matrix};

	unless (defined $im) {
	    my $a = $m->ScaleX;
	    my $b = $m->RotateSkew0;
	    my $c = $m->RotateSkew1;
	    my $d = $m->ScaleY;
	    my $det = $a*$d - $b*$c;

	    $im = SWF::Element::MATRIX->new;

	    if ($det) {
		$im->ScaleX($d / $det);
		$im->RotateSkew0(-$b / $det);
		$im->RotateSkew1(-$c / $det);
		$im->ScaleY($a / $det);
	    } else {
		if (warnings::enabled()) {
		    warnings::warn("Can't calculate inverse mapping");
		}
		if ($a-$b == 0) {
		    $im->RotateSkew1(0);
		    $im->ScaleX(0);
		    if ($c-$d == 0) {
			$im->RotateSkew0(0);
			$im->ScaleY(0);
		    } else {
			$im->RotateSkew0(1/($c-$d));
			$im->ScaleY(-1/($c-$d));
		    }
		} else {
		    $im->ScaleX(1/($a-$b));
		    $im->RotateSkew0(0);
		    $im->RotateSkew1(-1/($a-$b));
		    $im->ScaleY(0);
		}
	    }
	    $self->{inv_matrix} = $im;
	}
	my ($x, $y) = $self->{shape}->get_pos;
	$x -= $m->TranslateX * 20;  # twips -> pixels
	$y -= $m->TranslateY * 20;
	return ($x * $im->ScaleX + $y * $im->RotateSkew1, $x * $im->RotateSkew0 + $y * $im->ScaleY);
    }

    sub _transform {
	my $self = shift;
	my $sx = $self->{matrix}->ScaleX;
	my $sy = $self->{matrix}->ScaleY;
	my $r0 = $self->{matrix}->RotateSkew0;
	my $r1 = $self->{matrix}->RotateSkew1;
	my $tx = $self->{matrix}->TranslateX||0;
	my $ty = $self->{matrix}->TranslateY||0;
	my @p;

	while (my ($x, $y) = splice(@_, 0, 2)) {
	    push @p, $x * $sx + $y * $r1 + $tx, $x * $r0 + $y * $sy + $ty;
	}
	return @p;
    }

    sub _r_transform {
	my $self = shift;
	my $sx = $self->{matrix}->ScaleX;
	my $sy = $self->{matrix}->ScaleY;
	my $r0 = $self->{matrix}->RotateSkew0;
	my $r1 = $self->{matrix}->RotateSkew1;
	my @p;

	while (my ($x, $y) = splice(@_, 0, 2)) {
	    push @p, $x * $sx + $y * $r1, $x * $r0 + $y * $sy;
	}
	return @p;
    }

    sub end_transform {
	return shift->{shape};
    }

    sub AUTOLOAD {
	our $AUTOLOAD;
	return if $AUTOLOAD =~ /::DESTROY$/;

	my $self = shift;
	if ($AUTOLOAD =~ /::((_r)?[^:]+to_twips)$/) {
	    my $method = $1;
	    if ($2) {
		$self->{shape}->$method($self->_r_transform(@_));
	    } else {
		$self->{shape}->$method($self->_transform(@_));
	    }
	} else {
	    $self->{shape}->$1(@_);
	}
	$self;
    }
}
