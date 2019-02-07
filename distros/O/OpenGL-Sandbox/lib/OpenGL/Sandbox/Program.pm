package OpenGL::Sandbox::Program;
use Moo;
use Carp;
use Try::Tiny;
use Log::Any '$log';
use OpenGL::Sandbox::MMap;
use OpenGL::Sandbox qw(
	warn_gl_errors
	glCreateProgram glDeleteProgram glAttachShader glDetachShader glLinkProgram glUseProgram 
	get_program_uniforms glGetAttribLocation_c
	GL_LINK_STATUS GL_FALSE GL_TRUE GL_CURRENT_PROGRAM GL_ACTIVE_UNIFORMS
);
BEGIN {
	try {
		OpenGL::Sandbox->import(qw( glGetIntegerv_p glGetProgramInfoLog_p glGetProgramiv_p ));
	}
	catch {
		try {
			require OpenGL::Modern::Helpers;
			OpenGL::Modern::Helpers->import(qw( glGetIntegerv_p glGetProgramInfoLog_p glGetProgramiv_p ));
		}
		catch {
			croak "Your OpenGL does not support version-4 shaders: ".$_;;
		};
	};
}

# ABSTRACT: Wrapper object for OpenGL shader program pipeline
our $VERSION = '0.100'; # VERSION


has name       => ( is => 'rw' );
has id         => ( is => 'lazy', predicate => 1 );
has shaders    => ( is => 'rw', default => sub { +{} } );
sub shader_list { values %{ shift->shaders } }

sub _build_id {
	my $self= shift;
	warn_gl_errors;
	my $id= glCreateProgram();
	$id && !warn_gl_errors or croak "glCreateProgram failed";
	my $log= glGetProgramInfoLog_p($id);
	warn "Shader Program ".$self->name.": ".$log
		if $log;
	$id;
}

has prepared   => ( is => 'rw' );
has uniforms   => ( is => 'lazy', predicate => 1, clearer => 1 );

sub _build_uniforms {
	get_program_uniforms(shift->id);
}

has _attribute_cache => ( is => 'rw', default => sub { +{} } );


sub bind {
	my $self= shift;
	$self->prepare unless $self->prepared;
	glUseProgram($self->id);
	return $self;
}


sub prepare {
	my $self= shift;
	return if $self->prepared;
	my $id= $self->id;
	warn_gl_errors;
	for ($self->shader_list) {
		$_->prepare;
		$log->debug("Attach shader $_") if $log->is_debug;
		glAttachShader($id, $_->id);
		!warn_gl_errors
			or croak "glAttachShader failed: ".glGetProgramInfoLog_p($id);
	}
	$log->debug("Link program ".$self->name) if $log->is_debug;
    glLinkProgram($id);
	!warn_gl_errors and glGetProgramiv_p($id, GL_LINK_STATUS) == GL_TRUE
		or croak "glLinkProgram failed: ".glGetProgramInfoLog_p($id);
	$self->prepared(1);
	return $self;
}

sub unprepare {
	my $self= shift;
	return unless $self->has_id && $self->prepared;
	glUseProgram(0) if glGetIntegerv_p(GL_CURRENT_PROGRAM, 1) == $self->id;
	$_->has_id && glDetachShader($self->id, $_->id) for $self->shader_list;
	$self->clear_uniforms;
	$self->prepared(0);
	return $self;
}


sub attr_by_name {
	my ($self, $name)= @_;
	$self->_attribute_cache->{$name} //= do {
		my $loc= glGetAttribLocation_c($self->id, $name);
		$loc >= 0? $loc : undef;
	};
}

sub uniform_location {
	my ($self, $name)= @_;
	($self->uniforms->{$name} // [])->[1];
}

sub set_uniform {
	my $self= shift;
	OpenGL::Sandbox::set_uniform($self->id, $self->uniforms, @_);
	$self;
}
*set= *set_uniform;

sub DESTROY {
	my $self= shift;
	if ($self->has_id) {
		$self->unprepare;
		glDeleteProgram(delete $self->{id});
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::Program - Wrapper object for OpenGL shader program pipeline

=head1 VERSION

version 0.100

=head1 DESCRIPTION

OpenGL shaders get combined into a pipeline.  In older versions of OpenGL, there was only one
program composed of a vertex shader and fragment shader, and attaching one of those shaders was
a global change.  In newer OpenGL, you may assemble multiple program pipelines and switch
between them.

This class tries to support both APIs, by holding a set of shaders which you can then "bind".
On newer OpenGL, this calls C<glUseProgram>.  On older OpenGL, this changes the global vertex
and fragment shaders to the ones referenced by this object.

=head1 ATTRIBUTES

=head2 name

Human-readable name of this program (not GL's integer "name")

=head2 prepared

Boolean; whether the program is ready to run.  This is always 'true' for older global-program
OpenGL.

=head2 shaders

A hashref of shaders, each of which will be attached to the program when it is activated.
The keys of the hashref are up to you, and simply to help diagnostics or merging shader
configurations together with defaults.

=head2 shader_list

A convenient accessor for listing out the values of the L</shader> hash.

=head2 id

The OpenGL integer 'name' of this program.  On older OpenGL with the global program, this will
always be C<undef>.  On newer OpenGL, this should always return a value because accessing it
will call C<glCreateProgram>.

=over

=item has_id

True if the id attribute has been lazy-loaded already.

=back

=head2 uniforms

Lazy-built hashref listing all uniforms of the compiled program.

=over

=item has_uniforms

Whether this has been lazy-built yet

=item clear_uniforms

Remove the cache, to be rebuilt on next use

=back

=head1 METHODS

=head2 bind

  $program->bind;

Begin using this program as the active GL pipeline.

Returns C<$self> for convenient chaining.

=head2 prepare

For relevant implementations, this attaches the shaders and links the program.
If it fails, this throws an exception.  For OpenGL 4 implementation, this only happens
once, and any changes to L</shaders> afterward are ignored.  Use L</unprepare> to remove
the compiled state and be able to rearrange the shaders.

Returns C<$self> for convenient chaining.

=head2 unprepare

Release resources allocated by L</prepare>.

=head2 attr_by_name

Return the attribute ID of the given name, for the prepared program.

=head2 uniform_location

Return the uniform ID of the given name, for the prepared program.

=head2 set_uniform

  $prog->set_uniform( $name, \@values );
  $prog->set_uniform( $name, $opengl_array );

Set the value of a uniform.  This attempts to guess at the size/geometry of the uniform based
on the number or type of values given.

=head2 set

Alias for C<set_uniform>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
