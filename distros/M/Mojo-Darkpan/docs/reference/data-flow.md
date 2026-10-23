# Data flow

No database. All state is files under the repository directory (`Config->directory`).

## On-disk layout (written by OrePAN2)

| Path | Content |
|------|---------|
| `<dir>/authors/id/<X>/<XX>/<AUTHOR>/<dist>.tar.gz` | Injected distributions |
| `<dir>/modules/02packages.details.txt[.gz]` | Package index; `.gz` unless compression is off |

## Publish (`POST /publish`)

1. `Publish::upload` creates `Util`, calls `authorized`.
2. `Util::publish`: if a `pause99_add_uri_httpupload` upload exists, moves it into a temp dir; else reads the `module` param. No module raises an error, rendered as 400.
3. `OrePAN2::Injector->new(directory, author)->inject($module)` stores the archive and returns its relative path.
4. If the package file exists: `addToIndex` loads it with `OrePAN2::Index`, adds the archive, writes it back. If not: `createIndex`.

## Reindex (`GET /reindex`, or first publish)

`Util::createIndex` runs `OrePAN2::Indexer->make_index` in a `Mojo::IOLoop->subprocess` and logs completion or error. The HTTP response does not wait for it.

## List (`GET /list`)

`Util::list` reads the package file with `IO::Zlib`, builds a hash keyed by archive path (version, archive, dir, `other_versions`, `provides`), and `_getFileList` reads the author directory for sibling files. Rendered as JSON.

## Delivery (`GET /<delivery_path>/...`)

`DirectoryHandler` strips the delivery path from the request path, resolves it under the repository directory, and serves a file, a directory listing, or 404.
