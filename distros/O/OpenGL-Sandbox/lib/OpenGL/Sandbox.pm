package OpenGL::Sandbox;
use v5.14; # I can aim for older upon request.  Not expecting any requests though.
use Exporter::Extensible -exporter_setup => 1;
use Try::Tiny;
use File::Spec::Functions qw/ catpath splitpath catdir splitdir /;
use Cwd 'abs_path';
use Carp;
use Log::Any '$log';
use Module::Runtime 'require_module';
use Scalar::Util 'weaken';

# ABSTRACT: Rapid-prototyping utilities for OpenGL
BEGIN {
our $VERSION = '0.120'; # VERSION
}

# Choose OpenGL::Modern if available, else fall back to OpenGL.
# But use the one configured in the environment.  But yet don't blindly
# load modules from environment either.
our $OpenGLModule;
BEGIN {
	my $fromenv= $ENV{OPENGL_SANDBOX_OPENGLMODULE} // '';
	# Don't blindly require module from environment...
	# Any other value, and the user must require it themself (such as perl -M)
	require_module($fromenv) if $fromenv eq 'OpenGL' || $fromenv eq 'OpenGL::Modern';
	my $mod= $fromenv? $fromenv
		: eval 'require OpenGL::Modern; 1'? 'OpenGL::Modern'
		: eval 'require OpenGL; 1'? 'OpenGL'
		: croak "Can't load either OpenGL::Modern or OpenGL.  Please install one.";
	# If this succeeds, assume it is safe to eval this package name later
	$mod->import(qw/
		glGetString glGetError glClear
		GL_VERSION GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT
	/);
	$OpenGLModule= $mod;
}
require constant;

export qw( =$res -resources(1) tex new_texture buffer new_buffer shader new_shader
	program new_program font vao new_vao
	make_context current_context next_frame
	gl_error_name get_gl_errors log_gl_errors warn_gl_errors
	gen_textures delete_textures _round_up_pow2
	),
	-V1 => sub { Module::Runtime::use_module('OpenGL::Sandbox::V1','0.04'); },
	# Conditionally export the stuff that gets conditionally compiled
	map { __PACKAGE__->can($_)? ($_) : () } qw(
	get_program_uniforms set_uniform get_glsl_type_name
	gen_buffers delete_buffers load_buffer_data load_buffer_sub_data
	);


sub resources {
	my ($self, $config)= @_;
	ref $config eq 'HASH' or croak "Expected hashref argument for -resources";
	my $res= OpenGL::Sandbox::ResMan->default_instance;
	for (keys %$config) {
		$res->can($_)? $res->$_($config->{$_}) : carp "No such ResMan attribute '$_'";
	}
}

# Called when exporting '$res'
sub _generateScalar_res { \OpenGL::Sandbox::ResMan->default_instance; }

# Called for unknown exports, including all the GL_CONSTANT and glFuncName
sub exporter_autoload_symbol {
	my ($self, $sym)= @_;
	if ($sym =~ /^(?:(GL_)|(gl[a-zA-Z]))/) {
		return __PACKAGE__->can($sym) // do {
			# First import it into this package, for cached export
			$OpenGLModule->import($sym);
			no strict 'refs';
			# If it is a constant, make sure it has been collapsed to a perl constant
			# (the original OpenGL module fails to do this)
			if ($1) {
				my $val= __PACKAGE__->can($sym)->();
				undef *$sym;
				constant->import($sym => $val);
			}
			__PACKAGE__->can($sym);
		};
	}
	# Notation of -V1 means require "OpenGL::Sandbox::V1".
	elsif ($sym =~ /^-V([0-9]+)/) {
		my $mod= "OpenGL::Sandbox::V$1";
		return [ sub { require_module($mod) }, 0 ];
	}
	return $self->next::method($sym);
}


sub tex         { OpenGL::Sandbox::ResMan->default_instance->tex(@_) }
sub new_texture { OpenGL::Sandbox::ResMan->default_instance->new_texture(@_) }
sub buffer      { OpenGL::Sandbox::ResMan->default_instance->buffer(@_) }
sub new_buffer  { OpenGL::Sandbox::ResMan->default_instance->new_buffer(@_) }
sub vao         { OpenGL::Sandbox::ResMan->default_instance->vao(@_) }
sub new_vao     { OpenGL::Sandbox::ResMan->default_instance->new_vao(@_) }
sub shader      { OpenGL::Sandbox::ResMan->default_instance->shader(@_) }
sub new_shader  { OpenGL::Sandbox::ResMan->default_instance->new_shader(@_) }
sub program     { OpenGL::Sandbox::ResMan->default_instance->program(@_) }
sub new_program { OpenGL::Sandbox::ResMan->default_instance->new_program(@_) }
sub font        { OpenGL::Sandbox::ResMan->default_instance->font(@_) }


