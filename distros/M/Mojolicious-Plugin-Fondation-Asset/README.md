# NAME

Mojolicious::Plugin::Fondation::Asset - AssetPack wrapper -- generate via command, load pre-built def at runtime

# VERSION

version 0.02

# SYNOPSIS

    # myapp.pl asset generate          Generate assets/assetpack.def + process
    # myapp.pl asset generate -y       Force overwrite

# DESCRIPTION

This plugin wraps [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAssetPack). Asset definitions are
collected from all Fondation plugins via the `asset generate` command,
which merges them into `assets/assetpack.def` and processes the bundles.

During the merge, `<<` (fetch) directives for remote URLs (`https?://`)
are normalized to single `<`. This prevents AssetPack from marking
remote assets as Null (which would exclude them from rendering in development
mode). Local assets keep their original `<` operator.

At runtime (`fondation_finalyze`), AssetPack is loaded only if the merged
`assetpack.def` exists. If missing, a warning is logged and startup
continues -- run `asset generate` first. If the def exists, AssetPack is
loaded, plugin public directories are registered as store paths, and
`process()` is called to register all asset topics. This second
`process()` call skips already-cached external files.

# CONFIGURATION

    # myapp.conf
    {
        Fondation => {
            dependencies => ['Fondation::Asset'],
        },
    }

The plugin registers its CLI command namespace (`asset generate`) in
`register()` and sets up AssetPack at runtime in `fondation_finalyze`.

# COMMANDS

## asset generate

Scans all Fondation plugins for `share/assets/assetpack.def`, merges them,
writes `assets/assetpack.def`, and processes assets through AssetPack.

Options: `-y` (overwrite without prompt).

# RUNTIME

On startup (`fondation_finalyze`), if `assets/assetpack.def` exists,
AssetPack is loaded, plugin public directories are registered, and
`process()` is called to register all asset topics for template helpers.
External files already cached by `asset generate` are not re-downloaded.

If the def is missing, a warning is logged and startup continues -- run
`asset generate` first.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
