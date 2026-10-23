# Entry points

## HTTP routes (`lib/Mojo/Darkpan.pm`)

| Method | Path | Handler | Auth check | Behaviour |
|--------|------|---------|------------|-----------|
| GET | `/list` | `Controller::Index::list` (`Index.pm:10`) | `Util->authorized` | JSON of packages, `provides`, and `other_versions` |
| GET | `/reindex` | `Controller::Index::reindex` (`Index.pm:15`) | `Util->authorized`, checked before `createIndex` | Starts a subprocess reindex, returns text |
| POST | `/publish` | `Controller::Publish::upload` | `Util->authorized` | Injects a distribution, updates the index |
| POST | `/authenquery` | same as `/publish` | same | Compatibility alias |
| GET | `/<delivery_path>/**` (default `/darkpan`) | `DirectoryHandler` hook | none | Files and directory listings of the repository directory; paths containing `..` return 404 |

Accepted `/publish` parameters: multipart file `pause99_add_uri_httpupload`; or `module` (git/http/file ref); `author` or `HIDDENNAME` (uppercased, default `DUMMY`).

## CLIs

| Command | Path | Options |
|---------|------|---------|
| `darkpan` | `script/darkpan` | `--config <file>`, `--port <n>` (default 3000), `--devmode` |
| `darkpan_app.pl` | `script/darkpan_app.pl` | Mojolicious command line (`daemon`, `prefork`, ...) |

## Configuration inputs (`lib/Mojo/Darkpan/Config.pm`)

| Setting | Env var | JSON key | Default |
|---------|---------|----------|---------|
| Config file | `DARKPAN_CONFIG_FILE` | n/a | none |
| Repository directory | `DARKPAN_DIRECTORY` | `directory` | `darkpan` (resolved against cwd) |
| Delivery path | `DARKPAN_PATH` | `path` | `darkpan` |
| Compress index | `DARKPAN_COMPRESS_INDEX` | `compress_index` | on |
| Basic auth | `DARKPAN_AUTH_REALM` plus `DARKPAN_AUTH_<setting>` | `basic_auth` (first realm key) | off |

Env vars take precedence over the JSON file.
