package OpenGL::Sandbox::ContextShim::GLX;
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';
use OpenGL::Sandbox qw/ glGetString GL_VERSION /;
use X11::GLX::DWIM;

# ABSTRACT: Create OpenGL context with X11::GLX::DWIM
our $VERSION = '0.120'; # VERSION

our %instances;
sub new {
	my $class= shift;
	my %opts= ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	my $visible= $opts{visible} // 1;
	my $glx= X11::GLX::DWIM->new();
	if ($opts{fullscreen}) {
		# TODO: X11::Xlib doesn't have access to the modern concept of screen yet, only the
		#  idea of a screen that covers all physical monitors.  Need to add support for that.
		my $screen= $glx->screen;
		$opts{width}= $screen->width;
		$opts{height}= $screen->height;
	}
	# Target is lazy.  Make sure GL context fully initialized before return.
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
	my $self= bless { glx => $glx }, $class;
	weaken($instances{$self}= $self);
	return $self;
}

END {
	delete $_->{glx} for values %instances;
}

sub glx { shift->{glx} }

sub context_info {
	my $self= shift;
	sprintf("X11::GLX::DWIM %s, target '%s', GLX Version %s, OpenGL version %s\n",
		$self->glx && $self->glx->VERSION, $self->glx && $self->glx->target,
		$self->glx && $self->glx->glx_version, glGetString(GL_VERSION));
}

sub swap_buffers {
	my $self= shift;
	$self->glx->swap_buffers if $self->glx;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ContextShim::GLX - Create OpenGL context with X11::GLX::DWIM

=head1 VERSION

version 0.120

=head1 DESCRIPTION

This class is loaded automatically if needed by L<OpenGL::Sandbox/make_context>.
It uses L<X11::GLX::DWIM> to create an OpenGL context.

=head1 ATTRIBUTES

=head2 glx

The L<X11::GLX::DWIM> object

=head1 METHODS

=head2 Standard ContextShim API:

=over 14

=item new

Accepting all the options of L<OpenGL::Sandbox/make_context>

=item context_info

=item swap_buffers

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
