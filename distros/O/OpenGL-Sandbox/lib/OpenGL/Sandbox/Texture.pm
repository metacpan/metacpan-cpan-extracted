package OpenGL::Sandbox::Texture;
use Moo;
use Carp;
use Try::Tiny;
use OpenGL::Sandbox qw(
	GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_TEXTURE_MAG_FILTER GL_TEXTURE_WRAP_S GL_TEXTURE_WRAP_T
	GL_UNSIGNED_BYTE GL_RGB GL_RGBA GL_BGR GL_BGRA
	glTexParameteri glBindTexture gen_textures delete_textures
);
use OpenGL::Sandbox::MMap;

# ABSTRACT: Wrapper object for OpenGL texture
our $VERSION = '0.120'; # VERSION


has name       => ( is => 'rw' );
has filename   => ( is => 'rw' );
has loader     => ( is => 'rw' );
has loaded     => ( is => 'rw' );
has src_width  => ( is => 'rw' );
has src_height => ( is => 'rw' );
has tx_id      => ( is => 'rw', lazy => 1, builder => 1, predicate => 1 );
has width      => ( is => 'rwp' );
has height     => ( is => 'rwp' );
has internal_format => ( is => 'rw' );
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


sub _build_tx_id { gen_textures(1) }
sub bind {
	my ($self, $target)= @_;
	glBindTexture($target // GL_TEXTURE_2D, $self->tx_id);
	if (!$self->loaded && (defined $self->loader || defined $self->filename)) {
		$self->load;
	}
	$self;
}

sub DESTROY {
	my $self= shift;
	delete_textures(delete $self->{tx_id}) if $self->has_tx_id;
}


sub load {
	my $self= shift;
	if (@_ == 0 || (@_ == 1 && ref($_[0]) ne 'HASH')) {
		my $fname= shift // $self->filename;
		my $loader= $self->loader // do {
			defined $fname && length $fname
				or croak "Can't automatically load texture ".$self->name." without loader or filename";
			my ($extension)= ($fname =~ /\.(\w+)$/)
				or croak "Can't determine loader without file extension: \"$fname\"";
			my $method= "load_$extension";
			$self->can($method)
				or croak "Can't load file of type $extension";
		};
		$self->$loader($fname);
	}
	else {
		my %opts= @_ == 1? %{ $_[0] } : @_;
		$self->internal_format(delete $opts{internal_format}) if defined $opts{internal_format};
		$self->target(delete $opts{target}) if defined $opts{target};
		my $level= delete $opts{level} // 0;
		my $xoffset= delete $opts{xoffset} // 0;
		my $yoffset= delete $opts{yoffset} // 0;
		my $width= delete $opts{width} // $self->width - $xoffset;
		my $height= delete $opts{height} // $self->height - $yoffset;
		defined $opts{format} || !defined $opts{data} or croak("'format' is required");
		my $format= delete $opts{format} // GL_RGB;
		my $type= delete $opts{type} // GL_UNSIGNED_BYTE;
		my $data= delete $opts{data};
		my $pitch= delete $opts{pitch} // 0;
		carp "Unknown options to ->load(): ".join(', ', keys %opts)
			if keys %opts;
		$self->tx_id; # make sure initialized
		$self->OpenGL::Sandbox::_texture_load($level, $xoffset, $yoffset, $width, $height, $format, $type, $data, $pitch);
		# that call automatically sets ->width and ->height and ->internal_format and ->loaded(1)
	}
	$self;
}


sub load_rgb {
	my ($self, $fname)= @_;
	my $mmap= OpenGL::Sandbox::MMap->new($fname);
	my ($dim, $has_alpha)= _from_pow2_filesize($fname, $mmap);
	$self->tx_id; # make sure it is built
	$self->OpenGL::Sandbox::_texture_load(0, 0, 0, $dim, $dim, $has_alpha? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, $mmap, 0);
	return $self;
}
sub load_bgr {
	my ($self, $fname)= @_;
	my $mmap= OpenGL::Sandbox::MMap->new($fname);
	my ($dim, $has_alpha)= _from_pow2_filesize($fname, $mmap);
	$self->tx_id; # make sure it is built
	$self->OpenGL::Sandbox::_texture_load(0, 0, 0, $dim, $dim, $has_alpha? GL_BGRA : GL_BGR, GL_UNSIGNED_BYTE, $mmap, 0);
	return $self;
}

sub _from_pow2_filesize {
	my ($fname, $mmap)= @_;
	my $size= length $$mmap;
	my $dim= 1;
	if ($size) {
		# Count size's powers of 4, in dim
		while (($size & 3) == 0) {
			$size >>= 2;
			$dim <<= 1;
		}
	}
	# If RGBA, $size == 1, else if RGB, $size == 3, else not a power of 2
	return $size == 1? ( $dim >> 1, 1 )
		: $size == 3? ( $dim, 0 )
		: croak("File $fname length $size is not a power of 2 square of pixels");
}


sub load_png {
	my ($self, $fname)= @_;
	my $use_bgr= 1; # TODO: check OpenGL for optimal format
	$self->tx_id; # make sure it is built
	my ($w, $h, $fmt, $dataref)= _load_png_data($fname);
	$self->OpenGL::Sandbox::_texture_load(0, 0, 0, $w, $h, $fmt, GL_UNSIGNED_BYTE, $dataref, 0);
	$self->src_width($w);
	$self->src_height($h);
	return $self;
}

