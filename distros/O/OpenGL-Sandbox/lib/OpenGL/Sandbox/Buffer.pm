package OpenGL::Sandbox::Buffer;
use Moo;
use Carp;
use Try::Tiny;
use Log::Any '$log';
use OpenGL::Sandbox::MMap;
use OpenGL::Sandbox qw(
	warn_gl_errors gen_buffers delete_buffers load_buffer_data load_buffer_sub_data
	glBindBuffer GL_STATIC_DRAW
);

# ABSTRACT: Wrapper object for OpenGL Buffer Object
our $VERSION = '0.120'; # VERSION


has name       => ( is => 'rw' );
has target     => ( is => 'rw' );
has usage      => ( is => 'rw' );
has id         => ( is => 'lazy', predicate => 1 );
sub _build_id { gen_buffers(1) }

has filename   => ( is => 'rw' );
has autoload   => ( is => 'rw' );
has _mmap      => ( is => 'rw', init_arg => undef );


sub BUILD {
	my ($self, $args)= @_;
	if ($args->{data} && !defined $self->autoload) {
		$self->autoload($args->{data});
	}
	if ($self->filename && !defined $self->autoload) {
		$self->autoload(OpenGL::Sandbox::MMap->new($self->filename));
	}
}


sub bind {
	my ($self, $target)= @_;
	$self->target($target) if defined $target;
	$target //= $self->target // croak "No target specified, and target attribute is not set";
	if (defined $self->autoload) {
		$self->load($self->autoload);
		$self->autoload(undef);
	} else {
		$log->debug('glBindBuffer '.$self->id) if $log->is_debug;
		glBindBuffer($target, $self->id);
	}
	$self;
}


sub load {
	my ($self, $data, $usage)= @_;
	$usage //= $self->usage // GL_STATIC_DRAW;
	$self->usage($usage);
	my $target= $self->target // croak "No target specified for binding buffer";
	$log->debug('glBindBuffer '.$self->id.', load_buffer_data') if $log->is_debug;
	glBindBuffer($target, $self->id);
	load_buffer_data($target, undef, $data, $usage);
	$self;
}

sub load_at {
	my ($self, $offset, $data, $src_offset, $src_length)= @_;
	my $target= $self->target // croak "No target specified for binding buffer";
	glBindBuffer($target, $self->id);
	load_buffer_sub_data($target, $offset, $src_length, $data, $src_offset);
	$self;
}


sub mmap {
	my ($self, $mode, $offset, $length)= @_;
	my $current= $self->_mmap;
	if ($current) {
		return $current->[0] if @_ == 1;
		croak "Buffer is already memory mapped";
	}
	my $mmap= OpenGL::Sandbox::mmap_buffer($self->id, $self->target, $mode, $offset, $length);
	$self->_mmap( [ $mmap, $mode, $offset, $length ] );
	$mmap;
}

sub unmap {
	my ($self)= @_;
	if ($self->_mmap) {
		OpenGL::Sandbox::unmap_buffer($self->id, $self->target, $self->_mmap->[0]);
		$self->_mmap(undef);
	}
	$self;
}

sub DESTROY {
	my $self= shift;
	$self->unmap if $self->_mmap;
	delete_buffers(delete $self->{id}) if $self->has_id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::Buffer - Wrapper object for OpenGL Buffer Object

=head1 VERSION

version 0.120

=head1 DESCRIPTION

OpenGL Buffers represent a named block of memory on the graphics hardware which can be used
for various purposes, mostly serving to deliver large quantities of data from the application
to be used repeatedly by the shaders.

Creating a buffer simply reserves an ID, which can then later be bound to a buffer target
and loaded with data.

Loading this module requires OpenGL 2.0 or higher.

=head1 ATTRIBUTES

=head2 name

Human-readable name of object (not GL's integer "name")

=head2 target

OpenGL buffer target which this buffer object should be bound to, when necessary.
This attribute will be updated by L</bind> if you bind to a different target.

=head2 usage

Default data usage hint for OpenGL, when loading data into this buffer.  If this is C<undef>,
the default when loading data will be C<GL_STATIC_DRAW>.  If you call L<load> with a different
usage value, it will update this attribute.

=head2 id

The OpenGL integer "name" of this buffer.  This is a lazy-built attribute, and will call
C<glGenBuffers> the first time you access it.  Use C<has_id> to find out whether this has
happened yet.

=over

=item has_id

True if the id attribute is allocated.

=back

=head2 autoload

If this field is defined at the time of the next call to L</bind>, this data will be
immediately be loaded into the buffer with glBufferData.  The field will then be cleared, to
avoid holding onto large blobs of data.

=head2 filename

If passed to the constructor, this implies an L</autoload> from the file.  Else it is just
for informational purposes.

=head1 METHODS

=head2 new

This is a standard Moo constructor, accepting any of the attributes, however it also accepts
an alias C<'data'> for the L</autoload> attribute.

=head2 bind

  $buffer->bind;
  $buffer->bind(GL_ARRAY_BUFFER);

Bind this buffer to a target, using L</target> as the default.
If L<autoload> is set, this will also load that data into the buffer.

Returns C<$self> for convenient chaining.

=head2 load

  $buffer->load( $data, $usage_hint );

Load data into this buffer object.  You may pass a scalar, scalar ref, memory map (which is
just a special scalar ref) or an L<OpenGL::Array>.  This performs an automatic glBindBuffer
to the value of L</target>.  If L</target> is not defined, this dies.

=head2 load_at

  $buffer->load_at( $offset, $data );
  $buffer->load_at( $offset, $data, $src_offset, $src_length );

Load some data into the buffer at an offset.  If the C<$src_offset> and/or C<$src_length>
values are given, this will use a substring of C<$data>.  The buffer will be bound to
L</target> first, if it wasn't already.  This performs an automatic glBindBuffer
to the value of L</target>.  If L</target> is not defined, this dies.  Additionally, if
L</load> has not been called before this dies.

Returns C<$self> for convenient chaining.

=head2 mmap

  my $mmap= $buffer->mmap($mode);
  my $mmap= $buffer->mmap($mode, $offset, $length);

Call glMapBuffer (or glMapNamedBuffer) to memory-map the buffer into the current process.
The C<$mode> can be a GL constant of C<GL_READ_ONLY>, C<GL_WRITE_ONLY>, C<GL_READ_WRITE>
or a perl style mode of C<r>, C<w>, C<r+>.

On OpenGL < 4.5, the buffer gets automatically mapped to its L</target> to perform the mapping.
OpenGL 4.5 introduced glMapNamedBuffer which avoids the need for binding.

The memory-map object persists for the live of this buffer object or until you call C<unmap>.
Until then, C<mmap> acts as an attribute to return the previous value to you.

=head2 unmap

Release a memory-mapping of this buffer, if any.  If OpenGL < 4.5, this forces the buffer to
get mapped first.  This happens automatically on object destruction.  If automatically
destroyed on OpenGL < 4.5, it genertes a warning, since messing with global state during
object destruction is a bad thing.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
