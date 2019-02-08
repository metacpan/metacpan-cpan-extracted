package OpenGL::Sandbox::ContextShim::GLFW;
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';
use OpenGL::GLFW qw/ glfwInit glfwGetVersionString glfwTerminate NULL GLFW_TRUE GLFW_FALSE
	glfwGetPrimaryMonitor glfwCreateWindow glfwMakeContextCurrent glfwDestroyWindow
	glfwSwapInterval glfwSwapBuffers glfwPollEvents
	glfwWindowHint GLFW_VISIBLE GLFW_DECORATED GLFW_MAXIMIZED GLFW_DOUBLEBUFFER
	/;
use OpenGL::Sandbox qw/ glGetString GL_VERSION /;

# ABSTRACT: Create OpenGL context with OpenGL::GLFW
our $VERSION = '0.120'; # VERSION

# would use Moo, but I want to write my own constructor rather than store
# all these arguments as official attributes.
our $glfw_init;
our %instances;
sub new {
	my $class= shift;
	my %opts= ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	($glfw_init //= glfwInit)
		or croak "GLFW Initialization Failed";
	my $self= bless {}, $class;
	
	glfwWindowHint(GLFW_VISIBLE, ($opts{visible} // 1)? GLFW_TRUE : GLFW_FALSE);
	glfwWindowHint(GLFW_DECORATED, $opts{noframe}? GLFW_FALSE : GLFW_TRUE);
	#glfwWindowHint(GLFW_MAXIMIZED, $opts{fullscreen}? GLFW_TRUE : GLFW_FALSE);
	
	my $w= glfwCreateWindow(
		$opts{width} // 640, # width
		$opts{height} // 480, # height
		$opts{title} // 'OpenGL', # title
		$opts{fullscreen}? glfwGetPrimaryMonitor() : NULL, # monitor
		NULL # share_window
	) or croak "glfwCreateWindow failed";
	$self->{window}= $w;
	
	glfwSetWindowPos($w, $opts{x}//0, $opts{y}//0)
		if $opts{x} || $opts{y};
	
	glfwMakeContextCurrent($w);
	glfwSwapInterval(1) if $opts{vsync} // 1;
	
	weaken($instances{$self}= $self);
	return $self;
}

sub DESTROY {
	my $self= shift;
	glfwDestroyWindow(delete $self->{window}) if defined $self->{window};
	delete $instances{$self};
}

END {
	for (values %instances) {
		glfwDestroyWindow(delete $_->{window}) if defined $_->{window};
	}
	glfwTerminate if $glfw_init;
}

sub window { shift->{window} }

sub context_info {
	my $self= shift;
	sprintf("OpenGL::GLFW %s, glfw version %s, OpenGL version %s\n",
		OpenGL::GLFW->VERSION, glfwGetVersionString(), glGetString(GL_VERSION));
}

sub swap_buffers {
	my $self= shift;
	if ($self->window) {
		glfwSwapBuffers($self->window);
		glfwPollEvents;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ContextShim::GLFW - Create OpenGL context with OpenGL::GLFW

=head1 VERSION

version 0.120

=head1 DESCRIPTION

This class is loaded automatically if needed by L<OpenGL::Sandbox/make_context>.
It uses L<OpenGL::GLFW> to create an OpenGL context.

=head1 ATTRIBUTES

=head2 window

The GLFW window handle

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
