# Punk::OpenTelemetry example: an app, and something to watch it

Two servers. One is an ordinary Punk application with the plugin turned on;
the other is a collector that accepts what the exporter sends and prints it to
STDERR as a trace tree, so you can watch telemetry arrive rather than take a
vendor's word for it.

- `app.psgi` - the instrumented application
- `collector.psgi` - OTLP/HTTP in, readable spans out

## Run it

Two terminals, from the distribution root.

The collector, on the port the OTLP spec uses for HTTP:

```
plackup -s Hyperman -p 4318 example/collector.psgi
```

The application, pointed at it:

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 \
OTEL_EXPORTER_OTLP_PROTOCOL=http/json \
OTEL_BSP_SCHEDULE_DELAY=1000 \
  plackup -s Hyperman -p 5000 example/app.psgi
```

Then make some requests:

```
curl localhost:5000/hello/world
curl localhost:5000/work          # calls out, so you get a client span too
curl localhost:5000/slow
curl localhost:5000/boom          # dies on purpose; the span still arrives
```

Within a second or so the collector prints what it received:

```
=== punk-otel-example  instance=c89d9f58  schema=https://opentelemetry.io/schemas/1.30.0
  scope: Punk::OpenTelemetry 0.01
    GET /hello/:name             server      4.17ms  trace=0726f412 span=52eb67ff
        client.address = 127.0.0.1
        http.request.method = GET
        http.response.status_code = 200
        http.route = /hello/:name
        url.path = /hello/world
      greet                      internal    0.04ms  trace=0726f412 span=6c4d6ed5
        greeting.name = world
        * composed
```

## The three environment variables

`OTEL_EXPORTER_OTLP_PROTOCOL=http/json` is what makes the collector readable.
JSON is three to five times larger on the wire than the protobuf default, so
it is the demo's choice and not the deployment's - which is the reason the
JSON transport exists at all: you can read it in a bug report.

`OTEL_BSP_SCHEDULE_DELAY=1000` drops the batch delay to a second, so the demo
does not look broken while you wait out the five-second default.

`OTEL_EXPORTER_OTLP_ENDPOINT` is left to the environment on purpose. The
application declares its service name in code, where it belongs, and takes its
destination from the deployment, where that belongs. Point it at a real
collector or a vendor and nothing in `app.psgi` changes.

## What the application does not contain

Any export code. The plugin builds the tracer and the exporter and schedules
the drain between them; the application says `plugin 'OpenTelemetry'` and then
writes routes. That is the point of the plugin, and the part most easily got
wrong by hand - a drain on the tail of a response ships every server span one
request late, because the server span is ended by the response observer that
runs after `after_dispatch`.

## Turning it off

```
OTEL_SDK_DISABLED=true plackup -s Hyperman -p 5000 example/app.psgi
```

No tracer, no exporter, nothing installed into the request path. The boot line
says so, which is the one thing you want to see when you have just switched
telemetry off at three in the morning and need to know whether it took.

## This is a demonstration

The collector accepts everything, stores nothing and authenticates nobody.
It exists to make the wire format visible.
