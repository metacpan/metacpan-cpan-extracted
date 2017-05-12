
package PDLA::Graphics::TriD::Surface;

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
	my($nvertices,$nfaces,$nvertpface) = @_;
	my $this = {
		NVertices => $nvertices,
		NFaces    => $nfaces,
		NVPF	  => $nvertpface,
		Vertices  => zeroes(3,$nvertices),
		Faces     => -1*ones($nvertices,$nvertpface)
	};
}

# XXX Refit to use
sub new_pdl2d {
	my($pdl,%opts) = @_;
	defined($opts{X}) or $opts{X} = xvals zeroes $pdl->getdim(0);
	defined($opts{Y}) or $opts{Y} = xvals zeroes $pdl->getdim(1);
}

# Make normals as with no shared vertices.
# 1 normal / face.
sub normals_flat {
}

# Make normals as with round objects
# 1 normal / vertice
sub normals_smooth {
}

sub togl {
}


1;
