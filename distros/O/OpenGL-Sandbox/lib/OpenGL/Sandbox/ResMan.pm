package OpenGL::Sandbox::ResMan;
use Moo;
use Try::Tiny;
use Carp;
use File::Spec::Functions qw/ catdir rel2abs file_name_is_absolute canonpath splitdir /;
use Log::Any '$log';
use OpenGL::Sandbox::MMap;
use OpenGL::Sandbox::Texture;
use File::Find ();
use Scalar::Util 'weaken';
sub mmap { OpenGL::Sandbox::MMap->new(shift) }
our @CARP_NOT= ( 'OpenGL::Sandbox' );

# ABSTRACT: Resource manager for OpenGL prototyping
our $VERSION = '0.100'; # VERSION


has path              => ( is => 'rw', required => 1, trigger => sub {
	$_[0]->_clear_texture_dir_cache;
	$_[0]->_clear_shader_dir_cache;
	$_[0]->_clear_font_dir_cache;
	$_[0]->_clear_data_dir_cache;
});
*resource_root_dir= *path; # back-compat name

has texture_path      => ( is => 'rw', default => sub {'tex'},    trigger => sub { shift->_clear_texture_dir_cache } );
*tex_path= *texture_path;
has tex_fmt_priority  => ( is => 'rw', lazy => 1, builder => 1 );
has shader_path       => ( is => 'rw', default => sub {'shader'}, trigger => sub { shift->_clear_shader_dir_cache } );
has font_path         => ( is => 'rw', default => sub {'font'},   trigger => sub { shift->_clear_font_dir_cache } );
has data_path         => ( is => 'rw', default => sub {'data'},   trigger => sub { shift->_clear_data_dir_cache } );

has texture_config    => ( is => 'rw', default => sub { +{} } );
*tex_config= *texture_config;
has buffer_config     => ( is => 'rw', default => sub { +{} } );
has vertex_array_config => ( is => 'rw', default => sub { +{} } );
*vao_config= *vertex_array_config;
has shader_config     => ( is => 'rw', default => sub { +{} } );
has program_config    => ( is => 'rw', default => sub { +{} } );
has font_config       => ( is => 'rw', default => sub { +{} } );

sub _build_tex_fmt_priority {
	my $self= shift;
	# TODO: consult OpenGL to find out which format is preferred.
	return { bgr => 1, rgb => 2, png => 50 };
}

sub _interpret_config {
	my ($global_config, $name, $ctor_args)= @_;
	my $name_cfg= $global_config->{$name};
	# name_cfg might be a plain scalar, meaning it is an alias for a different name
	my $real_name= $name;
	while (defined $name_cfg && !ref $name_cfg) {
		$real_name= $name_cfg;
		$name_cfg= $global_config->{$real_name};
	}
	my $default_cfg= $global_config->{'*'};
	%$ctor_args= (
		name => $real_name,
		($default_cfg? (%$default_cfg):()),
		($name_cfg? (%$name_cfg):()),
		%$ctor_args
	);
	return ($real_name, $ctor_args);
}

has _texture_dir_cache => ( is => 'lazy', clearer => 1 );
has _texture_cache     => ( is => 'ro', default => sub { +{} } );
has _data_dir_cache    => ( is => 'lazy', clearer => 1 );
has _buffer_cache      => ( is => 'lazy', clearer => 1 );
has _vao_cache         => ( is => 'lazy', clearer => 1 );
has _shader_dir_cache  => ( is => 'lazy', clearer => 1 );
has _shader_cache      => ( is => 'lazy', clearer => 1 );
has _program_cache     => ( is => 'lazy', clearer => 1 );
has _mmap_cache        => ( is => 'ro', default => sub { +{} } );
has _font_cache        => ( is => 'lazy', clearer => 1 );
has _font_dir_cache    => ( is => 'lazy', clearer => 1 );

sub _build__buffer_cache  { require OpenGL::Sandbox::Buffer; return {}; }
sub _build__vao_cache     { require OpenGL::Sandbox::VertexArray; return {}; }
sub _build__shader_cache  { require OpenGL::Sandbox::Shader; return {}; }
sub _build__program_cache { require OpenGL::Sandbox::Program; return {}; }
sub _build__font_cache {
	eval { require OpenGL::Sandbox::V1::FTGLFont; 1 }
		or croak "Font support requires module L<OpenGL::Sandbox::V1::FTGLFont>, and OpenGL 1.x\n$@";
	return {};
}

