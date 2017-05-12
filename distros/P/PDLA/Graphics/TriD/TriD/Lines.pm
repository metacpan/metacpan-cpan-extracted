
package PDLA::Graphics::TriD::LinesFOOOLD;
@ISA=qw/PDLA::Graphics::TriD::Object/;

BEGIN {
   use PDLA::Config;
   if ( $PDLA::Config{USE_POGL} ) {
      eval "use OpenGL $PDLA::Config{POGL_VERSION} qw(:all)";
      eval 'use PDLA::Graphics::OpenGL::Perl::OpenGL';
   } else {
      eval 'use PDLA::Graphics::OpenGL';
   }
}

use PDLA::Lite;

sub new {
	my($type,$x,$y,$z,$color) = @_;
	my @xdims = $x->dims;
	$color = PDLA->pdl(1) if !defined $color;
	my $this = {
		X => $x, Y => $y, Z => $z,
		Color => $color,
	};
	bless $this,$type;
}

sub get_boundingbox {
	my ($this) = @_;
	my (@mins,@maxs);
	for (X,Y,Z) {
		push @mins, $this->{$_}->min();
		push @maxs, $this->{$_}->max();
	}
	print "LineBound: ",(join ',',@mins,@maxs),"\n";
	return PDLA::Graphics::TriD::BoundingBox->new( @mins,@maxs );
}

# XXX Color is ignored.
sub togl {
	my($this) = @_;
	glDisable(GL_LIGHTING);
	glBegin(&GL_LINE_STRIP);
	my $first = 1;
	PDLA::threadover_n($this->{X},$this->{Y},$this->{Z},$this->{Color},sub {
		if(shift > 0) {
			if(!$first) {
			glEnd();
			glBegin(&GL_LINE_STRIP);
			} else {$first = 0;}
		}
		my $color = pop @_;
		glColor3f($color,0,1-$color);
		glVertex3d(@_);
#		print "VERTEX: ",(join ",",@_),"\n";
	}) ;
	glEnd();
	glEnable(GL_LIGHTING);
}

1;
