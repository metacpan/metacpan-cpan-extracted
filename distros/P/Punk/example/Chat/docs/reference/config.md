# Configuration

Everything the example needs has a working default, so it runs with no
configuration at all. These are the knobs if you want them.

## Environment

| Variable | Default | What it does |
| --- | --- | --- |
| `PUNK_CHAT_DSN` | `dbi:SQLite:dbname=chat.db` | Where messages are stored |
| `PUNK_CHAT_ADMIN_TOKEN` | unset | The bearer token the API's admin operations accept |
| `PUNK_CHAT_PORT` | `5443` | The TLS listener port |

With no `PUNK_CHAT_ADMIN_TOKEN` set, the admin operations refuse everything.
That is the intended default: an example that ships with a working admin
credential is an example that ends up deployed.

## Swapping the database

The model tier is backed by whatever DSN it is given, so PostgreSQL works
without touching the model:

```sh
PUNK_CHAT_DSN='dbi:Pg:dbname=chat;host=localhost' ./bin/punk-chat
```

`Chat::Schema` creates the table on first run if it is not there.

## The markdown mount

The guide you are reading is declared in `lib/Chat.pm`:

```perl
markdown '/guide' => "$home/docs",
    title  => 'Punk Chat Guide',
    reload => $ENV{PUNK_CHAT_DEV} ? 1 : 0;
```

Pages are rendered once at boot and served from frozen bytes. With
`PUNK_CHAT_DEV=1` the mount re-stats each page on request and re-renders it
when the file has changed, which is what you want while writing docs and not
what you want in production.