our %context_provider_aliases;
BEGIN {
	%context_provider_aliases= (
		'GLX'            => 'OpenGL::Sandbox::ContextShim::GLX',
		'X11::GLX'       => 'OpenGL::Sandbox::ContextShim::GLX',
		'X11::GLX::DWIM' => 'OpenGL::Sandbox::ContextShim::GLX',
		'GLFW'           => 'OpenGL::Sandbox::ContextShim::GLFW',
		'OpenGL::GLFW'   => 'OpenGL::Sandbox::ContextShim::GLFW',
		'SDL'            => 'OpenGL::Sandbox::ContextShim::SDL',
		'SDLx::App'      => 'OpenGL::Sandbox::ContextShim::SDL',
		'GLUT'           => 'OpenGL::Sandbox::ContextShim::GLUT',
	);
}

our $current_context;
sub make_context {
	my %opts= (@_ == 1 && ref $_[0] eq 'HASH')? %{ $_[0] } : @_;
	# Check for geometry specification on command line
	my ($geom_spec, $w,$h,$l,$t);
	for (0..$#ARGV) {
		if ($ARGV[$_] =~ /^--?geometry(?:=(.*))?/) {
			$geom_spec= $1 // $ARGV[$_+1];
			last;
		}
	}
	# Also check environment variable
	$geom_spec //= $ENV{OPENGL_SANDBOX_GEOMETRY};
	if (defined $geom_spec
		&& (($w, $h, $l, $t)= ($geom_spec =~ /^(\d+)x(\d+)([-+]\d+)?([-+]\d+)?/))
	) {
		$opts{width} //= $w;
		$opts{height} //= $h;
		$opts{x} //= $l if defined $l;
		$opts{y} //= $t if defined $t;
	}

	# Load user's requested provider, or auto-detect first available
	my $provider;
	if ($ENV{OPENGL_SANDBOX_CONTEXT_PROVIDER}) {
		$provider= $context_provider_aliases{$ENV{OPENGL_SANDBOX_CONTEXT_PROVIDER}}
			or croak "Unhandled context provider $ENV{OPENGL_SANDBOX_CONTEXT_PROVIDER}";
		require_module($provider);
	}
	else {
		for my $mod (qw/ GLFW SDL GLX GLUT /) {
			next unless eval "require OpenGL::Sandbox::ContextShim::$mod; 1";
			$provider= "OpenGL::Sandbox::ContextShim::$mod";
			last;
		}
	}

	undef $current_context;
	my $cx= $current_context= $provider->new(%opts);
	$log->infof("Loaded %s", $cx->context_info);
	weaken($current_context) if defined wantarray;
	return $cx;
}


sub current_context { $current_context }


sub next_frame() {
	my $gl= OpenGL::Sandbox::current_context();
	$gl->swap_buffers if $gl;
	warn_gl_errors();
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	__PACKAGE__->maybe::next::method();
}


# gl_error_name comes from sandbox.c

sub get_gl_errors {
	my $self= shift;
	my (@names, $e);
	push @names, gl_error_name($e) || "(unrecognized) ".$e
		while (($e= glGetError()));
	return @names;
}

sub log_gl_errors {
	my @errors= get_gl_errors or return;
	$log->error("GL Error Bits: ".join(', ', @errors));
	return 1;
}

sub warn_gl_errors {
	my @errors= get_gl_errors or return;
	warn("GL Error Bits: ".join(', ', @errors)."\n");
	return 1;
}

# Pull in the C file and make sure it has all the C libs available
use Devel::CheckOS 'os_is';
use OpenGL::Sandbox::Inline do {
	my $src_dir= abs_path(catpath( (splitpath(__FILE__))[0,1] ));
	my $src= catdir($src_dir, 'Sandbox.c');
	my $libs= os_is('MSWin32')? '-lopengl32 -lgdi32 -lmsimg32' : '-lGL';
	# Inline::C can take a file path, but it mistakes Win32 absolute paths for C code,
	# so just slurp the file directly.
	$src= do { local $/= undef; open my $fh, '<', $src; <$fh> } if os_is('MSWin32');
	
	C => $src,
	INC => '-I'.$src_dir.' -I'.catdir($src_dir, qw( .. .. inc )),
	#CCFLAGSEX => '-Wall -g3 -Os'
	LIBS => $libs;
};


require OpenGL::Sandbox::ResMan;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox - Rapid-prototyping utilities for OpenGL

=head1 VERSION

version 0.120

=head1 SYNOPSIS

  use OpenGL::Sandbox qw( -V1 :all );
  make_context;
  setup_projection;
  next_frame;
  scale .01;
  font('Arial.ttf')->render("Hello World");
  next_frame;