sub _interpret_path {
	my ($self, $spec)= @_;
	return $self->path unless defined $spec && length $spec;
	return $spec if file_name_is_absolute($spec) or (splitdir($spec))[0] eq '.';
	return catdir($self->path, $spec);
}
sub _build__texture_dir_cache {
	$_[0]->_cache_directory($_[0]->_interpret_path($_[0]->tex_path), $_[0]->tex_fmt_priority)
}
sub _build__shader_dir_cache {
	$_[0]->_cache_directory($_[0]->_interpret_path($_[0]->shader_path));
}
sub _build__data_dir_cache {
	$_[0]->_cache_directory($_[0]->_interpret_path($_[0]->data_path));
}
sub _build__font_dir_cache {
	$_[0]->_cache_directory($_[0]->_interpret_path($_[0]->font_path));
}

sub _get_cached_mmap {
	my ($self, $file_info)= @_;
	my $mmap= $self->_mmap_cache->{$file_info->[0]} //= mmap($file_info->[1]);
	weaken($self->_mmap_cache->{$file_info->[0]}); # only keep weak references
	$mmap;
}


our $_default_instance;
sub default_instance {
	$_default_instance ||= __PACKAGE__->new(path => ".");
}
END { $_default_instance->clear_cache if $_default_instance }

sub BUILD {
	my $self= shift;
	$log->debug("OpenGL::Sandbox::ResMan loaded");
}


sub tex {
	my ($self, $name)= @_;
	$self->_texture_cache->{$name}
		|| ( try { $self->load_texture($name) }
		     catch { chomp(my $err= "Image '$name': $_"); $log->error($err); undef; }
		   )
		|| ($name ne 'default' && try { $self->tex('default') } )
		|| croak("No texture '$name' and no 'default'");
}

sub load_texture {
	my ($self, $name, %options)= @_;
	$self->_texture_cache->{$name} || do {
		$log->debug("loading texture $name");
		my ($real_name, $ctor_args)= _interpret_config($self->tex_config, $name, \%options);
		$self->_texture_cache->{$real_name} //= do {
			my $filename= $ctor_args->{filename} // $real_name;
			my $file_info= $self->_texture_dir_cache->{$filename}
				or croak "No such texture '$filename'";
			$ctor_args->{filename}= $file_info->[1];
			OpenGL::Sandbox::Texture->new($ctor_args);
		};
	};
}

sub new_texture {
	my ($self, $name, %options)= @_;
	$self->_texture_cache->{$name} and croak "Texture '$name' already exists";
	my ($real_name, $ctor_args)= _interpret_config($self->texture_config, $name, \%options);
	$self->_texture_cache->{$name}= $self->_texture_cache->{$real_name} //= do {
		my $filename= $ctor_args->{filename} // $real_name;
		my $file_info= $self->_texture_dir_cache->{$filename};
		$ctor_args->{filename}= $file_info->[1] if $file_info;
		OpenGL::Sandbox::Texture->new($ctor_args);
	}
}


sub buffer {
	my ($self, $name)= @_;
	$self->_buffer_cache->{$name} //= do {
		defined $self->buffer_config->{$name} or croak "No configured buffer '$name'";
		my ($real_name, $ctor_args)= _interpret_config($self->buffer_config, $name, {});
		$self->_buffer_cache->{$real_name} // $self->new_buffer($real_name, %$ctor_args);
	}
}

sub new_buffer {
	my ($self, $name, %options)= @_;
	$self->_buffer_cache->{$name} and croak "Buffer '$name' already exists";
	my ($real_name, $ctor_args)= _interpret_config($self->buffer_config, $name, \%options);
	$self->_buffer_cache->{$name}= $self->_buffer_cache->{$real_name} //= do {
		if (!defined $options{data} && !defined $options{autoload}) {
			my $filename= $ctor_args->{filename} // $real_name;
			my $file_info= $self->_data_dir_cache->{$filename};
			$ctor_args->{filename}= $file_info->[1] if $file_info;
		}
		OpenGL::Sandbox::Buffer->new($ctor_args);
	}
}


sub _replace_with_named_buffer {
	my $self= shift;
	return unless defined $_[0] && !ref $_[0] && $_[0] !~ /^[0-9]+$/;
	$_[0]= $self->buffer($_[0]);
}

