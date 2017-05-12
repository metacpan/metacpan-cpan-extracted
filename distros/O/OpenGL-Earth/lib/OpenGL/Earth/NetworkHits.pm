package OpenGL::Earth::NetworkHits;

use strict;
use warnings;
use OpenGL;
use OpenGL::Earth::Coords;

our @NETWORK_HITS;

sub display {
	my ($hits) = \@NETWORK_HITS;

	push @{ $hits }, generate_random();

	for my $s (@{ $hits }) {
		spike($s->[0], $s->[1], $s->[2], 1.5);
		$s->[2]--;
	}

    @{ $hits } = grep { $_->[2] > 0 } @{ $hits };

	return;
}

sub generate_random {

	my $lon = rand(360) - 180;
	my $lat = rand(180) - 90;
	my $amplitude = int rand(50) + 50;

	return [ $lat, $lon, $amplitude ];
}

sub spike {
	my ($lat, $long, $amount, $radius) = @_;

	# Apply texture offset
	$long -= 90;

	my ($x1, $y1, $z1) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long, $radius + $amount/200);
	my ($x2, $y2, $z2) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long + 0.4, $radius);
	my ($x3, $y3, $z3) = OpenGL::Earth::Coords::earth_to_xyz($lat, $long - 0.4, $radius);

	glBegin(GL_TRIANGLES);
		glColor3f(1.0, 0.3, 0.3);
		glVertex3f($x1, $y1, $z1);
		glVertex3f($x2, $y2, $z2);
		glVertex3f($x3, $y3, $z3);
	glEnd();

	#glLineWidth(1);
	#glBegin(GL_LINES);
	#    glColor4f(1.0, 0.2, 0.2, 0.6);
	#    glVertex3f(0, 0, 0);
	#    glVertex3f($x1, $y1, $z1);
	#glEnd();

	return;
}

1;

