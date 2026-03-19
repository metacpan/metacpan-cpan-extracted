package SignalWire::Agents::REST::Namespaces::Compat;
use strict;
use warnings;
use Moo;

# --- CompatAccounts ---
package SignalWire::Agents::REST::Namespaces::Compat::Accounts;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub get {
    my ($self, $sid) = @_;
    return $self->_http->get($self->_path($sid));
}

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

# --- CompatCalls ---
package SignalWire::Agents::REST::Namespaces::Compat::Calls;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub start_recording {
    my ($self, $call_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($call_sid, 'Recordings'), body => \%kwargs);
}

sub update_recording {
    my ($self, $call_sid, $recording_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($call_sid, 'Recordings', $recording_sid), body => \%kwargs);
}

sub start_stream {
    my ($self, $call_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($call_sid, 'Streams'), body => \%kwargs);
}

sub stop_stream {
    my ($self, $call_sid, $stream_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($call_sid, 'Streams', $stream_sid), body => \%kwargs);
}

# --- CompatMessages ---
package SignalWire::Agents::REST::Namespaces::Compat::Messages;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub list_media {
    my ($self, $message_sid, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($message_sid, 'Media'), params => $p);
}

sub get_media {
    my ($self, $message_sid, $media_sid) = @_;
    return $self->_http->get($self->_path($message_sid, 'Media', $media_sid));
}

sub delete_media {
    my ($self, $message_sid, $media_sid) = @_;
    return $self->_http->delete_request($self->_path($message_sid, 'Media', $media_sid));
}

# --- CompatFaxes ---
package SignalWire::Agents::REST::Namespaces::Compat::Faxes;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub list_media {
    my ($self, $fax_sid, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($fax_sid, 'Media'), params => $p);
}

sub get_media {
    my ($self, $fax_sid, $media_sid) = @_;
    return $self->_http->get($self->_path($fax_sid, 'Media', $media_sid));
}

sub delete_media {
    my ($self, $fax_sid, $media_sid) = @_;
    return $self->_http->delete_request($self->_path($fax_sid, 'Media', $media_sid));
}

# --- CompatConferences ---
package SignalWire::Agents::REST::Namespaces::Compat::Conferences;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $sid) = @_;
    return $self->_http->get($self->_path($sid));
}

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub list_participants {
    my ($self, $conference_sid, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($conference_sid, 'Participants'), params => $p);
}

sub get_participant {
    my ($self, $conference_sid, $call_sid) = @_;
    return $self->_http->get($self->_path($conference_sid, 'Participants', $call_sid));
}

sub update_participant {
    my ($self, $conference_sid, $call_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($conference_sid, 'Participants', $call_sid), body => \%kwargs);
}

sub remove_participant {
    my ($self, $conference_sid, $call_sid) = @_;
    return $self->_http->delete_request($self->_path($conference_sid, 'Participants', $call_sid));
}

sub list_recordings {
    my ($self, $conference_sid, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($conference_sid, 'Recordings'), params => $p);
}

sub get_recording {
    my ($self, $conference_sid, $recording_sid) = @_;
    return $self->_http->get($self->_path($conference_sid, 'Recordings', $recording_sid));
}

sub update_recording {
    my ($self, $conference_sid, $recording_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($conference_sid, 'Recordings', $recording_sid), body => \%kwargs);
}

sub delete_recording {
    my ($self, $conference_sid, $recording_sid) = @_;
    return $self->_http->delete_request($self->_path($conference_sid, 'Recordings', $recording_sid));
}

sub start_stream {
    my ($self, $conference_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($conference_sid, 'Streams'), body => \%kwargs);
}

sub stop_stream {
    my ($self, $conference_sid, $stream_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($conference_sid, 'Streams', $stream_sid), body => \%kwargs);
}

# --- CompatPhoneNumbers ---
package SignalWire::Agents::REST::Namespaces::Compat::PhoneNumbers;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

has '_available_base' => ( is => 'lazy' );

sub _build__available_base {
    my ($self) = @_;
    (my $path = $self->_base_path) =~ s/IncomingPhoneNumbers/AvailablePhoneNumbers/;
    return $path;
}

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub purchase {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub get {
    my ($self, $sid) = @_;
    return $self->_http->get($self->_path($sid));
}

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub delete_number {
    my ($self, $sid) = @_;
    return $self->_http->delete_request($self->_path($sid));
}

sub import_number {
    my ($self, %kwargs) = @_;
    (my $path = $self->_base_path) =~ s/IncomingPhoneNumbers/ImportedPhoneNumbers/;
    return $self->_http->post($path, body => \%kwargs);
}

sub list_available_countries {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_available_base, params => $p);
}