sub vertex_array {
	my ($self, $name)= @_;
	$self->_vao_cache->{$name} //= do {
		defined $self->vao_config->{$name} or croak "No configured Vertex Array '$name'";
		my ($real_name, $ctor_args)= _interpret_config($self->vao_config, $name, {});
		$self->_vao_cache->{$real_name} // $self->new_vertex_array($real_name, %$ctor_args);
	};
}
*vao= *vertex_array;

sub new_vertex_array {
	my ($self, $name, %options)= @_;
	$self->_vao_cache->{$name} and croak "Vertex Array '$name' already exists";
	my ($real_name, $ctor_args)= _interpret_config($self->vao_config, $name, \%options);
	$self->_vao_cache->{$name}= $self->_vao_cache->{$real_name} //= do {
		# Any references to named buffer objects need replaced with the object.
		$self->_replace_with_named_buffer($_)
			for $ctor_args->{buffer}, map $_->{buffer}, values %{ $ctor_args->{attributes} // {} };
		OpenGL::Sandbox::VertexArray->new($ctor_args);
	}
}
*new_vao= *new_vertex_array;


sub shader {
	my ($self, $name)= @_;
	$self->_shader_cache->{$name} // $self->new_shader($name);
}

sub new_shader {
	my ($self, $name, %options)= @_;
	$self->_shader_cache->{$name} and croak "Shader '$name' already exists";
	my ($real_name, $ctor_args)= _interpret_config($self->shader_config, $name, \%options);
	$self->_shader_cache->{$name}= $self->_shader_cache->{$real_name} //= do {
		if (!$ctor_args->{source} && !$ctor_args->{binary}) {
			my $filename= $ctor_args->{filename} // $real_name;
			my $file_info= $self->_shader_dir_cache->{$filename}
				or croak "No such shader source '$filename'";
			$ctor_args->{filename}= $file_info->[1];
		}
		OpenGL::Sandbox::Shader->new($ctor_args);
	}
}


sub _shaders_matching_name {
	my ($self, $name)= @_;
	# If shaders "foo.frag" and "foo.vert" exist, then this
	# will generate { frag => "foo.frag", vert => "foo.vert" }
	map { $_ =~ /^\Q$name\E\.(\w+)$/? ($1 => $_) : () }
		keys %{ $self->_shader_dir_cache };
}
sub program {
	my ($self, $name)= @_;
	$self->_program_cache->{$name} //= do {
		if (!$self->program_config->{$name}) {
			# If there is no config for this program, then it must have existing shaders
			# that match it, else we assume it was a typo.
			$self->_shaders_matching_name($name)
				or croak "No configured or implied program '$name'";
		}
		my ($real_name, $ctor_args)= _interpret_config($self->program_config, $name, {});
		$self->_program_cache->{$real_name} // $self->new_program($real_name, %$ctor_args);
	}
}
sub new_program {
	my ($self, $name, %options)= @_;
	$self->_program_cache->{$name} and croak "Program '$name' already exists";
	my ($real_name, $ctor_args)= _interpret_config($self->program_config, $name, {});
	$self->_program_cache->{$name}= $self->_program_cache->{$real_name} //= do {
		# perform a deeper merge of the ->{shaders} element
		my $default_cfg= $self->program_config->{'*'};
		my $name_cfg= $self->program_config->{$real_name};
		$ctor_args->{shaders}= {
			$self->_shaders_matching_name($real_name),
			( $options{shaders}? %{ $options{shaders} } : () ),
			( $default_cfg && $default_cfg->{shaders}? %{ $default_cfg->{shaders} } : () ),
			( $name_cfg && $name_cfg->{shaders}? %{ $name_cfg->{shaders} } : () ),
		};

		# Now, translate the shader names into shader objects
		ref $_ or ($_= $self->shader($_))
			for values %{ $ctor_args->{shaders} };
		OpenGL::Sandbox::Program->new($ctor_args);
	}
}


sub font {
	my ($self, $name)= @_;
	$self->_font_cache->{$name} ||=
		( try { $self->load_font($name) }
		  catch { chomp(my $err= "Font '$name': $_"); $log->error($err); undef; }
		)
		|| ($name ne 'default' && try { $self->font('default') } )
		|| croak "No font '$name' and no 'default'";
}


