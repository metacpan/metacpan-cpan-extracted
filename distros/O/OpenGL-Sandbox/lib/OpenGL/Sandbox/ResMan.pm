package OpenGL::Sandbox::ResMan;
BEGIN { $OpenGL::Sandbox::ResMan::VERSION = '0.02'; }
use Moo;
use Try::Tiny;
use Carp;
use File::Spec::Functions qw/ catdir rel2abs file_name_is_absolute canonpath /;
use Log::Any '$log';
use OpenGL::Sandbox::MMap;
use File::Find ();
use Scalar::Util ();

# ABSTRACT: Resource manager for OpenGL prototyping


has resource_root_dir => ( is => 'rw', default => sub { '.' } );
has font_config       => ( is => 'rw', default => sub { +{} } );
has tex_config        => ( is => 'rw', default => sub { +{} } );
has tex_fmt_priority  => ( is => 'rw', lazy => 1, builder => 1 );
has tex_default_fmt   => ( is => 'rw', lazy => 1, builder => 1 );

sub _build_tex_fmt_priority {
	my $self= shift;
	# TODO: consult OpenGL to find out which format is preferred.
	return { bgr => 1, rgb => 2, png => 50 };
}

sub _build_tex_default_fmt {
	my $self= shift;
	my $pri= $self->tex_fmt_priority;
	# Select the lowest value from the keys of the format priority map
	my $first;
	for (keys %{$self->tex_fmt_priority}) {
		$first= $_ if !defined $first || $pri->{$first} > $pri->{$_};
	}
	return $first // 'bgr';
}

has _fontdata_cache    => ( is => 'ro', default => sub { +{} } );
has _font_cache        => ( is => 'ro', default => sub { +{} } );
has _font_dir_cache    => ( is => 'lazy' );
has _texture_cache     => ( is => 'ro', default => sub { +{} } );
has _texture_dir_cache => ( is => 'lazy' );

sub _build__texture_dir_cache {
	$_[0]->_cache_directory(catdir($_[0]->resource_root_dir, 'tex'), $_[0]->tex_fmt_priority)
}
sub _build__font_dir_cache {
	$_[0]->_cache_directory(catdir($_[0]->resource_root_dir, 'font'));
}


our $_default_instance;
sub default_instance {
	$_default_instance ||= __PACKAGE__->new();
}

sub BUILD {
	my $self= shift;
	$log->debug("OpenGL::Sandbox::ResMan loaded");
}


sub release_gl {
	my $self= shift;
	$_->release_gl for values %{$self->_font_cache};
	%{$self->_tex_cache}= ();
}


sub font {
	my ($self, $name)= @_;
	$self->_font_cache->{$name} ||=
		( try { $self->load_font($name) }
		  catch { chomp(my $err= "Font '$name': $_"); $log->error($err); undef; }
		)
		|| $self->_font_cache->{default}
		|| $self->load_font('default');
}


sub load_font {
	eval 'require OpenGL::Sandbox::V1::FTGLFont'
		or croak "Font support requires module L<OpenGL::Sandbox::V1::FTGLFont>, and OpenGL 1.x";
	no warnings 'redefine';
	*load_font= *_load_font;
	goto $_[0]->can('load_font');
}
sub _load_font {
	my ($self, $name, %options)= @_;
	$self->_font_cache->{$name} ||= do {
		$log->debug("loading font $name");
		my $name_cfg= $self->font_config->{$name} // {};
		# Check for alias
		ref $name_cfg
			or return $self->load_font($name_cfg);
		# Merge options, configured options, and configured defaults
		my $default_cfg= $self->font_config->{'*'} // {};
		%options= ( filename => $name, %$default_cfg, %$name_cfg, %options );
		my $font_data= $self->load_fontdata($options{filename});
		OpenGL::Sandbox::V1::FTGLFont->new(data => $font_data, %options);
	};
}


sub load_fontdata {
	my ($self, $name)= @_;
	my $mmap;
	return $mmap if $mmap= $self->_fontdata_cache->{$name};
	
	$log->debug("loading fontdata $name");
	my $info= $self->_font_dir_cache->{$name}
		or croak "No such font file '$name'";
	# $info is pair if [$inode_key, $real_path].  Check if inode is already mapped.
	unless ($mmap= $self->_fontdata_cache->{$info->[0]}) {
		# If it wasn't, map it and also weaken the reference
		$mmap= OpenGL::Sandbox::MMap->new($info->[1]);
		Scalar::Util::weaken( $self->_fontdata_cache->{$info->[0]}= $mmap );
	}
	# Then cache that reference for this name, but also a weak reference.
	# (the font objects will hold strong references to the data)
	Scalar::Util::weaken( $self->_fontdata_cache->{$name}= $mmap );
	return $mmap;
}


sub tex {
	my ($self, $name)= @_;
	$self->_texture_cache->{$name} ||=
		( try { $self->load_texture($name) }
		  catch { chomp(my $err= "Image '$name': $_"); $log->error($err); undef; }
		)
		|| $self->_texture_cache->{default}
		|| $self->load_texture('default');
}


