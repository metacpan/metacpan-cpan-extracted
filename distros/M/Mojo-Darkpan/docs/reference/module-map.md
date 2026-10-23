# Module map

| Module | Path | Responsibility | Depends on | Used by |
|--------|------|----------------|------------|---------|
| Mojo::Darkpan | `lib/Mojo/Darkpan.pm` | App startup: registers `basic_auth_plus` and `DirectoryHandler` plugins, declares routes; holds the user POD | Config, DirectoryHandler, Mojolicious | `script/darkpan`, `script/darkpan_app.pl`, `t/00_compile.t` |
| Controller::Index | `lib/Mojo/Darkpan/Controller/Index.pm` | `list` renders package JSON; `reindex` starts a reindex | Util | Router (`/list`, `/reindex`) |
| Controller::Publish | `lib/Mojo/Darkpan/Controller/Publish.pm` | `upload` runs `Util->publish`, returns `OK` or a 400 with the error message | Util, Syntax::Keyword::Try | Router (`/publish`, `/authenquery`) |
| Util | `lib/Mojo/Darkpan/Util.pm` | Moo class: `authorized`, `publish`, `addToIndex`, `createIndex` (subprocess), `list`, `_getFileList`, lazy builders for upload, author, indexer, config, packageFile | Config, OrePAN2 (Injector, Indexer, Index), IO::Zlib, Mojo::IOLoop | Both controllers |
| Config | `lib/Mojo/Darkpan/Config.pm` | Moo class: resolves `directory`, `path`, `compressIndex`, `basic_auth` from `DARKPAN_*` env vars, then the JSON file at `DARKPAN_CONFIG_FILE`, then defaults | JSON, Mojo::File | App class, Util, DirectoryHandler |
| DirectoryHandler | `lib/Mojolicious/Plugin/DirectoryHandler.pm` | `before_dispatch` hook: maps `/<delivery_path>/...` to files under the repository directory; renders file, directory listing (HTML, optional JSON) or 404 | Config, Mojolicious types | App class |
| darkpan | `script/darkpan` | CLI: `--config`, `--port`, `--devmode`; sets `DARKPAN_CONFIG_FILE`, starts Prefork or `morbo` | Mojo::Darkpan | Docker `CMD`, users |
| darkpan_app.pl | `script/darkpan_app.pl` | Starts the app via `Mojolicious::Commands` | Mojo::Darkpan | `script/darkpan --devmode` (morbo) |

## Dependency direction

```
script/* -> Mojo::Darkpan -> Controller::{Index,Publish} -> Util -> Config
                          \-> DirectoryHandler -> Config
```
