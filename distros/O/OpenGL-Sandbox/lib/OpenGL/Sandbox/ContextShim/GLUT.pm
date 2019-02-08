package OpenGL::Sandbox::ContextShim::GLUT;
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';
use OpenGL qw/ glutInit glutInitWindowSize glutInitWindowPosition glutInitDisplayMode
  glutCreateWindow glutDisplayFunc glutMainLoopEvent glutDestroyWindow glutSwapBuffers
  glutFullScreen
  GLUT_RGBA GLUT_DOUBLE GLUT_DEPTH /;
use OpenGL::Sandbox qw/ glGetString GL_VERSION /;

# ABSTRACT: Create OpenGL context with OpenGL's GLUT support
our $VERSION = '0.120'; # VERSION

# would use Moo, but I want to write my own constructor rather than store
# all these arguments as official attributes.
our $glut_init;
our %instances;
sub new {
	my $class= shift;
	my %opts= ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	my $self= bless {}, $class;
	
	unless ($glut_init) {
		glutInit();
		$glut_init++;
	}
	glutInitWindowPosition($opts{x}//0, $opts{y}//0) if $opts{x} || $opts{y};
	glutInitWindowSize($opts{width}//640, $opts{height}//480);
	glutInitDisplayMode(GLUT_RGBA|GLUT_DOUBLE|GLUT_DEPTH);
	$self->{window}= glutCreateWindow($opts{title}//'OpenGL');
	glutFullScreen() if $opts{fullscreen};

	# GLUT is an ugly API that wants to steal the main loop for itself.
	# This is a hacky workaround...
	weaken(my $weakself= $self);
	glutDisplayFunc(sub {}); # $weakself && ++$weakself->{_ready_to_draw} });
	glutMainLoopEvent();# while (!$self->{_ready_to_draw});

	weaken($instances{$self}= $self);
	return $self;
}

sub DESTROY {
	my $self= shift;
	glutDestroyWindow(delete $self->{window}) if defined $self->{window};
	delete $instances{$self};
}

END {
	for (values %instances) {
		glutDestroyWindow(delete $_->{window}) if defined $_->{window};
	}
}

sub window { shift->{window} }

sub context_info {
	my $self= shift;
	sprintf("Perl OpenGL (GLUT) %s, OpenGL version %s\n",
		OpenGL->VERSION, glGetString(GL_VERSION));
}

sub swap_buffers {
	my $self= shift;
	if ($self->window) {
		glutSwapBuffers();
		glutMainLoopEvent();
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ContextShim::GLUT - Create OpenGL context with OpenGL's GLUT support

=head1 VERSION

version 0.120

=head1 DESCRIPTION

This class is loaded automatically if needed by L<OpenGL::Sandbox/make_context>.
It uses L<OpenGL>'s GLUT support to create an OpenGL context, but it bends the
GLUT API in ways the authors didn't intend (to not steal the main loop)
so it might not work correctly.

=head1 ATTRIBUTES

=head2 window

The GLUT window handle

=head1 METHODS

=head2 Standard ContextShim API:

=over 14

=item new

Accepting all the options of L<OpenGL::Sandbox/make_context>

=item context_info

=item swap_buffers

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
