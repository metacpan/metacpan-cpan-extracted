---
title: The API tier
order: 3
---

# The API tier

The spec is the routing table:

```perl
my $api = under('/api')->api("$home/openapi.json", {
    security => { adminToken => \&Chat::Auth::admin_token },
});

docs '/docs' => $api;
```

Every `operationId` in `openapi.json` resolves to a method under
`Chat::Controller::API` at boot. A typo croaks before the app serves a
request, rather than 404ing on the one call that exercises it.

## Security is wired, not assumed

The spec declares a bearer scheme; the `security` option binds it to a
checker. An operation that requires a scheme with no checker croaks at boot
too, so there is no way to leave the door open by forgetting to close it.

## Posting a message

```sh
curl -sk https://localhost:5443/api/rooms/general/messages \
     -H 'content-type: application/json' \
     -d '{"body":"hello from curl","author":"shell"}'
```

If a browser tab is open on that room, the message appears in it before the
`curl` returns. The controller stores the row and then hands it to the same
`Chat::Bus` room the sockets are subscribed to.

## Reading history

History is keyset paginated, not offset paginated, so a page boundary cannot
skip or repeat a row while messages are arriving:

```sh
curl -sk 'https://localhost:5443/api/rooms/general/messages?limit=20'
curl -sk 'https://localhost:5443/api/rooms/general/messages?limit=20&before=1234'
```

## Two kinds of documentation

`/docs` is the interactive OpenAPI reference, generated from the spec by the
`docs` keyword. The pages you are reading now are at `/guide`, written by hand
and served by the `markdown` keyword. They answer different questions and an
application generally wants both.
