#!/usr/bin/perl -w
#	Cdrom.pm
#
#	a SDL cdrom manipluation module
#
#	David J. Goehrig Copyright (C) 2000

package SDL::Cdrom;
use strict;
use SDL::sdlpl;

BEGIN {
	use Exporter();
	use vars qw(@ISA @EXPORT);
	@ISA = qw(Exporter);
	@EXPORT = qw/ &CD_NUM_DRIVES /;
}

#
# Cdrom Constructor / Destructor
#

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{-number} = shift;
	$self->{-cdrom} = SDL::sdlpl::sdl_cd_open($self->{-number});
	if ("error" eq SDL::sdlpl::sdl_cd_status($self->{-cdrom})) {
		die SDL::sdlpl::sdl_get_error(); }
	bless $self,$class;
	return $self;
}

sub DESTROY {
	my $self = shift;
	SDL::sdlpl::sdl_cd_close($self->{-cdrom});
}

#
# CD_NUM_DRIVES 
#
#	This is a pseudo constant which tells how many
#	cdrom drives there are in the system
#

sub CD_NUM_DRIVES {
	return SDL::sdlpl::sdl_cd_num_drives();
}

#
# drive name
#

sub name {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_name($self->{-cdrom});
}

#
# track listing
#

sub track_listing {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_track_listing($self->{-cdrom});
}

#
# status
#

sub status {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_status($self->{-cdrom});
}

#
# play (track,number, ...)
#
# I've chosen to only use SDL_CDPlayTracks since there are problems
# with the SDL_CDPlay function on some systems.
#

sub play {
	my $self = shift;
	my $start = shift;
	my $length = shift;
	my ($fs,$fl);
	if (@_) { $fs = shift; $fl = shift; } else { $fs = 0; $fl = 0; }
	return SDL::sdlpl::sdl_cd_play_tracks($self->{-cdrom},$start,$length,
			$fs,$fl);
}

#
# pause
#

sub pause {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_pause($self->{-cdrom});
}

#
# resume
#

sub resume {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_resume($self->{-cdrom});
}

#
# stop
#

sub stop {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_stop($self->{-cdrom});
}

#
# eject
#

sub eject {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_eject($self->{-cdrom});
}

#
# id
#

sub id {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_id($self->{-cdrom});
}

#
# numtracks
#

sub num_tracks {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_numtracks($self->{-cdrom});
}

#
# A helper function to convert SDL_CDtrack *
# into something useful
#

my $buildtrack = sub {
	my $ptr = shift;
	my %track = ();
	$track{-id} = SDL::sdlpl::sdl_cd_track_id($ptr);
	$track{-type} = SDL::sdlpl::sdl_cd_track_type($ptr);
	$track{-length} = SDL::sdlpl::sdl_cd_track_length($ptr);
	$track{-offset} = SDL::sdlpl::sdl_cd_track_offset($ptr);
	return \%track;
};


#
# Returns and arbirary track
#

sub track {
	my $self = shift;
	my $number = shift;
	return &$buildtrack(SDL::sdlpl::sdl_cd_track($self->{-cdrom},$number));
}

#
# Returns the current track
#

sub current {
	my $self = shift;
	return $self->track(SDL::sdlpl::sdl_cd_cur_track($self->{-cdrom}));
}

#
# Returns the current frame within the current track 
#

sub current_frame {
	my $self = shift;
	return SDL::sdlpl::sdl_cd_cur_frame($self->{-cdrom});
}

1;

__END__;

=head1 NAME

SDL::Cdrom - a SDL perl extension

=head1 SYNOPSIS

  $cdrom = new SDL::Cdrom 0;

=head1 DESCRIPTION

	
	Cdrom.pm provides software control for CD music.  To open a
CD for playing, ejecting, etc. create a new instance of the Cdrom object,
passing it the number of the drive starting with 0 .. CD_NUM_DRIVES - 1:

	$cdrom = new SDL::Cdrom 0;

The function CD_NUM_DRIVES will return the number of accessible drives
your system currently has.  Once open, you can get the device name
of the drive using the method name:

	$name = $cdrom->name();

=head2 Polling Status

	The method $cdrom->status() differs from the SDL function SDL_CDStatus
in that it returns a string describing the status.  This method returns
the following values:

			playing
			stopped
			paused
			empty
			error

This was done simply to make it easier to present this information to the
end user, in particular programmers debugging their scripts, with little
loss of speed.

=head2 Using the CD

	$cdrom->play(track,number_of_tracks,[frame],[number_of_frames]);
	$cdrom->pause();
	$cdrom->resume();
	$cdrom->stop();
	$cdrom->eject();

The only tricky thing here is that those familiar with the function
SDL_CDPlayTracks should be aware that ntracks and start_frame have
been swapped to make it easier to use, with the frame oriented parameters
being optional.

=head2 Track Data

	To get information on a particular track the method:

	$cdrom->track(index);

will return a hash containing: -id, the track number as one would see
on their cd player, -type, the type of data, -length, size of track
in frames, -offset, the posistion on the CD.

	$cdrom->current();

returns the hash for the current track, and $cdrom->current_frame will
give you the current frame within that track.

	$cdrom->num_tracks();

logically, returns the number of tracks on the cd, and 
	
	$cdrom->id();

returns the id of the cdrom.

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::Mixer(3) SDL::App(3).

=cut
