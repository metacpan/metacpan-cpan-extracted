package OpenGL::Sandbox::Texture;
BEGIN { $OpenGL::Sandbox::Texture::VERSION = '0.02'; }
use Moo;
use Carp;
use Try::Tiny;
use OpenGL::Sandbox qw(
	GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_TEXTURE_MAG_FILTER GL_TEXTURE_WRAP_S GL_TEXTURE_WRAP_T
	glTexParameteri glBindTexture
);
use OpenGL::Sandbox::MMap;

# ABSTRACT: Wrapper object for OpenGL texture


has filename   => ( is => 'rw' );
has loader     => ( is => 'rw' );
has loaded     => ( is => 'rw' );
has src_width  => ( is => 'rw' );
has src_height => ( is => 'rw' );
has tx_id      => ( is => 'rw', lazy => 1, builder => 1, predicate => 1 );
has width      => ( is => 'rwp' );
has height     => ( is => 'rwp' );
has pow2_size  => ( is => 'rw' );
has has_alpha  => ( is => 'rwp' );
has mipmap     => ( is => 'rwp' );
has min_filter => ( is => 'rw', trigger => sub { shift->_maybe_apply_gl_texparam(GL_TEXTURE_MIN_FILTER, shift) } );
has mag_filter => ( is => 'rw', trigger => sub { shift->_maybe_apply_gl_texparam(GL_TEXTURE_MAG_FILTER, shift) } );
has wrap_s     => ( is => 'rw', trigger => sub { shift->_maybe_apply_gl_texparam(GL_TEXTURE_WRAP_S, shift) } );
has wrap_t     => ( is => 'rw', trigger => sub { shift->_maybe_apply_gl_texparam(GL_TEXTURE_WRAP_T, shift) } );

# Until loaded, changes to these parameters are just stored in the object.
# After loading, changes need pushed to GL, which also requires binding the texture.
sub _maybe_apply_gl_texparam {
	my ($self, $param, $val)= @_;
	return unless $self->loaded;
	$self->bind;
	glTexParameteri(GL_TEXTURE_2D, $param, $val);
}


sub bind {
	my ($self, $target)= @_;
	glBindTexture($target // GL_TEXTURE_2D, $self->tx_id);
	if (!$self->loaded && (defined $self->loader || defined $self->filename)) {
		$self->load;
	}
	$self;
}


sub load {
	my ($self, $fname)= @_;
	$fname //= $self->filename;
	my $loader= $self->loader // do {
		my ($extension)= ($fname =~ /\.(\w+)$/)
			or croak "No file extension: \"$fname\"";
		my $method= "load_$extension";
		$self->can($method)
			or croak "Can't load file of type $extension";
	};
	$self->$loader($fname);
}


sub load_rgb {
	my ($self, $fname)= @_;
	my $mmap= OpenGL::Sandbox::MMap->new($fname);
	$self->_load_rgb_square($mmap, 0);
	$self->loaded(1);
	return $self;
}
sub load_bgr {
	my ($self, $fname)= @_;
	my $mmap= OpenGL::Sandbox::MMap->new($fname);
	$self->_load_rgb_square($mmap, 1);
	$self->loaded(1);
	return $self;
}


sub load_png {
	my ($self, $fname)= @_;
	my $use_bgr= 1; # TODO: check OpenGL for optimal format
	my ($imgref, $w, $h)= _load_png_data_and_rescale($fname, $use_bgr);
	$self->_load_rgb_square($imgref, $use_bgr);
	$self->src_width($w);
	$self->src_height($h);
	$self->loaded(1);
	return $self;
}

