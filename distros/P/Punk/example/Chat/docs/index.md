# Punk Chat

A small chat application that exercises the things Punk does which are awkward
to show separately, in one app class, over one router, against one table.

This guide is itself part of the example. It is a directory of markdown files
served by the `markdown` keyword, so the page you are reading was rendered at
boot and is being served from frozen bytes.

## What is in here

The [Running it](/guide/running) page gets the app up. After that,
[The live tier](/guide/websockets) covers the WebSocket half and
[The API tier](/guide/api) covers the spec-first half. The
[Configuration](/guide/reference/config) page lists the environment variables.

## The shape of the app

Everything is declared in one class:

```perl
package Chat;
use Punk;

views Stencil => { template_dir => "$home/root/templates" };
static   '/static' => "$home/root/static";
markdown '/guide'  => "$home/docs", title => 'Punk Chat Guide';

get '/'           => 'Web::Chat#index';
websocket '/ws/:room' => 'WS::Chat#join_room';

my $api = under('/api')->api("$home/openapi.json");
docs '/docs' => $api;
```

Note that `docs` and `markdown` are different keywords doing different jobs.
`docs` renders the interactive reference for an OpenAPI mount; `markdown`
renders prose you wrote by hand. An application can have both, as this one
does.

## Why the two halves are wired together

A message POSTed to the API is stored and then broadcast to every socket in
that room, so `curl` into a shell arrives in an open browser tab. That is the
whole point of the example: the API tier and the live tier are not two
applications that happen to share a process.
