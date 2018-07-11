package OpenGL::Sandbox;
BEGIN { $OpenGL::Sandbox::VERSION = '0.03'; }
use v5.14; # I can aim for older upon request.  Not expecting any requests though.
use strict;
use warnings;
use Try::Tiny;
use Exporter;
use Carp;
use Log::Any '$log';
# Choose OpenGL::Modern if available, else fall back to OpenGL.
# But use the one configured in the environment.  But yet don't blindly
# load modules from environment either.
our $OpenGLModule;
BEGIN {
	$OpenGLModule //= do {
		my $fromenv= $ENV{OPENGL_SANDBOX_OPENGLMODULE} // '';
		# Don't blindly require module from environment...
		# Any other value, and the user must require it themself (such as perl -M)
		eval "require $fromenv" if $fromenv eq 'OpenGL' || $fromenv eq 'OpenGL::Modern';
		$fromenv? $fromenv
		: eval 'require OpenGL::Modern; 1'? 'OpenGL::Modern'
		: eval 'require OpenGL; 1'? 'OpenGL'
		: croak "Can't load either OpenGL::Modern or OpenGL.  Please install one.";
	};
	
	# If this succeeds, assume it is safe to eval this package name later
	$OpenGLModule->import(qw/
		glGetString glGetError
		GL_VERSION
	/);
}
require constant;
require OpenGL::Sandbox::ResMan;

# ABSTRACT: Rapid-prototyping utilities for OpenGL


sub tex  { OpenGL::Sandbox::ResMan->default_instance->tex(@_) }
sub font { OpenGL::Sandbox::ResMan->default_instance->font(@_) }


our @EXPORT_OK= qw( font tex make_context get_gl_errors );
our %EXPORT_TAGS= ( all => \@EXPORT_OK );

sub import {
	my $caller= caller;
	my $class= $_[0];
	my @gl_const;
	my @gl_fn;
	for (reverse 1..$#_) {
		my $arg= $_[$_];
		if ($arg eq '$res') {
			my $res= OpenGL::Sandbox::ResMan->default_instance;
			no strict 'refs';
			*{$caller.'::res'}= \$res;
			splice(@_, $_, 1);
		}
		elsif ($arg =~ /^:V(\d)(:.*)?$/) {
			my $mod= "OpenGL::Sandbox::V$1";
			my $imports= $2;
			$imports =~ s/:/ :/g;
			eval "package $caller; use $mod qw/ $imports /; 1"
				or croak "Can't load $mod (note that this must be installed separately)\n  $@";
			splice(@_, $_, 1);
		}
		elsif ($arg =~ /^GL_/) {
			push @gl_const, $arg;
			splice(@_, $_, 1);
		}
		elsif ($arg =~ /^gl[a-zA-Z]/) {
			# Let local methods in this package override external ones
			unless ($class->can($arg)) {
				push @gl_fn, $arg;
				splice(@_, $_, 1);
			}
		}
	}
	$class->_import_gl_constants_into($caller, @gl_const) if @gl_const;
	$class->_import_gl_functions_into($caller, @gl_fn) if @gl_fn;
	# Let the real Exporter module handle anything remaining in @_
	goto \&Exporter::import;
}

sub _import_gl_constants_into {
	my ($class, $into, @names)= @_;
	# First, import into this module, then import into caller.  This resolves an
	# inefficiency in traditional OpenGL module where it optimizes imports for
	# import speed rather than runtime speed.  We want constants to actually be
	# perl constants.
	my @need_import_const= grep !$class->can($_), @names;
	$OpenGLModule->import(@need_import_const);
	# Now for each constant we imported, undefine it then pass it to the constant module
	no strict 'refs';
	for (@need_import_const) {
		my $val= $class->can($_)->();
		undef *$_;
		constant->import($_ => $val);
	}
	# Now import them all into caller
	*{ $into . '::' . $_ }= $class->can($_) for @names;
}

