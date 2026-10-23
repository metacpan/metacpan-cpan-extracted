# Test landscape

| Kind | Location | Run | Covers |
|------|----------|-----|--------|
| Compile test | `t/00_compile.t` | `prove -l t` | `use_ok Mojo::Darkpan` |
| Route tests (Test::Mojo) | `t/01_routes.t` | `prove -l t` | Delivery of files and listings; traversal attempts return 404; `/list` on an empty repository; `/reindex` runs only when authorized (`createIndex` stubbed); `compress_index: false` in the config file |
| Publish, list and auth tests | `t/02_publish.t` | `prove -l t` | Upload and `module=` publishing, index creation and update, 400 without a module, `/list` `other_versions`, basic auth 401 versus success (username/password mode) |
| Config tests | `t/03_config.t` | `prove -l t` | Defaults, config file values, env-over-file precedence, empty `DARKPAN_COMPRESS_INDEX`, env basic auth, missing and invalid config files |
| DirectoryHandler tests | `t/04_directory_handler.t` | `prove -l t` | Plugin registered directly: file types, spaced names, listings, `auto_index`, `json`, `handler`, `dir_page`, file-as-root, traversal inside the delivery path |

- Test dependencies: `Test::More` 0.98 (`cpanfile`); `Test::Mojo` ships with Mojolicious; `Archive::Tar` is core.
- Not covered: LDAP auth, `git+ssh` and HTTP `module` sources, `script/darkpan`.
- Coverage (Devel::Cover, `^lib`, 2026-10-22): total 95.9% (statements 97.8%, branches 91.1%, conditions 71.7%); `Darkpan.pm`, `Controller/Index.pm` and `Controller/Publish.pm` 100%, `Config.pm` 95%, `DirectoryHandler.pm` 95%, `Util.pm` 90%. Under the earlier `Nice::Try` source filter `Publish.pm` read 41% and the branch total 47.5%. Coverage is not wired into CI.
- CI: `.github/workflows/test.yml` (Perl 5.26, 5.32, 5.38, 5.40, 5.44); not yet run on GitHub.
- Run in the image (host Perl lacks deps on macOS): `podman run --rm -v <repo>:/src:ro -w /src --entrypoint prove mojo-darkpan:test -l t`.
- Last run (2026-10-22): all 5 files, 25 tests pass.
