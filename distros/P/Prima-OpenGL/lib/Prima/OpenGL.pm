package Prima::OpenGL;
use strict;
use Prima;
require Exporter;
require DynaLoader;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);

sub dl_load_flags { 0x01 };

$VERSION = '0.07';
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();

bootstrap Prima::OpenGL $VERSION;

package 
    Prima::Drawable; # double line needed for CPAN indexer, it thinks THIS is that module

# Now inject GL functions

sub gl_create
{
	my ($self, %config) = @_;
	die "already got GL context" if $self-> {__gl_context};
	$self-> {__gl_context} = Prima::OpenGL::context_create($self, \%config);
	warn Prima::OpenGL::last_error() unless $self-> {__gl_context};
	return $self-> {__gl_context} ? 1 : 0;
}

sub gl_destroy
{
	my $self = shift;
	Prima::OpenGL::context_destroy($self-> {__gl_context})
		if $self-> {__gl_context};
	undef $self-> {__gl_context};
}

sub gl_begin_paint
{
	my ( $self, %config ) = @_;
	die "already in paint state" if $self-> {__gl_context};
	my $ret = $self-> gl_create( %config );
	$self-> gl_select;
	return $ret;
}

sub gl_end_paint
{
	my ( $self ) = @_;
	$self-> gl_flush;
	$self-> gl_destroy;
}

sub gl_paint_state
{
	return shift-> {__gl_context} ? 1 : 0;
}

sub gl_select
{
	my $ctx = shift-> {__gl_context};
	Prima::OpenGL::context_make_current($ctx) if $ctx;
}

sub gl_unselect
{
	Prima::OpenGL::context_make_current(0);
}

sub gl_flush
{
	my $ctx = shift-> {__gl_context};
	Prima::OpenGL::flush($ctx) if $ctx;
}

sub gl_do
{
	my ( $self, $sub, @param ) = @_;
	unless ( Prima::OpenGL::context_push()) {
		warn Prima::OpenGL::last_error();
		return;
	}
	$self-> gl_select;
	my ($fail, @ret);
	eval { 
		if (wantarray) {
			@ret    = $sub->(@param);
		} else {
			$ret[0] = $sub->(@param);
		}
	};
	Prima::OpenGL::context_pop();
	$fail = $@;
	die $fail if $fail;
	return wantarray ? @ret : $ret[0];
}

__END__

=pod

=head1 NAME

Prima::OpenGL - Prima extension for OpenGL drawing

=head1 DESCRIPTION

The module allows for programming GL library together with Prima widgets.
L<OpenGL> module does a similar jobs using freeglut GUI library.

=head1 API

=head2 Selection of a GL visual

Before a GL area is used, a GL visual need to be selected first. Currently this
process is done by system-specific search function, so results differ between
win32 and x11.  Namely, x11 is less forgiving, and may fail with error. Also,
win32 and x11 GL defaults are different.

All attributes are passed to function C<context_create> as a hashref (see
description below).  If an option is not set, or set to undef, system default
is used.

=over

=item render ( "direct" or "xserver" )

Excerpt from C<glXCreateContext>:

Specifies whether rendering is to be done with a direct connection to the
graphics system if possible ("direct") or through the X server ("xserver").  If
direct is True, then a direct rendering context is created if the
implementation supports direct rendering, if the connection is to an X server
that is local, and if a direct rendering context is available. (An
implementation may return an indirect context when direct is True.) If direct
is False, then a rendering context that renders through the X server is always
created.  Direct rendering provides a performance advantage in some
implementations.  However, direct rendering contexts cannot be shared outside a
single process, and they may be unable to render to GLX

I here may add that I needed that option when was testing cygwin
implementation of the module in no-X11 environment. I couldn't get my X11
working on windows, and installed one under VirtualBox.  However, the only way
I could connect to X server there was to tell VirtualBox to forward the port
6000 inside the emulator to the host machine's 6000. GLX was happy finding that
the connection was local, and tried to use shared memory or whatever underlies
"direct" connection, and failed, instead of doing a soft fall-back to x11
protocol. The only way to make it work in such condition was explicitly setting
config to "xserver".