sub search_local {
    my ($self, $country, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_available_base . "/$country/Local", params => $p);
}

sub search_toll_free {
    my ($self, $country, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_available_base . "/$country/TollFree", params => $p);
}

# --- CompatApplications ---
package SignalWire::Agents::REST::Namespaces::Compat::Applications;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

# --- CompatLamlBins ---
package SignalWire::Agents::REST::Namespaces::Compat::LamlBins;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

# --- CompatQueues ---
package SignalWire::Agents::REST::Namespaces::Compat::Queues;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub update {
    my ($self, $sid, %kwargs) = @_;
    return $self->_http->post($self->_path($sid), body => \%kwargs);
}

sub list_members {
    my ($self, $queue_sid, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($queue_sid, 'Members'), params => $p);
}

sub get_member {
    my ($self, $queue_sid, $call_sid) = @_;
    return $self->_http->get($self->_path($queue_sid, 'Members', $call_sid));
}

sub dequeue_member {
    my ($self, $queue_sid, $call_sid, %kwargs) = @_;
    return $self->_http->post($self->_path($queue_sid, 'Members', $call_sid), body => \%kwargs);
}

# --- CompatRecordings ---
package SignalWire::Agents::REST::Namespaces::Compat::Recordings;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $sid) = @_;
    return $self->_http->get($self->_path($sid));
}

sub delete_recording {
    my ($self, $sid) = @_;
    return $self->_http->delete_request($self->_path($sid));
}

# --- CompatTranscriptions ---
package SignalWire::Agents::REST::Namespaces::Compat::Transcriptions;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $sid) = @_;
    return $self->_http->get($self->_path($sid));
}

sub delete_transcription {
    my ($self, $sid) = @_;
    return $self->_http->delete_request($self->_path($sid));
}

# --- CompatTokens ---
package SignalWire::Agents::REST::Namespaces::Compat::Tokens;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub update {
    my ($self, $token_id, %kwargs) = @_;
    return $self->_http->patch($self->_path($token_id), body => \%kwargs);
}

sub delete_token {
    my ($self, $token_id) = @_;
    return $self->_http->delete_request($self->_path($token_id));
}

# --- CompatNamespace ---
package SignalWire::Agents::REST::Namespaces::Compat;
use Moo;

has '_http'        => ( is => 'ro', required => 1 );
has 'account_sid'  => ( is => 'ro', required => 1 );

has 'accounts'       => ( is => 'lazy' );
has 'calls'          => ( is => 'lazy' );
has 'messages'       => ( is => 'lazy' );
has 'faxes'          => ( is => 'lazy' );
has 'conferences'    => ( is => 'lazy' );
has 'phone_numbers'  => ( is => 'lazy' );
has 'applications'   => ( is => 'lazy' );
has 'laml_bins'      => ( is => 'lazy' );
has 'queues'         => ( is => 'lazy' );
has 'recordings'     => ( is => 'lazy' );
has 'transcriptions' => ( is => 'lazy' );
has 'tokens'         => ( is => 'lazy' );

sub _base {
    my ($self) = @_;
    return '/api/laml/2010-04-01/Accounts/' . $self->account_sid;
}

sub _build_accounts       { SignalWire::Agents::REST::Namespaces::Compat::Accounts->new(_http => $_[0]->_http, _base_path => '/api/laml/2010-04-01/Accounts') }
sub _build_calls          { SignalWire::Agents::REST::Namespaces::Compat::Calls->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Calls') }
sub _build_messages       { SignalWire::Agents::REST::Namespaces::Compat::Messages->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Messages') }
sub _build_faxes          { SignalWire::Agents::REST::Namespaces::Compat::Faxes->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Faxes') }
sub _build_conferences    { SignalWire::Agents::REST::Namespaces::Compat::Conferences->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Conferences') }
sub _build_phone_numbers  { SignalWire::Agents::REST::Namespaces::Compat::PhoneNumbers->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/IncomingPhoneNumbers') }
sub _build_applications   { SignalWire::Agents::REST::Namespaces::Compat::Applications->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Applications') }
sub _build_laml_bins      { SignalWire::Agents::REST::Namespaces::Compat::LamlBins->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/LamlBins') }
sub _build_queues         { SignalWire::Agents::REST::Namespaces::Compat::Queues->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Queues') }
sub _build_recordings     { SignalWire::Agents::REST::Namespaces::Compat::Recordings->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Recordings') }
sub _build_transcriptions { SignalWire::Agents::REST::Namespaces::Compat::Transcriptions->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/Transcriptions') }
sub _build_tokens         { SignalWire::Agents::REST::Namespaces::Compat::Tokens->new(_http => $_[0]->_http, _base_path => $_[0]->_base . '/tokens') }

1;
