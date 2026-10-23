# Domains

No `CONTEXT.md` or `CONTEXT-MAP.md` exists yet; the repo is small enough to be one area.

| Domain | Code | Context |
|--------|------|---------|
| Publishing (inject a distribution, update the index) | `lib/Mojo/Darkpan/Controller/Publish.pm`, `Util.pm` (`publish`, `addToIndex`) | none |
| Indexing (`02packages.details`) | `lib/Mojo/Darkpan/Util.pm` (`createIndex`, `packageFile`, `indexer`) | none |
| Listing | `lib/Mojo/Darkpan/Util.pm` (`list`, `_getFileList`), `Controller/Index.pm` | none |
| Repository delivery | `lib/Mojolicious/Plugin/DirectoryHandler.pm` | none |
| Configuration | `lib/Mojo/Darkpan/Config.pm` | none |
| Authentication | `lib/Mojo/Darkpan/Util.pm` (`authorized`), `Config.pm` (`basic_auth`) | none |

## Term gaps

Words the code uses with no defined term; candidates for `name-it`:

- **darkpan**: names the repository directory, the delivery URL path, the app and the CLI.
- **author**: a PAUSE-style id (uppercased) under which a distribution is stored, `authors/id/...`.
- **archive**: the distribution tarball path returned by `OrePAN2::Injector->inject`.
- **delivery path**: the `path` setting and `delivery_path` plugin argument.
- **other_versions**: files in the same author directory whose names share the package prefix.