*load_font= *new_font;
sub new_font {
	eval 'require OpenGL::Sandbox::V1::FTGLFont'
		or croak "Font support requires module L<OpenGL::Sandbox::V1::FTGLFont>, and OpenGL 1.x";
	no warnings 'redefine';
	*load_font= *_load_font;
	goto $_[0]->can('load_font');
}
sub _load_font {
	my ($self, $name, %options)= @_;
	$self->_font_cache->{$name} //= do {
		$log->debug("loading font $name");
		my ($real_name, $ctor_args)= _interpret_config($self->font_config, $name, \%options);
		$self->_font_cache->{$real_name} //= do {
			my $filename= $ctor_args->{filename} //= $real_name;
			my $file_info= $self->_font_dir_cache->{$filename}
				or croak "No such font source '$filename'";
			$ctor_args->{data}= $self->_get_cached_mmap($file_info);
			OpenGL::Sandbox::V1::FTGLFont->new($ctor_args);
		};
	};
}

# Not officially public anymore, so don't document it
sub load_fontdata {
	my ($self, $name)= @_;
	my ($real_name, $ctor_args)= _interpret_config($self->font_config, $name);
	my $filename= $ctor_args->{filename} //= $real_name;
	my $file_info= $self->_font_dir_cache->{$filename}
		or croak "No such font source '$filename'";
	$self->_get_cached_mmap($file_info);
}


sub clear_cache {
	my $self= shift;
	%{ $self->_mmap_cache }= ();
	%{ $self->_texture_cache }= ();
	$self->_clear_texture_dir_cache;
	$self->_clear_buffer_cache;
	$self->_clear_data_dir_cache;
	$self->_clear_vao_cache;
	$self->_clear_shader_cache;
	$self->_clear_shader_dir_cache;
	$self->_clear_program_cache;
	$self->_clear_font_cache;
	$self->_clear_font_dir_cache;
}

