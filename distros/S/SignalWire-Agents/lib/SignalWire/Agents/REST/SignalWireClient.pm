package SignalWire::Agents::REST::SignalWireClient;
use strict;
use warnings;
use Moo;

use SignalWire::Agents::REST::HttpClient;
use SignalWire::Agents::REST::Namespaces::Base;
use SignalWire::Agents::REST::Namespaces::Fabric;
use SignalWire::Agents::REST::Namespaces::Calling;
use SignalWire::Agents::REST::Namespaces::PhoneNumbers;
use SignalWire::Agents::REST::Namespaces::Datasphere;
use SignalWire::Agents::REST::Namespaces::Video;
use SignalWire::Agents::REST::Namespaces::Compat;
use SignalWire::Agents::REST::Namespaces::Resources;
use SignalWire::Agents::REST::Namespaces::Registry;
use SignalWire::Agents::REST::Namespaces::Logs;
use SignalWire::Agents::REST::Namespaces::Project;
use SignalWire::Agents::REST::Namespaces::PubSub;
use SignalWire::Agents::REST::Namespaces::Chat;

has 'project' => ( is => 'ro', required => 1 );
has 'token'   => ( is => 'ro', required => 1 );
has 'host'    => ( is => 'ro', required => 1 );

has '_http' => ( is => 'lazy' );

# --- Namespaced sub-objects (all 21) ---

# Fabric API
has 'fabric' => ( is => 'lazy' );

# Calling API
has 'calling' => ( is => 'lazy' );

# Relay REST resources
has 'phone_numbers'    => ( is => 'lazy' );
has 'addresses'        => ( is => 'lazy' );
has 'queues'           => ( is => 'lazy' );
has 'recordings'       => ( is => 'lazy' );
has 'number_groups'    => ( is => 'lazy' );
has 'verified_callers' => ( is => 'lazy' );
has 'sip_profile'      => ( is => 'lazy' );
has 'lookup'           => ( is => 'lazy' );
has 'short_codes'      => ( is => 'lazy' );
has 'imported_numbers' => ( is => 'lazy' );
has 'mfa'              => ( is => 'lazy' );
has 'registry'         => ( is => 'lazy' );

# Datasphere API
has 'datasphere' => ( is => 'lazy' );

# Video API
has 'video' => ( is => 'lazy' );

# Logs
has 'logs' => ( is => 'lazy' );

# Project management
has 'project_ns' => ( is => 'lazy' );

# PubSub & Chat
has 'pubsub' => ( is => 'lazy' );
has 'chat'   => ( is => 'lazy' );

# Compatibility (Twilio-compatible) API
has 'compat' => ( is => 'lazy' );

# --- Builders ---

sub _build__http {
    my ($self) = @_;
    return SignalWire::Agents::REST::HttpClient->new(
        project => $self->project,
        token   => $self->token,
        host    => $self->host,
    );
}

sub _build_fabric {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Fabric->new(_http => $self->_http);
}

sub _build_calling {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Calling->new(
        _http      => $self->_http,
        _base_path => '/api/calling/calls',
    );
}

sub _build_phone_numbers {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::PhoneNumbers->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/phone_numbers',
    );
}

sub _build_addresses {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Addresses->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/addresses',
    );
}

sub _build_queues {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Queues->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/queues',
    );
}

sub _build_recordings {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Recordings->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/recordings',
    );
}

sub _build_number_groups {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::NumberGroups->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/number_groups',
    );
}

sub _build_verified_callers {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::VerifiedCallers->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/verified_caller_ids',
    );
}

sub _build_sip_profile {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::SipProfile->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/sip_profile',
    );
}

sub _build_lookup {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Lookup->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/lookup',
    );
}

sub _build_short_codes {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::ShortCodes->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/short_codes',
    );
}

sub _build_imported_numbers {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::ImportedNumbers->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/imported_phone_numbers',
    );
}

sub _build_mfa {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::MFA->new(
        _http      => $self->_http,
        _base_path => '/api/relay/rest/mfa',
    );
}

sub _build_registry {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Registry->new(_http => $self->_http);
}

sub _build_datasphere {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Datasphere->new(_http => $self->_http);
}

sub _build_video {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Video->new(_http => $self->_http);
}

sub _build_logs {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Logs->new(_http => $self->_http);
}

sub _build_project_ns {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Project->new(_http => $self->_http);
}

sub _build_pubsub {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::PubSub->new(
        _http      => $self->_http,
        _base_path => '/api/pubsub/tokens',
    );
}

sub _build_chat {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Chat->new(
        _http      => $self->_http,
        _base_path => '/api/chat/tokens',
    );
}

sub _build_compat {
    my ($self) = @_;
    return SignalWire::Agents::REST::Namespaces::Compat->new(
        _http       => $self->_http,
        account_sid => $self->project,
    );
}

1;
