# External systems

Names only; no values.

| System | Used by | Configured by |
|--------|---------|---------------|
| OrePAN2 (`Injector`, `Indexer`, `Index`) | `lib/Mojo/Darkpan/Util.pm` | `directory` setting |
| LDAP / auth backend via Mojolicious::Plugin::BasicAuthPlus | `Util::authorized`, `Darkpan.pm` plugin load | `DARKPAN_AUTH_REALM`, `DARKPAN_AUTH_*`, or `basic_auth` in the JSON config (host, port, basedn, binddn, bindpw, filter) |
| git (`git+ssh://`, `git+file://`, `git@host:...`) | OrePAN2 Injector when `module` is a git ref | `git` and `openssh-client` installed in the image |
| HTTP sources for `module=<url>` | OrePAN2 Injector | request parameter |
| CPAN clients (`cpanm`, `cpm`, Carton, `cpan-upload`/Minilla) | Consumers of `/darkpan`, `/publish` | Client-side config (`.pause`, mirror env vars); see issue #4 on `upload_uri` |
