# Hypnotoad example

This is a runnable version of the hypnotoad deployment example in
`Mojolicious::Plugin::Buffer`. It uses CHI's File driver for the response
cache and the built-in file lock backend so multiple workers share both the
cache and the single-flight lock.

## Run it

From the distribution root, with `hypnotoad` and CHI installed:

    MYAPP_LISTEN=http://127.0.0.1:8080 hypnotoad -f examples/hypnotoad/script/my_app

Then request the cached route twice:

    curl -i http://127.0.0.1:8080/expensive
    curl -i http://127.0.0.1:8080/expensive

The first response has `X-Cache: MISS`; the second has `X-Cache: HIT` and the
same "Built at" time.

Stop the foreground server with Ctrl-C, or from another terminal:

    hypnotoad -s examples/hypnotoad/script/my_app

## Paths and port

By default the example keeps its files under `examples/hypnotoad/var` and listens
on port 8080. Override any of these in a deployment-style setup:

- `MYAPP_LISTEN` - listen URL, default `http://*:8080`
- `MYAPP_CACHE_DIR` - CHI File cache directory
- `MYAPP_LOCK_DIR` - shared lock directory
- `MYAPP_PID_FILE` - hypnotoad PID file

For example:

    MYAPP_LISTEN=http://127.0.0.1:9000 \
    MYAPP_CACHE_DIR=/tmp/myapp/cache \
    MYAPP_LOCK_DIR=/tmp/myapp/locks \
    MYAPP_PID_FILE=/tmp/myapp/hypnotoad.pid \
    hypnotoad -f examples/hypnotoad/script/my_app

When stopping a server that used these overrides, pass the same
`MYAPP_PID_FILE`, or send the signal to the PID directly.

The lock backend requires a shared filesystem with working `flock`. For
workers on different hosts, use the Redis lock backend described in the
main documentation instead.

## Testing

`t/85-example.t` starts this example under hypnotoad on an unused port and
checks the MISS then HIT sequence, so the instructions above are exercised by
the test suite. It skips when hypnotoad or CHI is not installed.