sub _import_gl_functions_into {
	my ($class, $into, @names)= @_;
	eval "package $into; $OpenGLModule->import(\@names); 1" or die $@;
}


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
	# Try X11 first, because lightest weight
	my $provider= $ENV{OPENGL_SANDBOX_CONTEXT_PROVIDER};
	$provider //=
		eval('require X11::GLX::DWIM; 1;') ? 'X11::GLX::DWIM'
		: eval('require SDLx::App; 1;') ? 'SDLx::App'
		: croak "make_context needs one of X11::GLX or SDL to be installed";
	if ($provider eq 'X11::GLX' || $provider eq 'X11::GLX::DWIM') {
		require X11::GLX::DWIM;
		my $glx= X11::GLX::DWIM->new();
		my $visible= $opts{visible} // 1;
		if ($visible) {
			$glx->target({ window => {
				x => $opts{x} // 0,
				y => $opts{y} // 0,
				width => $opts{width} // 400,
				height => $opts{height} // 400
			}});
		} else {
			$glx->target({ pixmap => {
				width => $opts{width} // 256,
				height => $opts{height} // 256
			}});
		}
		$log->infof("Loaded X11::GLX::DWIM %s, target '%s', GLX Version %s, OpenGL version %s\n",
			$glx->VERSION, $visible? 'window':'pixmap', $glx->glx_version, glGetString(GL_VERSION));
		return $glx;
	}
	# TODO: Else try GLFW
	# Else try SDL
	elsif ($provider eq 'SDL' || $provider eq 'SDLx::App') {
		my $sdl_subclass= _init_sdl_wrapper();
		# TODO: Figure out best way to create invisible SDL window
		if (defined $opts{visible} && !$opts{visible}) {
			$opts{x}= -100;
			$opts{width}= $opts{height}= 1;
		}
		# This is the only option I know of for SDL to set initial window placement
		local $ENV{SDL_VIDEO_WINDOW_POS}= ($opts{x}//0).','.($opts{y}//0)
			if defined $opts{x} || defined $opts{y};
		my $flags= 0;
		$flags |= SDL::SDL_NOFRAME() if $opts{noframe};
		$flags |= SDL::SDL_FULLSCREEN() if $opts{fullscreen};
		my $sdl= $sdl_subclass->new(
			title  => $opts{title} // 'OpenGL',
			(defined $opts{width}?  ( width  => $opts{width} ) : ()),
			(defined $opts{height}? ( height => $opts{height} ) : ()),
			($flags?                ( flags => (SDL::SDL_ANYFORMAT() | $flags) ) : ()),
			opengl => 1,
			exit_on_quit => 1,
		);
		$log->infof("Loaded SDLx::App %s, OpenGL version %s\n", $sdl->VERSION, glGetString(GL_VERSION));
		return $sdl;
	}
	# TODO: else try Prima
	else {
		die "Unhandled context provider $provider";
	}
}

sub _init_sdl_wrapper {
	# Hack together a subclass of SDLx::App, but without alerting CPAN to its presence
	# and without introducing it to the perl namespace unless SDLx::App exists.
	unless (OpenGL::Sandbox::SDLx::App->VERSION) {
		require SDLx::App;
		no warnings 'once';
		$OpenGL::Sandbox::SDLx::App::VERSION= __PACKAGE__->VERSION;
		push @OpenGL::Sandbox::SDLx::App::ISA, 'SDLx::App';
		*OpenGL::Sandbox::SDLx::App::swap_buffers= sub {
			shift->sync;
		};
	}
	return 'OpenGL::Sandbox::SDLx::App';
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox - Rapid-prototyping utilities for OpenGL

=head1 VERSION

version 0.03

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

=head2 :V1:all

Exports ':all' from L<OpenGL::Sandbox::V1> (which must be installed separately).
This module contains many "sugar" functions to make the GL 1.x API more friendly.

C<:V2:all>, C<:V3:all>, etc will likewise import everything from packages named
C<OpenGL::SandBox::V$_> which do not currently exist, but could be authored
in the future.

=head2 make_context

  my $context= make_context( %opts );

Pick the lightest smallest module that can get a window set up for rendering.
This tries: L<X11::GLX>, and L<SDLx::App> in that order.  You can override the detection
with environment variable C<OPENGL_SANDBOX_CONTEXT_PROVIDER>.
It assumes you don't have any desire to receive user input and just want to render some stuff.
If you do actually have a preference, you should just invoke that package yourself.

Always returns an object whose scope controls the lifecycle of the window, and that object
always has a C<swap_buffers> method.

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

=head2 get_gl_errors

Returns the symbolic names of any pending OpenGL errors, as a list.

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

L<Inline::C>, including a local C compiler

=back

For the "V1" module (L<OpenGL::Sandbox::V1>) you will additionally need

=over

=item *

libGLU and headers

=item *

Inline::CPP, including a local C++ compiler

=back

For the "FTGLFont" module (L<OpenGL::Sandbox::V1::FTGLFont>) you will additionally need

=over

=item *

libftgl, and libfreetype2, and headers

=back

You probably also want a module to open a GL context to see things in.  This module is aware
of L<X11::GLX> and L<SDL>, but you can use anything you like since the GL context
is global.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
