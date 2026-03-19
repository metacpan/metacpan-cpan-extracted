package SignalWire::Agents::REST::Namespaces::Logs;
use strict;
use warnings;
use Moo;

# --- MessageLogs ---
package SignalWire::Agents::REST::Namespaces::Logs::Messages;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $log_id) = @_;
    return $self->_http->get($self->_path($log_id));
}

# --- VoiceLogs ---
package SignalWire::Agents::REST::Namespaces::Logs::Voice;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $log_id) = @_;
    return $self->_http->get($self->_path($log_id));
}

sub list_events {
    my ($self, $log_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($log_id, 'events'), params => $p);
}

# --- FaxLogs ---
package SignalWire::Agents::REST::Namespaces::Logs::Fax;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $log_id) = @_;
    return $self->_http->get($self->_path($log_id));
}

# --- ConferenceLogs ---
package SignalWire::Agents::REST::Namespaces::Logs::Conferences;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

# --- LogsNamespace ---
package SignalWire::Agents::REST::Namespaces::Logs;
use Moo;

has '_http'       => ( is => 'ro', required => 1 );
has 'messages'    => ( is => 'lazy' );
has 'voice'       => ( is => 'lazy' );
has 'fax'         => ( is => 'lazy' );
has 'conferences' => ( is => 'lazy' );

sub _build_messages    { SignalWire::Agents::REST::Namespaces::Logs::Messages->new(_http => $_[0]->_http, _base_path => '/api/messaging/logs') }
sub _build_voice       { SignalWire::Agents::REST::Namespaces::Logs::Voice->new(_http => $_[0]->_http, _base_path => '/api/voice/logs') }
sub _build_fax         { SignalWire::Agents::REST::Namespaces::Logs::Fax->new(_http => $_[0]->_http, _base_path => '/api/fax/logs') }
sub _build_conferences { SignalWire::Agents::REST::Namespaces::Logs::Conferences->new(_http => $_[0]->_http, _base_path => '/api/logs/conferences') }

1;