(or, something more exciting and modern)

  #! /usr/bin/env perl
  use strict;
  use warnings;
  use Time::HiRes 'time';
  use OpenGL::Sandbox qw( :all GL_FLOAT GL_TRIANGLES glDrawArrays );
  use OpenGL::Sandbox -resources => {
    path => './t/data',
    program_config => {
      demo => { shaders => { vert => 'xy_screen.vert' } },
    },
    vertex_array_config => {
      unit_quad => {
        buffer => { data => pack('f*', # two triangles covering entire screen
            -1.0, -1.0,   1.0, -1.0,    -1.0,  1.0,
             1.0, -1.0,   1.0,  1.0,    -1.0,  1.0
        )},
        attributes => { pos => { size => 2, type => GL_FLOAT } }
      },
    },
  };
  make_context;
  new_program('demo', shaders => { frag => $ARGV[0] })->bind
    ->set_uniform("iResolution", 640, 480, 1.0);
  vao('unit_quad')->bind;
  my $started= time;
  while (1) {
    program('demo')->set_uniform("iGlobalTime", time - $started);
    glDrawArrays( GL_TRIANGLES, 0, 6 );
    next_frame;
  }

=head1 DESCRIPTION

This module collection aims to provide quick and easy access to OpenGL, for use in one-liners
or experiments or simple visualizations.  There are many system dependencies involved, so to
make the modules more accessible I divided it into multiple distributions:

=over

=item OpenGL::Sandbox

This package, containing the foundation for the rest, and anything in common among the
different OpenGL APIs.  It has methods to help set up the context, and load textures.

=item L<OpenGL::Sandbox::V1>

Everything related to OpenGL 1.x API

=item L<OpenGL::Sandbox::V1::FTGLFont>

A class providing fonts, but only for OpenGL 1.x

=back

=head1 EXPORTS

Nothing is exported by default.  You may request any of the following:

=head2 GL_$CONSTANT, gl$Function

This module can export OpenGL constants and functions, selecting them out of either L<OpenGL> or
L<OpenGL::Modern>.   When exported by name, constants will be exported as true perl constants.
However, the full selection of GL constants and functions is *not* available directly from this
module's namespace.  i.e. C<< OpenGL::Sandbox::GL_TRUE() >> does not work.

=head2 -V1

Loads L<OpenGL::SandBox::V1> (which must be installed separately) and makes all its symbols
available for importing.  That module contains many "sugar" functions to make the
GL 1.x API more friendly.  These aren't much use in modern OpenGL, and actually missing in
various OpenGL implementations (like ES) so they are supplied as a separate dist.

If L<OpenGL::SandBox::V1> is loaded, the C<:all> export will include everything from that
module as well.

=head2 :all

This *only* exports the symbols defined by this module collection, *not* every OpenGL symbol,
even though this module can export OpenGL symbols.  However, this module exports lots of short
(convenient) names which have a high chance of conflicting with your own symbols, so you should
think twice before using C<:all> in any long-lived code that you want to maintain.

=head2 $res

Returns a default global instance of the L<resource manager|OpenGL::Sandbox::ResMan>
with C<path> pointing to the current directory.

=head2 -resources => \%config

This isn't an actual export, but gives you a quick way to configure the default resource
manager instance.  Each key/value of C<%config> is applied as a method call.

=head2 Methods of C<$res>:

Shortcuts are exportable for the following methods of the default
L<resource manager|OpenGL::Sandbox::ResMan>:

=over

=item tex

=item new_texture

=item buffer

=item new_buffer

=item vao

=item new_vao

=item shader

=item new_shader

=item program

=item new_program

=item font

=back

(i.e. vao("Foo") is the same as C<< OpenGL::Sandbox::ResMan->default_instance->vao("Foo") >>)

Note that you need to install L<OpenGL::Sandbox::V1::FTGLFont> in order to get font support,
currently.  Other font providers might be added later.

=head2 make_context

  my $context= make_context( %opts );

Pick the lightest smallest module that can get a window set up for rendering.
This tries: L<X11::GLX>, L<OpenGL::GLFW>, and L<SDLx::App> in that order.
You can override the detection with environment variable C<OPENGL_SANDBOX_CONTEXT_PROVIDER>.
It assumes you don't have any desire to receive user input and just want to render some stuff.
If you do actually have a preference, you should just invoke that package yourself.

Returns an object whose scope controls the lifecycle of the window, and that object always has
a C<swap_buffers> method.  If you call this method in void context, the object is stored
internally and you can access it with L</current_context>.

This attempts to automatically pick up the window geometry, either from a "--geometry=" option
or from the environment variable C<OPENGL_SANDBOX_GEOMETRY>.  The Geometry value is in X11
notation of C<"${WIDTH}x${HEIGHT}+$X+$Y"> except that negative C<X>,C<Y> (from right edge) are
not supported.

Not all options have been implemented for each source, but the list of possibilities is:

=over

=item x, y, width, height