sub _load_png_data_and_rescale {
	my ($fname, $use_bgr)= @_;
	require Image::PNG::Libpng;
	
	# Load PNG format, or die
	open my $fh, '<:raw', $fname or croak "open($fname): $!";
	my $png= Image::PNG::Libpng::create_read_struct();
	$png->init_io($fh);
	$png->read_png(Image::PNG::Const::PNG_TRANSFORM_EXPAND());
	close $fh or croak "close($fname): $!";
	
	# Verify it's an encoding that we can use
	my $header= $png->get_IHDR;
	my ($width, $height, $color, $bit_depth)= @{$header}{'width','height','color_type','bit_depth'};
	my $has_alpha= $color eq Image::PNG::Const::PNG_COLOR_TYPE_RGB()? 0
		: $color eq Image::PNG::Const::PNG_COLOR_TYPE_RGB_ALPHA()? 1
		: croak "$fname must be encoded as RGB or RGBA";
	$bit_depth == 8
		or croak "$fname must be encoded with 8-bit color channels";
	
	# Get the row data and scale it to a square if needed.
	# PNG data is stored top-to-bottom, but OpenGL considers 0,0 the lower left corner.
	my $dataref= \join('', reverse @{ $png->get_rows });
	# Should have exactly the number of bytes for pixels, no extra padding or alignment
	length($$dataref) == ($has_alpha? 4 : 3) * $width * $height
		or croak sprintf "$fname does not contain the expected number of data bytes (%d != %d * %d * %d)",
			length($$dataref), $has_alpha? 4:3, $width, $height;
	# Result is a ref to a scalar, to avoid copying
	$dataref= _rescale_to_pow2_square($width, $height, $has_alpha, $use_bgr? 1 : 0, $dataref)
		unless $width == $height && $width == _round_up_pow2($width);
	return $dataref, $width, $height;
}


sub render {
	# Render requires OpenGL 1.x API
	eval 'require OpenGL::Sandbox::V1' or croak "render requires OpenGL::Sandbox::V1 (1.x API)";
	# Now install methods for fast future calls
	no warnings 'redefine';
	*render_bound= *OpenGL::Sandbox::V1::_texture_render;
	*render= sub {
		$_[0]->bind;
		shift->render_bound(@_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_);
	};
	goto $_[0]->can('render');
}

*render_bound= *render;


sub convert_png {
	my ($src, $dst)= @_;
	my $use_bgr= $dst =~ /\.bgr$/? 1 : 0;
	my ($dataref)= _load_png_data_and_rescale($src, $use_bgr);
	open my $dst_fh, '>', $dst or croak "open($dst): $!";
	binmode $dst_fh;
	print $dst_fh $$dataref;
	close $dst_fh or croak "close($dst): $!";
}

# Pull in the C file and make sure it has all the C libs available
use Inline
	C => do { my $x= __FILE__; $x =~ s|\.pm|\.c|; Cwd::abs_path($x) },
	(defined $OpenGL::Sandbox::Texture::VERSION? (
		NAME => __PACKAGE__,
		VERSION => __PACKAGE__->VERSION
	) : () ),
	INC => '-I'.do{ my $x= __FILE__; $x =~ s|/[^/]+$|/|; Cwd::abs_path($x) }.' -I/usr/include/ffmpeg',
	LIBS => '-lGL -lswscale',
	CCFLAGSEX => '-Wall -g3 -Os';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::Texture - Wrapper object for OpenGL texture

=head1 VERSION

version 0.02

=head1 ATTRIBUTES

=head2 filename

Path from which image data will be loaded.  If not set, the texture will not have any default
image data loaded.

=head2 loader

A method name or coderef of your choice for lazy-loading the image data.  If not set, the
loader is determined from the L</filename> and if that is not set, nothing gets loaded on
creation of the texture id L<tx_id>.

Gets executed as C<< $tex->$loader($filename) >>.

=head2 loaded

Boolean; whether any image data has been loaded yet.  This is not automatically aware of data
you load yourself via calls to glTexImage or glTexSubImage.

=head2 src_width

Original width of the texture before it might have been rescaled to a square power of two.

=head2 src_height

Original height of the texture before it might have been rescaled to a square power of two.

=head2 tx_id

Lazy-built OpenGL texture ID (integer).  Triggers L</load> if image is not yet loaded.

=head2 has_tx_id

Check this to find out whether tx_id has been initialized.

=head2 width

Width of texture, in texels.

=head2 height

Height of texture, in texels.  Currently will always equal width.

=head2 pow2_size

If texture is loaded as a square power-of-two (currently all are) then this returns the
dimension of the texture.  This can differ from width/height in the event that you configured
those with the logical dimensions of the image.  If texture was loaded as a rectangular texture,
this is undef.

