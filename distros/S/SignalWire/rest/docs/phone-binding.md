# Binding a phone number to a call handler

Routing an inbound phone number to something — an SWML webhook, a cXML app, an AI Agent, a call flow — is configured on the **phone number**, not on the Fabric resource. Fabric resources are *derived representations* of bindings configured on adjacent entities. Read this page before writing code that creates webhook/agent/flow resources manually; for the common cases, you don't need to.

## The mental model

A phone number has a `call_handler` field that chooses what to do with inbound calls. Setting `call_handler` (together with its handler-specific required field) triggers the server to materialize the appropriate Fabric resource automatically.

```
+------------------------+      sets       +--------------------------+
| PUT /phone_numbers/X   |---------------->| call_handler +           |
| (you call this)        |                 | handler-specific URL/ID  |
+------------------------+                 +--------------------------+
                                                        |
                                                        v
                                       +------------------------------+
                                       | Fabric resource materializes |
                                       | automatically, keyed off the |
                                       | URL or ID you supplied       |
                                       +------------------------------+
```

You rarely create a Fabric webhook resource directly. Doing so without binding a phone number to it leaves an orphan.

## The `PhoneCallHandler` constants

The authoritative list of handler values. The SDK ships this as a set of constants in `SignalWire::REST::PhoneCallHandler` so the value doesn't have to be guessed from the OpenAPI spec.

| Constant            | `call_handler` wire value | Required companion field   | Auto-materializes Fabric resource |
|---------------------|---------------------------|----------------------------|-----------------------------------|
| `RELAY_SCRIPT`      | `relay_script`            | `call_relay_script_url`    | `swml_webhook`                    |
| `LAML_WEBHOOKS`     | `laml_webhooks`           | `call_request_url`         | `cxml_webhook`                    |
| `LAML_APPLICATION`  | `laml_application`        | `call_laml_application_id` | `cxml_application`                |
| `AI_AGENT`          | `ai_agent`                | `call_ai_agent_id`         | `ai_agent`                        |
| `CALL_FLOW`         | `call_flow`               | `call_flow_id`             | `call_flow`                       |
| `RELAY_APPLICATION` | `relay_application`       | `call_relay_application`   | `relay_application`               |
| `RELAY_TOPIC`       | `relay_topic`             | `call_relay_topic`         | *(no Fabric resource — routes via RELAY client)* |
| `RELAY_CONTEXT`     | `relay_context`           | `call_relay_context`       | *(no Fabric resource — legacy; prefer `relay_topic`)* |
| `RELAY_CONNECTOR`   | `relay_connector`         | *(connector config)*       | *(internal)*                      |
| `VIDEO_ROOM`        | `video_room`              | `call_video_room_id`       | *(no Fabric resource — routes to Video API)* |
| `DIALOGFLOW`        | `dialogflow`              | `call_dialogflow_agent_id` | *(no Fabric resource)*            |

**Naming note on `laml_webhooks`:** The wire value is plural and contains "webhooks", but it produces a **cXML** (Twilio-compat) handler — not a generic webhook, not an SWML webhook. For SWML, use `RELAY_SCRIPT`. The dashboard labels these resources "cXML Webhook" after assignment.

**`calling_handler_resource_id`** (where present in responses) is **server-derived** and read-only. Don't try to set it on update; the server computes it from the handler you chose.

## Typed helpers on `phone_numbers`

Every port ships a small set of typed helpers that wrap `phone_numbers->update` with the right `call_handler` value and companion field already set. They're the one-line recipe for every common case.

```perl
use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID},
    token   => $ENV{SIGNALWIRE_API_TOKEN},
    host    => $ENV{SIGNALWIRE_SPACE},
);

# SWML webhook (the common case — your backend returns SWML per call)
$client->phone_numbers->set_swml_webhook($pn_id, url => "https://example.com/swml");

# cXML / LAML webhook (Twilio-compat)
$client->phone_numbers->set_cxml_webhook(
    $pn_id,
    url                 => "https://example.com/voice.xml",
    fallback_url        => "https://example.com/fallback.xml",    # optional
    status_callback_url => "https://example.com/status",          # optional
);

# Existing cXML application by ID
$client->phone_numbers->set_cxml_application($pn_id, application_id => "app-uuid");

# AI Agent by ID
$client->phone_numbers->set_ai_agent($pn_id, agent_id => "agent-uuid");

# Call flow (optionally pin a version — default is current_deployed)
$client->phone_numbers->set_call_flow(
    $pn_id,
    flow_id => "flow-uuid",
    version => "current_deployed",
);

# Relay application (named routing)
$client->phone_numbers->set_relay_application($pn_id, name => "my-relay-app");

# Relay topic (RELAY client subscription)
$client->phone_numbers->set_relay_topic($pn_id, topic => "office");
```

All helpers return the updated phone number representation. All are thin wrappers over the single underlying `phone_numbers->update($sid, call_handler => ..., <field> => ...)` call; use the update form directly when you need an unusual combination.

The wire-level form is always available:

```perl
use SignalWire::REST::PhoneCallHandler;

$client->phone_numbers->update(
    $pn_id,
    call_handler          => SignalWire::REST::PhoneCallHandler::RELAY_SCRIPT,
    call_relay_script_url => "https://example.com/swml",
);
```

## What NOT to do

### Don't pre-create the webhook resource

```perl
# WRONG — orphan resource, does nothing
my $webhook = $client->fabric->swml_webhooks->create(
    name                => "my-webhook",
    primary_request_url => "https://example.com/swml",
);
$client->fabric->resources->assign_phone_route(
    $webhook->{id}, phone_number_id => $pn_id,
);
# ^ returns 404 / 422 depending on body shape
```

The `swml_webhooks->create` and `cxml_webhooks->create` endpoints exist historically but are not how you bind a number. The Fabric resource is materialized as a side-effect of `phone_numbers->update`; there's nothing to attach.

### `assign_phone_route` is narrow and deprecated for the common case

`$client->fabric->resources->assign_phone_route(...)` posts to `/api/fabric/resources/{id}/phone_routes`. It applies only to a few legacy resource types that accept phone-route attachment as a separate step. It **does not work** for `swml_webhook`, `cxml_webhook`, or `ai_agent` — those use the derivation model above. It is retained for backwards compatibility but emits a deprecation warning.

## Summary

- Bindings live on `phone_numbers`, not on Fabric resources.
- Set `call_handler` + the one handler-specific field; the server materializes the resource for you.
- Use the typed `phone_numbers->set_*` helpers — they document the constant values inline.
- `swml_webhook` and `cxml_webhook` Fabric resources are auto-materialized. Don't manually create them.
- `laml_webhooks` produces a **cXML** handler despite the name. Use `RELAY_SCRIPT` for SWML.
- `assign_phone_route` is narrow and not needed for the common handlers.