sub _load_png_data {
	my ($fname)= @_;
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
	
	# PNG data is stored top-to-bottom, but OpenGL considers 0,0 the lower left corner.
	my $dataref= \join('', reverse @{ $png->get_rows });
	# Should have exactly the number of bytes for pixels, no extra padding or alignment
	length($$dataref) == ($has_alpha? 4 : 3) * $width * $height
		or croak sprintf "$fname does not contain the expected number of data bytes (%d != %d * %d * %d)",
			length($$dataref), $has_alpha? 4:3, $width, $height;
	return $width, $height, ($has_alpha? GL_RGBA : GL_RGB), $dataref;
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
	my ($w, $h, $fmt, $dataref)= _load_png_data($src);
	OpenGL::Sandbox::_img_rgb_to_bgr($dataref, ($fmt == GL_RGBA? 1 : 0)) if $dst =~ /\.bgr$/;
	open my $dst_fh, '>', $dst or croak "open($dst): $!";
	binmode $dst_fh;
	print $dst_fh $$dataref;
	close $dst_fh or croak "close($dst): $!";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::Texture - Wrapper object for OpenGL texture

=head1 VERSION

version 0.120

=head1 ATTRIBUTES

=head2 name

Human-readable name of this texture (not GL's integer "name")

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

Original width of the image independent of whether it got stored in a power-of-two texture.

=head2 src_height

Original height of the image independent of whether it got stored in a power-of-two texture.

=head2 tx_id

Lazy-built OpenGL texture ID (integer).  Triggers L</load> if image is not yet loaded.

=head2 has_tx_id

Check this to find out whether tx_id has been initialized.

=head2 width

Width of texture, in texels.

=head2 height

Height of texture, in texels.

=head2 internal_format

The enum (integer) of the internal storage format of the texture.  See tables at
L<https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml>.

=head2 has_alpha

Boolean of whether the texture contains an alpha channel.

=head2 mipmap

Boolean, whether texture has (or should have) mipmaps generated for it.
When loading any "simple" image format, this setting controls whether
mipmaps will be automatically generated.

=head2 min_filter

Value for GL_TEXTURE_MIN_FILTER.  Setting does not take effect until L</loaded>, but after that
a change to this attribute takes effect immediately, causing the texture to be bound in the
process.  Change with care.

=head2 mag_filter

Value for GL_TEXTURE_MAG_FILTER.  See notes on L</min_filter>.

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

  $tex->load; # from 'loader' or 'filename'
  $tex->load( $filename );
  $tex->load({ format => ..., type => ..., data => ... });

Load image data into the texture.  When no arguments are given, the normal mechanism is to call
C<< $self->loader->($self, $self->filename) >>.  L</loader> or L</filename> can be configured
in advance.  This method is B<called automatically> during the first call to L</bind> if
C<loader> or C<filename> are set.

A single non-hashref argument is assumed to be a filename to pass to the loader.

A hashref argument is treated as arguments to C<glTexImage2D> or C<glTexSubImage2D>.
It uses the same parameter names documented at L<https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml>
with defaults coming from the attributes of the object.

=over

=item target

Defaults to C<GL_TEXTURE_2D>.  (and other targets are not supported yet)

=item level

Defaults to C<0>. (the main image)

=item internal_format

Defaults to L</internal_format>, and if that isn't set, defaults to something matching C<format>.

=item width

Defaults to L</width>.

=item height

Defaults to L</height>.

=item xoffset

Defaults to C<0>.  Setting this to a non-zero value calls C<glTexSubImage2D>, which requires
that the image has already had its storage initialized.

=item yoffset

Defaults to C<0>.  Setting this to a non-zero value calls C<glTexSubImage2D>, which requires
that the image has already had its storage initialized.

=item border

Defaults to C<0>.  Ignored on any modern OpenGL.

=item format

Must be specified, unless C<data> is C<undef>.

=item type

Must be specified, unless C<data> is C<undef>.

=item data

A scalar-ref containing the bytes to be loaded.  May be undef to request that OpenGL allocate
space for the texture without loading any data into it.  However, if there is a Pixel Buffer 
Object currently bound to C<GL_PIXEL_UNPACK_BUFFER> then this I<may not> be a ref, and must
be either undef (0) or a numeric value, since it gets interpreted as an offset.

=item pitch

A number of bytes between one row of image data and the next.  Note that OpenGL doesn't support
arbitrary pitch values - it must be a multiple of the pixel size rounded up to one of the
standard alignments.  If you pass in a pitch value that doesn't work, this function dies.
The values of C<GL_UNPACK_ALIGNMENT> and C<GL_UNPACK_ROW_LENGTH> will be returned to their
original value afterward.  They will not be changed at all if you don't specify a pitch.

=back

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

Load image data from a PNG file.  The PNG must be internally encoded as RGB or RGBA,
and the presence or absence of alpha channel will be carried over to the texture.

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

Read a C<.png> file and write an C<.rgb> (or C<.bgr>) file.
The pixel format of the PNG must be C<RGB> or C<RGBA>.
This does not require an OpenGL context.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
