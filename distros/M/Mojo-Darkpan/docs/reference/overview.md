# Overview

Mojo::Darkpan (`lib/Mojo/Darkpan.pm`, `$VERSION` 0.09) is a Mojolicious web service that fronts OrePAN2 to run a private CPAN ("DarkPAN") repository. It is distributed as a CPAN dist (Minilla + Module::Build::Tiny).

## Parts

| Part | Role | Path |
|------|------|------|
| App class | Loads plugins, defines routes | `lib/Mojo/Darkpan.pm` |
| Controllers | `Index` (list, reindex), `Publish` (upload) | `lib/Mojo/Darkpan/Controller/` |
| Util | Auth check, publish, index create/update, package listing | `lib/Mojo/Darkpan/Util.pm` |
| Config | Env-var and JSON-file settings | `lib/Mojo/Darkpan/Config.pm` |
| DirectoryHandler | Serves the repository directory under the delivery path | `lib/Mojolicious/Plugin/DirectoryHandler.pm` |
| Launchers | `darkpan` (prefork/morbo), `darkpan_app.pl` (Mojolicious commands) | `script/` |

## What it does

- Accepts distributions via `POST /publish` (file upload or `module` URL/git ref) and injects them into an OrePAN2 repository directory.
- Maintains `modules/02packages.details.txt[.gz]` so `cpanm`, `cpm` and Carton can use the directory as a mirror.
- Serves the directory over HTTP at the delivery path (default `/darkpan`).
- Optional HTTP Basic auth (Mojolicious::Plugin::BasicAuthPlus, e.g. LDAP) on `/list`, `/reindex`, `/publish`, `/authenquery`.

## Deployment

Single process, no database; state is files under the repository directory. `script/darkpan` runs `Mojo::Server::Prefork` (production mode) on `http://*:<port>`, default port 3000. A multi-stage `Dockerfile` builds an image that runs it.
