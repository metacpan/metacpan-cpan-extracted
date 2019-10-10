package MusicBrainz::DiscID;

################
#
# libdiscid: perl bindings
#
# Copyright 2009-2019 Nicholas J. Humfrey <njh@aelius.com>
#

use XSLoader;
use Carp;

use strict;

use vars qw/$VERSION/;

$VERSION="0.06";

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

=back

=head1 SEE ALSO

L<http://musicbrainz.org/doc/libdiscid>

=head1 AUTHOR

Nicholas J. Humfrey <njh@aelius.com>

=head1 COPYRIGHT AND LICENSE

The MIT License (MIT)

Copyright (c) 2009-2019 Nicholas J Humfrey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
