package OpenGL::Sandbox;
our $VERSION = '0.042'; # VERSION
use v5.14; # I can aim for older upon request.  Not expecting any requests though.
use Exporter::Extensible -exporter_setup => 1;
use Try::Tiny;
use Carp;
use Log::Any '$log';
use Module::Runtime 'require_module';
use Scalar::Util 'weaken';
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
require OpenGL::Sandbox::ResMan;

# ABSTRACT: Rapid-prototyping utilities for OpenGL


sub tex  { OpenGL::Sandbox::ResMan->default_instance->tex(@_) }
sub font { OpenGL::Sandbox::ResMan->default_instance->font(@_) }


export qw( =$res font tex make_context current_context next_frame
	get_gl_errors log_gl_errors warn_gl_errors
	glGetString glGetError GL_VERSION ),
	-V1 => sub { Module::Runtime::use_module('OpenGL::Sandbox::V1','0.04'); };

sub _generateScalar_res { \OpenGL::Sandbox::ResMan->default_instance; }

sub exporter_autoload_symbol {
	my ($self, $sym)= @_;
	if ($sym =~ /^(?:(GL_)|(gl[a-zA-Z]))/) {
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
		return ($OpenGL::Sandbox::EXPORT{$sym}= __PACKAGE__->can($sym));
	}
	# Notation of -V1 means require "OpenGL::Sandbox::V1".
	elsif ($sym =~ /^-V([0-9]+)/) {
		my $mod= "OpenGL::Sandbox::V$1";
		return [ sub { require_module($mod) }, 0 ];
	}
	return $self->next::method($sym);
}


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
	);
}

our $current_context;
sub make_context {
	my (%opts)= @_;
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
	my $provider= $ENV{OPENGL_SANDBOX_CONTEXT_PROVIDER};
	$provider //=
		# Try X11 first, because lightest weight
		eval('require X11::GLX::DWIM; 1;') ? 'GLX'
		: eval('require OpenGL::GLFW; 1;') ? 'GLFW'
		: eval('require SDLx::App; 1;') ? 'SDL'
		: croak "make_context needs one of X11::GLX, OpenGL::GLFW, or SDLx::App to be installed";
	
	my $class= $context_provider_aliases{$provider}
		or croak "Unhandled context provider $provider";
	require_module($class);
	
	undef $current_context;
	my $cx= $current_context= $class->new(%opts);
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


our %_gl_err_msg;
BEGIN {
	%_gl_err_msg= map { my $v= eval "$OpenGLModule->import('$_'); $_()"; defined $v? ($v => $_) : () } qw(
		GL_INVALID_ENUM
		GL_INVALID_VALUE
		GL_INVALID_OPERATION
		GL_INVALID_FRAMEBUFFER_OPERATION
		GL_OUT_OF_MEMORY
		GL_STACK_OVERFLOW
		GL_STACK_UNDERFLOW
		GL_TABLE_TOO_LARGE
	);
}

sub get_gl_errors {
	my $self= shift;
	my (@names, $e);
	push @names, $_gl_err_msg{$e} || "(unrecognized) ".$e
		while (($e= glGetError()));
	return @names;
}

sub log_gl_errors {
	my @errors= get_gl_errors;
	$log->error("GL Error Bits: ".join(', ', @errors)) if @errors;
}

sub warn_gl_errors {
	my @errors= get_gl_errors;
	warn("GL Error Bits: ".join(', ', @errors)."\n") if @errors;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox - Rapid-prototyping utilities for OpenGL

=head1 VERSION

version 0.042

=head1 SYNOPSIS

  use OpenGL::Sandbox qw( -V1 :all );
  make_context;
  setup_projection;
  next_frame;
  scale .01;
  font('Arial.ttf')->render("Hello World");
  next_frame;

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

=head2 GL_$CONSTANT, gl$Function

This module can export OpenGL constants and functions, selecting them out of either L<OpenGL> or
L<OpenGL::Modern>.   When exported by name, constants will be exported as true perl constants.
However, the full selection of GL constants and functions is *not* available directly from this
module's namespace.  i.e. C<< OpenGL::Sandbox::GL_TRUE() >> does not work.

=head2 $res

Returns a default global instance of the L<resource manager|OpenGL::Sandbox::ResMan>
with C<resource_root_dir> pointing to the current directory.

=head2 tex

Shortcut for C<< OpenGL::Sandbox::ResMan->default_instance->tex >>

=head2 font

Shortcut for C<< OpenGL::Sandbox::ResMan->default_instance->font >>

Note that you need to install L<OpenGL::Sandbox::V1::FTGLFont> in order to get font support,
currently.  Other font providers might be added later.

=head2 -V1

Loads L<OpenGL::SandBox::V1> (which must be installed separately) and makes all its symbols
available for importing.  This module contains many "sugar" functions to make the
GL 1.x API more friendly.

C<-V2>, C<-V3>, etc will likewise import everything from packages named C<OpenGL::SandBox::V$_>
which do not currently exist, but could be authored in the future.

=head2 :all

This *only* exports the symbols defined by this module collection, *not* every OpenGL symbol.

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

=head2 get_gl_errors

Returns the symbolic names of any pending OpenGL errors, as a list.

=head2 log_gl_errors

Write all GL errors to Log::Any as C<< ->error >>

=head2 warn_gl_errors

Emit any GL errors using 'warn'

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

LibAV libraries libswscale, libavutil, and headers, for the feature that automatically rescales textures

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