Actual for x11 only.

=item pixels ( "rgba" or "paletted" )

Selects either paletted or true-color visual representation.

=item layer INTEGER

x11: Layer zero corresponds to the main frame buffer of the display.  Layer
one is the first overlay frame buffer, level two the second overlay frame
buffer, and so on. Negative buffer levels correspond to underlay frame
buffers.

win32: Provides only three layers, -1, 0, and 1 .

=item double_buffer BOOLEAN

If set, select double buffering.

=item stereo BOOLEAN

If set, select a stereo visual.

=item color_bits INTEGER

Indicates the desired color index buffer size. Usual values are 8, 15, 16, 24, or 32.

=item aux_buffers INTEGER

Indicated the desired number of auxilliary buffers.

=item depth_bits INTEGER 

If this value is zero, visuals with no depth buffer are preferred.  Otherwise,
the largest available depth buffer of at least the minimum size is preferred.

=item stencil_bits INTEGER

Indicates the desired number of stencil bitplanes.  The smallest stencil buffer
of at least the specified size is preferred.  If the desired value is zero,
visuals with no stencil buffer are preferred.

=item red_bits green_bits blue_bits alpha_bits INTEGER

If this value is zero, the smallest available red/green/blue/alpha buffer is
preferred.  Otherwise, the largest available buffer of at least the minimum
size is preferred.
                    
=item accum_red_bits accum_green_bits accum_blue_bits accum_alpha_bits INTEGER

If this value is zero, visuals with no red/green/blue/alpha accumulation buffer
are preferred.  Otherwise, the largest possible accumulation buffer of at least
the minimum size is preferred.

=back

=head2 Methods

=over

=item context_push

Pushes the current GL context on an internal stack; there can be only 32 entries. Returns success flag.

=item context_pop

Pops the top GL context from the stack, and selects it. Returns success flag.


=item last_error

Call C<last_error> that returns string representation of the last error, or undef if there was none.
Note that X11 errors are really unspecific due to asynchronous mode X server and clients operate; expect
some generic error strings there.

=back

=head2 Prima::Drawable methods

The module also injects a set of gl_ methods for general use on Widget, Application, DeviceBitmap, Image,
and Printer (the latter on win32 only) objects.

=over

=item gl_create %config

Creates a GL context and prepares it for drawing on the object.
If the object is not a widget, it needs to be in C<begin_paint> state.
See valid C<%config> values in L<Selection of a GL visual> .

=item gl_destroy

Destroys GL context. Note that it doesn't synchronize GL area content, one
should do that manually using C<gl_flush> (and also remember to call glFinish
when drawing on bitmaps!). Need to be always called otherwise GL contexts would
leak.

=item gl_begin_paint %config

Shortcut for gl_create and gl_select. 
See valid C<%config> values in L<Selection of a GL visual> .

=item gl_end_paint

Shortcut for gl_flush and gl_destroy.

=item gl_paint_state

Returns boolean flag indicating whether the object is within gl_begin_paint/gl_end_paint state.

=item gl_select

Associates the widget visual with current GL context, so GL functions can be used on the widget.

=item gl_unselect

Disassociates any GL context.

=item gl_do &SUB

Executes &SUB within current GL context, restores context after the SUB is finished.

=item gl_flush

Copies eventual off-screen GL buffer to the screen. Needs to be always called at the end of paint routine.

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 SEE ALSO

L<Prima>, L<OpenGL>

   git clone git@github.com:dk/Prima-OpenGL.git

=head1 LICENSE

This software is distributed under the BSD License.

=head1 NOTES

Thanks to Chris Marshall for the motivating me writing this module!

=cut
