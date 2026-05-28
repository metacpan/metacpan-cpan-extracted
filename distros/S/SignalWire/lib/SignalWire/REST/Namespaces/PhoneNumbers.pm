package SignalWire::REST::Namespaces::PhoneNumbers;
use strict;
use warnings;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';

use SignalWire::REST::PhoneCallHandler;

has '+_update_method' => ( default => sub { 'PUT' } );

sub search {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path('search'), params => $p);
}

# --- Typed binding helpers -------------------------------------------------
#
# Each helper is a one-line wrapper over `update` with the right
# `call_handler` value and companion field already set. Extra key/value
# pairs are passed through for cases the helper doesn't name explicitly
# (e.g. you can pass `name => "..."` on any of them).

sub set_swml_webhook {
    my ($self, $resource_id, %args) = @_;
    my $url = delete $args{url}
        or die "set_swml_webhook: 'url' is required";
    return $self->update(
        $resource_id,
        call_handler          => SignalWire::REST::PhoneCallHandler::RELAY_SCRIPT,
        call_relay_script_url => $url,
        %args,
    );
}

sub set_cxml_webhook {
    my ($self, $resource_id, %args) = @_;
    my $url = delete $args{url}
        or die "set_cxml_webhook: 'url' is required";
    my $fallback_url = delete $args{fallback_url};
    my $status_callback_url = delete $args{status_callback_url};

    my %body = (
        call_handler     => SignalWire::REST::PhoneCallHandler::LAML_WEBHOOKS,
        call_request_url => $url,
    );
    $body{call_fallback_url}        = $fallback_url        if defined $fallback_url;
    $body{call_status_callback_url} = $status_callback_url if defined $status_callback_url;

    return $self->update($resource_id, %body, %args);
}

sub set_cxml_application {
    my ($self, $resource_id, %args) = @_;
    my $application_id = delete $args{application_id}
        or die "set_cxml_application: 'application_id' is required";
    return $self->update(
        $resource_id,
        call_handler             => SignalWire::REST::PhoneCallHandler::LAML_APPLICATION,
        call_laml_application_id => $application_id,
        %args,
    );
}

sub set_ai_agent {
    my ($self, $resource_id, %args) = @_;
    my $agent_id = delete $args{agent_id}
        or die "set_ai_agent: 'agent_id' is required";
    return $self->update(
        $resource_id,
        call_handler     => SignalWire::REST::PhoneCallHandler::AI_AGENT,
        call_ai_agent_id => $agent_id,
        %args,
    );
}

sub set_call_flow {
    my ($self, $resource_id, %args) = @_;
    my $flow_id = delete $args{flow_id}
        or die "set_call_flow: 'flow_id' is required";
    my $version = delete $args{version};

    my %body = (
        call_handler => SignalWire::REST::PhoneCallHandler::CALL_FLOW,
        call_flow_id => $flow_id,
    );
    $body{call_flow_version} = $version if defined $version;

    return $self->update($resource_id, %body, %args);
}

sub set_relay_application {
    my ($self, $resource_id, %args) = @_;
    my $name = delete $args{name}
        or die "set_relay_application: 'name' is required";
    return $self->update(
        $resource_id,
        call_handler           => SignalWire::REST::PhoneCallHandler::RELAY_APPLICATION,
        call_relay_application => $name,
        %args,
    );
}

sub set_relay_topic {
    my ($self, $resource_id, %args) = @_;
    my $topic = delete $args{topic}
        or die "set_relay_topic: 'topic' is required";
    my $status_callback_url = delete $args{status_callback_url};

    my %body = (
        call_handler     => SignalWire::REST::PhoneCallHandler::RELAY_TOPIC,
        call_relay_topic => $topic,
    );
    $body{call_relay_topic_status_callback_url} = $status_callback_url
        if defined $status_callback_url;

    return $self->update($resource_id, %body, %args);
}

1;

__END__

=head1 NAME

SignalWire::REST::Namespaces::PhoneNumbers - Phone number management

=head1 DESCRIPTION

Supports the standard CRUD surface plus typed helpers for binding an
inbound call to a handler (SWML webhook, cXML webhook, AI agent, call
flow, RELAY application/topic). The binding model is: set C<call_handler>
plus the handler-specific companion field on the phone number; the
server auto-materializes the matching Fabric resource. See
L<SignalWire::REST::PhoneCallHandler> for the enum.

=head1 HELPERS

=over 4

=item set_swml_webhook($sid, url => $url)

Route inbound calls to an SWML webhook URL. Your backend returns an
SWML document per call. The server auto-creates a C<swml_webhook>
Fabric resource keyed off this URL.

=item set_cxml_webhook($sid, url => $url, fallback_url => $f?, status_callback_url => $s?)

Route inbound calls to a cXML (Twilio-compat / LAML) webhook. Despite
the wire value C<laml_webhooks> being plural, this creates a single
C<cxml_webhook> Fabric resource.

=item set_cxml_application($sid, application_id => $id)

Route inbound calls to an existing cXML application by ID.

=item set_ai_agent($sid, agent_id => $id)

Route inbound calls to an AI Agent Fabric resource by ID.

=item set_call_flow($sid, flow_id => $id, version => $v?)

Route inbound calls to a Call Flow by ID. C<version> accepts
C<working_copy> or C<current_deployed> (server default when omitted).

=item set_relay_application($sid, name => $name)

Route inbound calls to a named RELAY application.

=item set_relay_topic($sid, topic => $topic, status_callback_url => $s?)

Route inbound calls to a RELAY topic (client subscription).

=back

=cut