=head2 has_alpha

Boolean of whether the texture contains an alpha channel.

=head2 mipmap

Boolean, whether texture has (or should have) mipmaps generated for it.
When loading any "simple" image format, this setting controls whether
mipmaps will be automatically generated.

=head2 min_filter

Value for GL_TEXTURE_MIN_FILTER.  Setting does not take effect until L</loaded>, but after that
a change to this attribute takes effect immediately causing the texture to be bound.

=head2 max_filter

Value for GL_TEXTURE_MAX_FILTER.  See notes on L</min_filter>.

=head2 wrap_s

Value for GL_TEXTURE_WRAP_S.  See notes on L</min_filter>.

=head2 wrap_t

Value for GL_TEXTURE_WRAP_T.  See notes on L</min_filter>.

=head1 METHODS

=head2 bind

  $tex->bind;
  $tex->bind( $target );

Make this image the current texture for OpenGL's C<$target>, with the default of
C<GL_TEXTURE_2D>.  If L</tx_id> does not exist yet, it gets created.  If this texture has
a L</loader> or L</filename> defined and has not yet been L</loaded>, this automatically
calls L</load>.

Returns C<$self> for convenient chaining.

=head2 load

  $tex->load;

Load image data from a file into OpenGL.  This does not happen when the object is first
constructed, in case the OpenGL context hasn't been initialized yet.  It automatically happens
when L</bind> is called for the first time.

Calls C<< $self->loader->($self, $self->filename) >>.  L</tx_id> will be a valid texture id
after this (assuming the loader doesn't die).

Returns C<$self> for convenient chaining.

=head2 load_rgb

Load image data from a file which is nothing more than raw RGB or RGBA pixels
in a power-of-two dimension suitable for directly loading into OpenGL.  The
dimensions and presence of alpha channel are derived mathematically from the
file size.  The data is directly mmap'd so no copying is performed before
handing the pointer to OpenGL.

=head2 load_bgr

Same as rgb, except the source data has the red and blue bytes swapped.

=head2 load_png

Load image data from a PNG file.  The file is read and decoded, and if it is a
square power of two dimension, it is loaded directly.  If it is rectangular, it
gets stretched out to the next power of two square, using libswscale.

This library currently has no provision for the OpenGL "rectangular texture"
extension that allows for actual rectangular images and positive integer texture
coordinates.  That could be a useful addition.

=head2 TODO: load_ktx

OpenGL has its own image file format designed to directly handle all the various things you
might want to load into a texture.  Integrating libktx is on my list.

=head2 render

  $tex->render( %opts );

Render the texture as a plain rectangle with optional coordinate/size modifications.
Implies a call to C</bind> which might also trigger L</load>.

Assumes you have already enabled GL_TEXTURE_2D, and that you are not using shaders.
(future versions might include a shader-compatible implementation)

=over

=item C<x>, C<y>

Use specified origin point. Uses (0,0) if these are not provided.

=item C<w>, C<h>

Use specified width and/or height.  If undefined, defaults to pixel dimensions of the source
image, unless only one is specified then it calculates the other using the aspect ratio.
If source dimensions are not set, it uses the actual texture dimensions.  These may or might
not make sense for your current OpenGL coordinate space.

=item C<scale>

Multiply width and height by this number.

=item C<center>

Center the image on the origin, instead of using the origin as the lower-left corner.

=item C<s>, C<t>

Starting offset texture coordinates for the lower-left corner.

=item C<s_rep>, C<t_rep>

The number of repititions of the texture to use across the face of the described rectangle.
These won't give the desired result if you set the wrap mode of the texture to GL_CLAMP.

=back

=head2 render_bound

Like L</render> but skips the call to L</bind>, for when you know that it is already the
current texture.

=head1 CLASS FUNCTIONS

=head2 convert_png

  convert_png("foo.png", "foo.rgb");

Read a C<.png> file and write an C<.rgb> (or C<.bgr>) file.  The C<.png> will be scaled to a
square power of 2 if it is not already.  The pixel format of the PNG must be C<RGB> or C<RGBA>.
This does not require an OpenGL context.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