sub load_texture {
	require OpenGL::Sandbox::Texture;
	no warnings 'redefine';
	*load_texture= *_load_texture;
	goto $_[0]->can('load_texture');
}
sub _load_texture {
	my ($self, $name, %options)= @_;
	my $tex;
	return $tex if $tex= $self->_texture_cache->{$name};
	
	$log->debug("loading texture $name");

	my $name_cfg= $self->tex_config->{$name} // {};
	# Check for alias
	ref $name_cfg
		or return $self->load_texture($name_cfg);

	# Merge options, configured options, and configured defaults
	my $default_cfg= $self->tex_config->{'*'} // {};
	%options= ( filename => $name, %$default_cfg, %$name_cfg, %options );
	
	my $info= $self->_texture_dir_cache->{$options{filename}}
		or croak "No such texture '$options{filename}'";
	$tex= OpenGL::Sandbox::Texture->new(%options, filename => $info->[1]);
	$self->_texture_cache->{$name}= $tex;
	return $tex;
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
		(my $key= $rel_name) =~ s/\.\w+$//;
		# If there is a conflict for the key, resolve with the extension priority (low wins)
		# or else a key of literally $_ takes priority
		if ($names{$key}) {
			if (!$extension_priority) {
				return unless $rel_name eq $key;
			} else {
				my ($this_ext)= ($full_path =~ /\.(\w+)$/);
				my ($prev_ext)= ($names{$key}[1] =~ /\.(\w+)$/);
				($extension_priority->{$this_ext//''}//999) < ($extension_priority->{$prev_ext//''}//999)
					or return;
			}
		}
		# Stat, for device/inode.  But if stat fails, warn and skip it.
		if (my ($dev, $inode)= stat $full_path) {
			$names{$rel_name}= $names{$key}= [ "($dev,$inode)", $full_path ];
		}
		else {
			$log->warn("Can't stat $full_path: $!");
		}
	}}, $path);
	\%names;
}


sub clear_cache {
	my $self= shift;
	$self->_clear_texture_cache;
	$self->_clear_texture_dir_cache;
	$self->_clear_font_cache;
	$self->_clear_fontdata_cache;
	$self->_clear_font_dir_cache;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ResMan - Resource manager for OpenGL prototyping

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  my $r= OpenGL::Sandbox::ResMan->default_instance;
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

=head2 resource_root_dir

The path where resources are located, adhering to the basic layout of:

  ./tex/          # textures
  ./tex/default   # file or symlink for default texture.  Required.
  ./font/         # fonts compatible with libfreetype
  ./font/default  # file or symlink for default font.  Required.

=head2 font_config

A hashref of font names which holds default L<OpenGL::Sandbox::Font|font> constructor
options.  The hash key of C<'*'> can be used to apply default values to every font.
The font named 'default' can be configured here instead of needing a file of that name in
the C<font/> directory.

Example font_config:

  {
    '*'     => { face_size => 48 }, # default settings get applied to all configs
    3d      => { face_size => 64, type => 'FTExtrudeFont' },
    default => { face_size => 32, filename => 'myfont1' }, # font named 'default'
    myfont2 => 'myfont1',  # alias
  }

=head2 tex_config

A hashref of texture names which holds default L<OpenGL::Sandbox::Texture|texture> constructor
options.  The hash key of C<'*'> can be used to apply default values to every texture.
The texture named 'default' can be configured here instead of needing a file of that name in
the C<tex/> directory.

Example tex_config:

  {
    '*'     => { wrap_s => GL_CLAMP,  wrap_t => GL_CLAMP  },
    default => { filename => 'foo.png' }, # texture named "default"
    tile1   => { wrap_s => GL_REPEAT, wrap_t => GL_REPEAT },
    blocky  => { mag_filter => GL_NEAREST },
    alias1  => 'tile1',
  }

=head1 METHODS

=head2 new

Standard Moo constructor.  Also validates the resource directory by loading
"font/default", which must exist (either a file or symlink)

=head2 default_instance

Return a default instance which uses the current directory as "resource_root_dir".

=head2 release_gl

Free all OpenGL resources currently referenced by the texture and image cache.

=head2 font

  $font= $res->font( $name );

Retrieve a named font, loading it if needed.  See L</load_font>.

If the font cannot be loaded, this logs a warning and returns the 'default'
font rather than throwing an exception or returning undef.

=head2 load_font

  $font= $res->load_font( $name, %config );

Load a font by name.  By default, a font file of the same name is loaded as a
TextureFont and rendered at 24px.  If multiple named fonts reference the same
file (including hardlink checks), it will only be mapped into memory once.

Any configuration options specified here are combined with any defaults
specified in L</font_config>.

If the font can't be loaded, this throws an exception.  If the named font has
already been loaded, this will return the existing font, even if the options
have changed.

=head2 load_fontdata

  $mmap= $res->load_fontdata( $name );

Memory-map the given font file.  Dies if the font doesn't exist.
A memory-mapped font file can be shared between all the renderings
at different resolutions.

=head2 tex

  my $tex= $res->tex( $name );

Load a texture by name, or return the 'default' texture if it doesn't exist.

=head2 load_texture

  my $tex= $res->load_texture( $name )

Load a texture by name.  It first checks for a file of no extension, which may
be an image file, cached texture file, or symlink/hardlink to another file.
Failing that, it checks for a file of that name with any file extension, and
attempts to load them in whatever order they were returned.

Dies if no matching file can be found, or if it wasn't able to process any match.

=head2 clear_cache

Call this method to remove all current references to any resource.  If this was the last
reference to those resources, it will also garbage collect any OpenGL resources that had been
allocated.  The next access to any font or texture will re-load the resource from disk.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
