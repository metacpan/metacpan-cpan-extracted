package MusicBrainz::DiscID;

################
#
# libdiscid: perl bindings
#
# Copyright 2009 Nicholas J. Humfrey <njh@aelius.com>
#

use XSLoader;
use Carp;

use strict;

use vars qw/$VERSION/;

$VERSION="0.04";

XSLoader::load('MusicBrainz::DiscID', $VERSION);


sub default_device {
    return MusicBrainz::DiscID::discid_get_default_device();
}

sub new {
    my $class = shift;
    my ($device) = @_;
    
    # Get default device if none given
    if (!defined $device) {
        $device = MusicBrainz::DiscID::discid_get_default_device();
    }
    
    # Bless the hash into an object
    my $self = { device => $device };
    bless $self, $class;
        
    # Create new DiscID instance
    $self->{disc} = MusicBrainz::DiscID::discid_new();
    if (!defined $self->{disc}) {
        carp("Error creating DiscId structure");
        undef $self;
    }

   	return $self;
}

sub first_track_num {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_first_track_num($self->{disc});
}

sub error_msg {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_error_msg($self->{disc});
}

sub freedb_id {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_freedb_id($self->{disc});
}

sub id {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_id($self->{disc});
}

sub last_track_num {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_last_track_num($self->{disc});
}

sub put {
    my $self = shift;
    return MusicBrainz::DiscID::discid_put($self->{disc}, @_);
}

sub read {
    my $self = shift;
    $self->{device} = $_[0] if (defined $_[0]);
    return MusicBrainz::DiscID::discid_read($self->{disc},$self->{device});
}

sub sectors {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_sectors($self->{disc});
}

sub submission_url {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_submission_url($self->{disc});
}

sub track_offset {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_track_offset($self->{disc}, $_[0]);
}

sub track_length {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_track_length($self->{disc}, $_[0]);
}

sub webservice_url {
    my $self = shift;
    return MusicBrainz::DiscID::discid_get_webservice_url($self->{disc});
}

sub DESTROY {
    my $self=shift;
    
    if (defined $self->{disc}) {
        MusicBrainz::DiscID::discid_free( $self->{disc} );
        undef $self->{disc};
    }
}


1;

__END__

=pod

=head1 NAME

MusicBrainz::DiscID - Perl interface for the MusicBrainz libdiscid library

=head1 SYNOPSIS

  use MusicBrainz::DiscID;

  my $discid = MusicBrainz::DiscID->new();
  if ( $disc->read() == 0 ) {
      print STDERR "Error: " . $discid->error_msg() . "\n";
      exit(1);
  }
  print "DiscID: " . $discid->id() . "\n";

=head1 DESCRIPTION

MusicBrainz::DiscID is a class to calculate a MusicBrainz DiscID 
from an audio CD in the drive. The coding style is slightly different to 
the C interface to libdiscid, because it makes use of perl's Object Oriented 
functionality.

=over 4

=item MusicBrainz::DiscID::default_device()

Returns a device string for the default device for this platform.

=item MusicBrainz::DiscID::new( [$device] )

Construct a new DiscID object.

As an optional argument the name of the device to read the ID from may 
be given. If you don't specify a device here you can later read the ID with 
the read method.

=item $discid->error_msg()

Return a human-readable error message of the last error that occured.

=item $discid->first_track_num()

Return the number of the first track on this disc (usually 1).
Returns undef if no ID was yet read.

=item $discid->last_track_num()

Return the number of the last track on this disc.

=item $discid->id()

Returns the DiscID as a string.
Returns undef if no ID was yet read.

=item $discid->last_track_num()

Return the number of the last track on this disc.
Returns undef if no ID was yet read.

=item $discid->put( $first_track, $sectors, $offset1, $offset2, ... )

This function may be used if the TOC has been read earlier and you
want to calculate the disc ID afterwards, without accessing the disc
drive.

=item $discid->read( [$device] )

Read the disc ID from the given device.
If no device is given the default device of the platform will be used.
On error, this function returns false and sets the error message which you 
can access $discid->error_msg().

=item $discid->sectors()

Return the length of the disc in sectors.
Returns undef if no ID was yet read.

=item $discid->submission_url()

Returns a submission URL for the DiscID as a string.
Returns undef if no ID was yet read.

=item $discid->track_length( $track_num )

Return the length of a track in sectors.

=item $discid->track_offset( $track_num )

Return the sector offset of a track.

=item $discid->webservice_url()

Returns a Webservice URL for the DiscID as a string.
Returns undef if no ID was yet read.

=back

=head1 SEE ALSO

L<http://musicbrainz.org/doc/libdiscid>

=head1 AUTHOR

Nicholas J. Humfrey <njh@aelius.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Nicholas J. Humfrey

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
