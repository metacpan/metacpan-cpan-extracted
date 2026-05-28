package SignalWire::REST::Namespaces::Video;
use strict;
use warnings;
use Moo;

# --- VideoRooms ---
package SignalWire::REST::Namespaces::Video::Rooms;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';
has '+_update_method' => ( default => sub { 'PUT' } );

sub list_streams {
    my ($self, $room_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($room_id, 'streams'), params => $p);
}

sub create_stream {
    my ($self, $room_id, %kwargs) = @_;
    return $self->_http->post($self->_path($room_id, 'streams'), body => \%kwargs);
}

# --- VideoRoomTokens ---
package SignalWire::REST::Namespaces::Video::RoomTokens;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

# --- VideoRoomSessions ---
package SignalWire::REST::Namespaces::Video::RoomSessions;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $session_id) = @_;
    return $self->_http->get($self->_path($session_id));
}

sub list_events {
    my ($self, $session_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($session_id, 'events'), params => $p);
}

sub list_members {
    my ($self, $session_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($session_id, 'members'), params => $p);
}

sub list_recordings {
    my ($self, $session_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($session_id, 'recordings'), params => $p);
}

# --- VideoRoomRecordings ---
package SignalWire::REST::Namespaces::Video::RoomRecordings;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $recording_id) = @_;
    return $self->_http->get($self->_path($recording_id));
}

sub delete_recording {
    my ($self, $recording_id) = @_;
    return $self->_http->delete_request($self->_path($recording_id));
}

# Python parity alias.
sub delete {
    my ($self, $recording_id) = @_;
    return $self->_http->delete_request($self->_path($recording_id));
}

sub list_events {
    my ($self, $recording_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($recording_id, 'events'), params => $p);
}

# --- VideoConferences ---
package SignalWire::REST::Namespaces::Video::Conferences;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';
has '+_update_method' => ( default => sub { 'PUT' } );

sub list_conference_tokens {
    my ($self, $conference_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($conference_id, 'conference_tokens'), params => $p);
}

sub list_streams {
    my ($self, $conference_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($conference_id, 'streams'), params => $p);
}

sub create_stream {
    my ($self, $conference_id, %kwargs) = @_;
    return $self->_http->post($self->_path($conference_id, 'streams'), body => \%kwargs);
}

# --- VideoConferenceTokens ---
package SignalWire::REST::Namespaces::Video::ConferenceTokens;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub get {
    my ($self, $token_id) = @_;
    return $self->_http->get($self->_path($token_id));
}

sub reset {
    my ($self, $token_id) = @_;
    return $self->_http->post($self->_path($token_id, 'reset'));
}

# --- VideoStreams ---
package SignalWire::REST::Namespaces::Video::Streams;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub get {
    my ($self, $stream_id) = @_;
    return $self->_http->get($self->_path($stream_id));
}

sub update {
    my ($self, $stream_id, %kwargs) = @_;
    return $self->_http->put($self->_path($stream_id), body => \%kwargs);
}

sub delete_stream {
    my ($self, $stream_id) = @_;
    return $self->_http->delete_request($self->_path($stream_id));
}

# Python parity alias.
sub delete {
    my ($self, $stream_id) = @_;
    return $self->_http->delete_request($self->_path($stream_id));
}

# --- VideoNamespace ---
package SignalWire::REST::Namespaces::Video;
use Moo;

has '_http'             => ( is => 'ro', required => 1 );
has 'rooms'             => ( is => 'lazy' );
has 'room_tokens'       => ( is => 'lazy' );
has 'room_sessions'     => ( is => 'lazy' );
has 'room_recordings'   => ( is => 'lazy' );
has 'conferences'       => ( is => 'lazy' );
has 'conference_tokens' => ( is => 'lazy' );
has 'streams'           => ( is => 'lazy' );

my $base = '/api/video';

sub _build_rooms             { SignalWire::REST::Namespaces::Video::Rooms->new(_http => $_[0]->_http, _base_path => "$base/rooms") }
sub _build_room_tokens       { SignalWire::REST::Namespaces::Video::RoomTokens->new(_http => $_[0]->_http, _base_path => "$base/room_tokens") }
sub _build_room_sessions     { SignalWire::REST::Namespaces::Video::RoomSessions->new(_http => $_[0]->_http, _base_path => "$base/room_sessions") }
sub _build_room_recordings   { SignalWire::REST::Namespaces::Video::RoomRecordings->new(_http => $_[0]->_http, _base_path => "$base/room_recordings") }
sub _build_conferences       { SignalWire::REST::Namespaces::Video::Conferences->new(_http => $_[0]->_http, _base_path => "$base/conferences") }
sub _build_conference_tokens { SignalWire::REST::Namespaces::Video::ConferenceTokens->new(_http => $_[0]->_http, _base_path => "$base/conference_tokens") }
sub _build_streams           { SignalWire::REST::Namespaces::Video::Streams->new(_http => $_[0]->_http, _base_path => "$base/streams") }

1;