Set the placement and dimensions of the created window.

=item visible

Defaults to true, but if false, attempts to create an off-screen GL context.

=item fullscreen

Attempts to create a full-screen context.

=item noframe

Attempts to create a window without window border decorations.

=item title

Window title

=back

Note that if you're using Classic OpenGL (V1) you also need to set up the projection matrix
to something more useful than the defaults before rendering anything.
See L<OpenGL::Sandbox::V1/setup_projection>.

=head2 current_context

Returns the most recently created result of L</make_context>, assuming it hasn't been
garbage-collected.  If you stored the return value of L</make_context>, then garbage
collection happens according to that reference.  If you called L</make_context> in void
context, then the GL context will live indefinitely.

If you have a simple program with only one context, this global simplifies life for you.

=head2 next_frame

This calls a sequence of:

  current_context->swap_buffers;
  warn_gl_errors;
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

If you have loaded "-V1" it also calls

  glLoadIdentity();

Note that C<< current_context->swap_buffers() >> will only work after L</make_context>.

This is intended to help out with quick prototyping and one-liners:

  perl -e 'use OpenGL::Sandbox qw( -V1 :all ); make_context; while(1) { next_frame; ...; }'

=head2 gl_error_name

  my $name= gl_error_name( $code );

Returns the symbolic name of a GL error code.

=head2 get_gl_errors

  my @names= get_gl_errors();

Returns the symbolic names of any pending OpenGL errors, as a list.

=head2 log_gl_errors

Write all GL errors to Log::Any as C<< ->error >>.  Returns true if any errors were reported.

=head2 warn_gl_errors

Emit any GL errors using 'warn'.  Returns true if any errors were reported.

=head2 Wrappers Around glGen*

OpenGL::Modern doesn't currently provide nice wrappers for glGen family of functions, so
I wrote some of my own.  They follow the pattern

  my @ids= gen_textures($count);
  delete_textures(@ids);

=over

=item gen_textures

=item delete_textures

=item gen_buffers

=item delete_buffers

=item gen_vertex_arrays

=item delete_vertex_arrays

=back

=head2 load_buffer_data

  load_buffer_data( $buffer_target, $size, $data, $usage );

Wrapper around glBufferData.  C<$size> may be undef, in which case it will use the length of
C<$data>.  C<$usage> may also be undef, in which case it will default to C<GL_STATIC_DRAW>.

=head2 load_buffer_sub_data

  load_buffer_sub_data( $buffer_target, $offset, $size, $data, $data_offset );

Wrapper around glBufferSubData.  C<$size> may be undef, in which case it uses the length of
C<$data>.  C<$data_offset> is an optional offset from the start of C<$data> to avoid the
need for substring operations on the perl side.

=head2 get_glsl_type_name

  my $typename= get_glsl_type_name(GL_FLOAT_MAT3);
  # returns 'mat3'

Returns the GLSL type name that would be used to declare a type, per GL's type constants.

=head2 get_program_uniforms

  my $uniform_set= get_program_uniforms($prog_id);

Returns a hashref of all uniforms defined for a program.  The values are arrayrefs of

  [ $name, $index, $type, $size ]

This cache can be passed to L</set_uniform> to avoid further lookups.

=head2 set_uniform

  set_uniform($program, $cache, $name, @values);
  set_uniform($program, $cache, $name, \@values);
  set_uniform($program, $cache, $name, \@val1, \@val2, ...);
  set_uniform($program, $cache, $name, \OpenGL::Array);

Set a named uniform of a program.  For OpenGL < 4.1 the program must be the active program.
C<$cache> is the value returned by L</get_program_uniforms>.  C<$value> can be a wide variety
of things, but in general, must have a number of components that matches the size of the
uniform being assigned; the values will be automatically packed into a buffer.

=head1 INSTALLING

Getting this module collection installed is abnormally difficult.  This is a "selfish module"
that I wrote primarily for me, but published in case it might be useful to someone else. My
other more altruistic modules aim for high compatibility, but this one just unapologetically
depends on lots of specific things.

For the core module, you need:

=over

=item *

Perl 5.14 or higher

=item *

libGL, and headers

=item *

L<Image::PNG::Libpng>, for the feature that automatically loads PNG.

=item *

L<File::Map>, for efficiently memory-mapping resource files

=item *

XS support (C compiler)

=back

For the "V1" module (L<OpenGL::Sandbox::V1>) you will additionally need

=over

=item *

libGLU and headers

=back

For the "FTGLFont" module (L<OpenGL::Sandbox::V1::FTGLFont>) you will additionally need

=over

=item *

libftgl, and libfreetype2, and headers

=back

You probably also want a module to open a GL context to see things in.  This module is aware
of L<OpenGL::GLFW>, L<X11::GLX> and L<SDL>, but you can use anything you like since the GL
context is global.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
