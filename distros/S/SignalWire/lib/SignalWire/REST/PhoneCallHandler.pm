package SignalWire::REST::PhoneCallHandler;
use strict;
use warnings;

# PhoneCallHandler - enum of `call_handler` values accepted by phone_numbers->update.
#
# Named `PhoneCallHandler` (not `CallHandler`) to stay consistent with the other
# SignalWire ports and to avoid colliding with any RELAY client callback type.
#
# Setting a phone number's `call_handler` + the handler-specific companion
# field routes inbound calls and auto-materializes the matching Fabric
# resource on the server. See the high-level helpers on
# SignalWire::REST::Namespaces::PhoneNumbers.
#
# Each constant is a plain scalar, so passing the constant directly into
# phone_numbers->update(..., call_handler => PhoneCallHandler::RELAY_SCRIPT)
# serializes to the wire value without any indirection.
#
#   Constant             Wire value            Companion field            Auto-materializes
#   -------------------- --------------------- -------------------------- --------------------
#   RELAY_SCRIPT         relay_script          call_relay_script_url      swml_webhook
#   LAML_WEBHOOKS        laml_webhooks         call_request_url           cxml_webhook
#   LAML_APPLICATION     laml_application      call_laml_application_id   cxml_application
#   AI_AGENT             ai_agent              call_ai_agent_id           ai_agent
#   CALL_FLOW            call_flow             call_flow_id               call_flow
#   RELAY_APPLICATION    relay_application     call_relay_application     relay_application
#   RELAY_TOPIC          relay_topic           call_relay_topic           (routes via RELAY)
#   RELAY_CONTEXT        relay_context         call_relay_context         (legacy, prefer topic)
#   RELAY_CONNECTOR      relay_connector       (connector config)         (internal)
#   VIDEO_ROOM           video_room            call_video_room_id         (routes to Video API)
#   DIALOGFLOW           dialogflow            call_dialogflow_agent_id   (none)
#
# Note: LAML_WEBHOOKS (wire value "laml_webhooks") produces a cXML handler,
# not a generic webhook. For SWML, use RELAY_SCRIPT.

use Exporter 'import';

use constant {
    RELAY_SCRIPT      => 'relay_script',
    LAML_WEBHOOKS     => 'laml_webhooks',
    LAML_APPLICATION  => 'laml_application',
    AI_AGENT          => 'ai_agent',
    CALL_FLOW         => 'call_flow',
    RELAY_APPLICATION => 'relay_application',
    RELAY_TOPIC       => 'relay_topic',
    RELAY_CONTEXT     => 'relay_context',
    RELAY_CONNECTOR   => 'relay_connector',
    VIDEO_ROOM        => 'video_room',
    DIALOGFLOW        => 'dialogflow',
};

our @EXPORT_OK = qw(
    RELAY_SCRIPT
    LAML_WEBHOOKS
    LAML_APPLICATION
    AI_AGENT
    CALL_FLOW
    RELAY_APPLICATION
    RELAY_TOPIC
    RELAY_CONTEXT
    RELAY_CONNECTOR
    VIDEO_ROOM
    DIALOGFLOW
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# values() - return all 11 wire values (authoritative list).
sub values {
    return (
        RELAY_SCRIPT,
        LAML_WEBHOOKS,
        LAML_APPLICATION,
        AI_AGENT,
        CALL_FLOW,
        RELAY_APPLICATION,
        RELAY_TOPIC,
        RELAY_CONTEXT,
        RELAY_CONNECTOR,
        VIDEO_ROOM,
        DIALOGFLOW,
    );
}

1;
