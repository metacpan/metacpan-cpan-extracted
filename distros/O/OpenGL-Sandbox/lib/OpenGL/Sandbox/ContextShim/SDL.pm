package OpenGL::Sandbox::ContextShim::SDL;
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';
use OpenGL::Sandbox qw/ glGetString GL_VERSION /;
use SDLx::App;

# ABSTRACT: Create OpenGL context with SDLx::App
our $VERSION = '0.100'; # VERSION

my %instances;
sub new {
	my $class= shift;
	my %opts= ref $_[0] eq 'HASH'? %{$_[0]} : @_;
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
	my $sdl= SDLx::App->new(
		title  => $opts{title} // 'OpenGL',
		(defined $opts{width}?  ( width  => $opts{width} ) : ()),
		(defined $opts{height}? ( height => $opts{height} ) : ()),
		($flags?                ( flags => (SDL::SDL_ANYFORMAT() | $flags) ) : ()),
		opengl => 1,
		exit_on_quit => 1,
	);
	my $self= bless { sdl => $sdl }, $class;
	weaken($instances{$self}= $self);
	return $self;
}

END {
	delete $_->{sdl} for values %instances;
}

sub sdl { shift->{sdl} }

sub context_info {
	my $self= shift;
	sprintf("SDLx::App %s, OpenGL version %s\n",
		$self->sdl && $self->sdl->VERSION, glGetString(GL_VERSION));
}

sub swap_buffers {
	my $self= shift;
	$self->sdl->sync if $self->sdl;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::ContextShim::SDL - Create OpenGL context with SDLx::App

=head1 VERSION

version 0.100

=head1 DESCRIPTION

This class is loaded automatically if needed by L<OpenGL::Sandbox/make_context>.
It uses L<SDLx::App> to create an OpenGL context.

=head1 ATTRIBUTES

=head2 sdl

The SDLx::App object

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