sub _cache_directory {
	my ($self, $path, $extension_priority)= @_;
	my %names;
	File::Find::find({ no_chdir => 1, wanted => sub {
		return if -d $_; # ignore directories
		my $full_path= $File::Find::name;
		(my $rel_name= substr($full_path, length($File::Find::dir))) =~ s,^[\\/],,;
		# If it's a symlink, get the real filename
		if (-l $full_path) {
			$full_path= readlink $full_path;
			$full_path= canonpath(catdir($File::Find::dir, $full_path))
				unless file_name_is_absolute($full_path);
		}
		# Decide on the friendly name which becomes the key in the hash
		# (but the whole filename always becomes a key in the hash as well)
		(my $short_name= $rel_name) =~ s/\.\w+$//;
		# If there is a conflict for the short key...
		if ($names{$short_name}) {
			# If extension priority available, use that.  Else first in wins.
			if (!$extension_priority) {
				$short_name= $rel_name;
			} else {
				my ($this_ext)= ($full_path =~ /\.(\w+)$/);
				my ($prev_ext)= ($names{$short_name}[1] =~ /\.(\w+)$/);
				($extension_priority->{$this_ext//''}//999) < ($extension_priority->{$prev_ext//''}//999)
					or ($short_name= $rel_name);
			}
		}
		# Stat, for device/inode.  But if stat fails, warn and skip it.
		if (my ($dev, $inode)= stat $full_path) {
			$names{$rel_name}= $names{$short_name}= [ "($dev,$inode)", $full_path ];
		}
		else {
			$log->warn("Can't stat $full_path: $!");
		}
	}}, $path) if -d $path;
	\%names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ResMan - Resource manager for OpenGL prototyping

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  my $r= OpenGL::Sandbox::ResMan->default_instance;
  $r->path( $path );
  my $tex= $r->tex('foo');
  my $font= $r->font('default');

=head1 DESCRIPTION

This object caches references to various OpenGL resources like textures and fonts.
It is usually instantiated as a singleton from L</default_instance> or from
importing the C<$res> variable from L<OpenGL::Sandbox>.  It pulls resources
from a directory of your choice.  Where possible, files get memory-mapped
directly into the library that uses them, which should keep the overhead of
this library as low as possible.

Note that you need to install L<OpenGL::Sandbox::V1::FTGLFont> in order to get font support,
currently.  Other font providers might be added later.

=head1 ATTRIBUTES

=head2 path

The path where resources are located, adhering to the basic layout of:

  ./tex/          # textures
  ./tex/default   # file or symlink for default texture.  Required.
  ./font/         # fonts compatible with libfreetype
  ./font/default  # file or symlink for default font.  Required.
  ./shader/       # GLSL shaders with extension '.glsl', '.frag', or '.vert'
  ./data/         # raw data to be loaded into Buffer Objects

You can override these implied sub-paths with the following attributes:

=over 18

=item texture_path

=item tex_path

(alias for texture_path)

=item shader_path

=item data_path

=item font_path

=back

A plain string is interpreted as relative to C<path>; an absolute path or path beginning
with C<"."> is used as-is.  An empty string means it is identical to C<path>.

=head2 C<*_config>

Each type of resource managed by this object can be pre-configured.  Each config attribute
is a hashref where the keys match the named of the created resources.  Each config may also
include a key C<'*'> which applies settings to every created resource.

The values of the config are usually hashrefs of constructor arguments that get shallow-merged
with arguments you pass to C<new_*>, but may also be plain scalars indicating that this resource
is an alias for some other name.

Several configurations also expect an entry for 'default', which gets returned on any request
for a missing resource.

The namespace of each type of resource is independent.

=over

=item texture_config

Configuration for L</new_tex>, constructing L<OpenGL::Sandbox::Texture>.

Example texture_config:

  {
    '*'     => { wrap_s => GL_CLAMP,  wrap_t => GL_CLAMP  },
    default => { filename => 'foo.png' }, # texture named "default"
    tile1   => { wrap_s => GL_REPEAT, wrap_t => GL_REPEAT },
    blocky  => { mag_filter => GL_NEAREST },
    alias1  => 'tile1',
  }

Textures can also be implied by a file in the L</tex_path> directory.

=item tex_config

Alias for C<texture_config>

=item buffer_config

Configuration for L</new_buffer>, constructing L<OpenGL::Sandbox::Buffer>.

  {
    '*' => { type => GL_VERTEX_ARRAY },
    triangle_data => { data => pack('f*', 1,1, 2,1, 2,-1, ...) }
  }

Buffers can also be implied by a file in the L</data_path> directory.

=item vertex_array_config

Configuration for L</new_vertex_array>, constructing L<OpenGL::Sandbox::VertexArray>.

  {
    my_triangles => {
      buffer => 'triangle_data',
      attributes => { pos => { size => 2, type => GL_FLOAT } }
    }
  }

Vertex Arrays must be configured; there is currently not a file format for them.

=item vao_config

Alias for C<vertex_array_config>

=item shader_config

Configuration for L</new_shader>, constructing L<OpenGL::Sandbox::Shader>.

  {
    '*' => { type => GL_FRAGMENT_SHADER },
    aurora => { filename => 'aurora.frag' },
    vpassthrough => { filename => 'vertex-passthrough.vert', type => GL_VERTEX_SHADER },
  }

Shaders are also implied by the presence of a file in the L</shader_path> directory.

=item program_config

Configuration for L</new_program>, constructing L<OpenGL::Sandbox::Program>.

  {
    '*' => { shaders => { vertex => 'vpassthrough', fragment => 'aurora' } },
    'demo' => { attr => { ... }, shaders => { vertex => 'special_vshader' } },
  }

Programs are also implied by the presence shaders of the same name prefix.

=item font_config

Configures L<OpenGL::Sandbox::V1::FTGLFont>.  (distributed separately)

  {
    '*'     => { face_size => 48 }, # default settings get applied to all configs
    3d      => { face_size => 64, type => 'FTExtrudeFont' },
    default => { face_size => 32, filename => 'myfont1' }, # font named 'default'
    myfont2 => 'myfont1',  # alias
  }

Fonts are also implied by the presence of a file in the L</font_path> directory.

=back

=head2 tex_fmt_priority

If you have texture files with the same base name and different extensions (such as original
image formats and derived ".png" or ".rgb") this resolves which image file you want to load
automatically for C<tex("basename")>.  Default is to load ".bgr", else ".rgb", else ".png"

=head1 METHODS

=head2 new

Standard Moo constructor.

=head2 default_instance

Return a default instance which uses the current directory as "path".

=head2 texture, tex, load_texture, new_texture

  my $tex= $res->tex( $name ); # handy alias
  my $tex= $res->texture( $name );
  my $tex= $res->load_texture( $name, %options );

Get a texture object.  Textures can be configured, or implied by presence of image files in
L</tex_path>, or both.

=over

=item texture

Return named texture, or load one with L</load_texture>.

The C<texture> method has a feature that if you request a non-existent texture, it will
return the texture named 'default' rather than throwing an exception.
This operates on the assumption that you'd rather see a big visual cue about which texute is
missing than to have your program crash from an exception.  You still get the exception if
you don't have a texture named 'default'.

=item tex

Alias for C<texture>

=item load_texture

Load a texture, or throw an exception if there is no image file by that name.

It first checks for a file of no extension in L</tex_path>, which may
be an image file, special "rgb" or "bgr" texture file, or symlink/hardlink to another file.
Failing that, it checks for a file of that name with any file extension, and
attempts to load them in whatever order they were returned.

=item new_texture

Create a new texture object regardless of whether the filename exists.  If the texture of this
name was already created, it dies.

=back

=head2 buffer, new_buffer

  my $buffer= $res->buffer( $name );
  my $buffer= $res->new_buffer( $name, %options );

Get a Buffer Object, either configured in L<buffer_config> or loaded from L<data_path>.
Buffer objects require OpenGL version 2.0 or above.

=over

=item buffer

Return an existing buffer object, or create one from L</buffer_config>.  If the C<$name> is
not configured, this dies.

=item new_buffer

This creates a new buffer object by combining C<%options> with any (optional) configuration for
this name in L</buffer_config>.  This dies if C<$name> was already created.

=back

=head2 vao, vertex_array, new_vao, new_vertex_array

  my $vertex_array= $res->vao( $name );
  my $vertex_array= $res->new_vao( $name, %options );

Return an existing or configured L<OpenGL::Sandbox::VertexArray|Vertex Array>.
The configurations may reference Buffer objects by name, and these will be translated
to the actual perl object with calls to L</buffer> before constructing the vertex array.

=over

=item vao

=item vertex_array

Return an existing VAO, or create one from L</vao_config>.  If the C<$name> is not configured,
this dies.

=item new_vao

=item new_vertex_array

Create a new Vertex Array Object by combining C<%options> with any (optional) configuration
for this name in L</vao_config>.  This dies if C<$name> was already created.

=back

=head2 shader, new_shader

  my $shader= $res->shader( $name );
  my $shader= $res->new_shader( $name, %options );

Returns a named shader.  A C<$name> ending with C<.frag> or C<.vert> will imply the relevant
GL shader type, unless you specifically passed it in C<%options> or configured it in
L</shader_config>.

Shader and Program objects require OpenGL version 2.0 or above.

=over

=item shader

Return an existing or configured shader.

=item new_shader

Create a new named shader from the options, including any configuration in L</shader_config>.
The shader must not have previously been created.

=back

=head2 program, new_program

  my $prog= $res->program( $name );
  my $prog= $res->new_program( $name, %options );

Return a named shader program.  If the combined C<%options> and L</program_config> do
not specify C<shaders>, this will look through the C<< shader/ >> directory for every
shader that begins with this name.  For example, if the directory contains:

   shader/foo.vert
   shader/foo.frag

Then this will augment the configuration with

   shaders => { vert => 'foo.vert', frag => 'foo.frag' }

Shader and Program objects require OpenGL version 2.0 or above.

=over

=item program

Return a configured or existing or implied (by shader names) program object.

=item new_program

Create and return a new named program, with the given constructor options, which get combined
with any in L</program_config>.

=back

=head2 font

  $font= $res->font( $name );

Retrieve a named font, either confgured in L<font_config>, previously created, or implied by
the presence of a file in L</font_path>.

If the font cannot be loaded, this logs a warning and returns the 'default'
font rather than throwing an exception or returning undef.  If there is no font named
'default', it dies instead.

=head2 new_font

  $font= $res->load_font( $name, %config );

Load a font by name.  By default, a font file of the same name is loaded as a
TextureFont and rendered at 24px.  If multiple named fonts reference the same
file (including hardlink checks), it will only be mapped into memory once.

Any configuration options specified here are combined with any defaults
specified in L</font_config>.

If the font can't be loaded, this throws an exception.  If the named font has
already been loaded, this will return the existing font, even if the options
have changed.

=head2 clear_cache

Call this method to remove all current references to any resource.  If this was the last
reference to those resources, it will also garbage collect any OpenGL resources that had been
allocated.  The next access to any font or texture will re-load the resource from disk.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
