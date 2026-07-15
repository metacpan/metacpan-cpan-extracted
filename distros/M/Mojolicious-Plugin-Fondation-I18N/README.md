# SYNOPSIS

    # myapp.conf
    {
        Fondation => {
            dependencies => ['Fondation::I18N'],
        },
    }

    # In templates
    %= l('Welcome')
    <a href="/"><%= l 'Home' %></a>

    # In JavaScript (after %= i18n_js in layout)
    successBox(l("User saved successfully"));

# DESCRIPTION

This plugin provides real dictionary-based translation for Fondation
applications, overriding the identity fallback helpers (`l` and `i18n_js`)
from Fondation core.

## How it works

A post-load action (declared via `provides_actions => ['I18N']`) scans
every plugin's `share/translations/<lang>.json` at startup and merges
them into a single lexicon per language. The merged lexicons are stored on
`$app` and exposed via the `i18n_lexicons` helper.

At request time, a `before_dispatch` hook detects the user's language
(from URL prefix or `Accept-Language` header) and caches the appropriate
lexicon reference in `$c->stash('i18n_lexicon')`. The `l()` helper
then performs a single hash lookup -- no chasing.

## Client-side JavaScript

The `i18n_js` helper injects a `<script>` tag with the current
language's translations as a JSON object. Application JavaScript calls
`window.l('key')` for zero-overhead lookups.

An `/i18n/<lang>.json` endpoint is also registered for dynamic
lookups.

# CONFIGURATION

    {
        Fondation => {
            dependencies => [
                { 'Fondation::I18N' => {
                    default           => 'en',
                    support_url_langs => ['fr', 'en'],
                }},
            ],
        },
    }

## Options

- `default`

    Fallback language when detection fails (default: `en`).

- `support_url_langs`

    Language codes that may appear as the first URL path segment
    (e.g. `/fr/users`). These are detected in `before_dispatch`.

# TRANSLATION FILES

Plugins ship translations in `share/translations/<lang>.json`:

    share/translations/en.json   {"Home": "Home", "Save": "Save"}
    share/translations/fr.json   {"Home": "Accueil", "Save": "Enregistrer"}

Keys are the English strings passed to `l()`. Files from all plugins are
merged at startup by the I18N action; last write wins for duplicate keys.

# SEE ALSO

- [Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation)

    Core framework providing the identity fallback helpers that this plugin overrides.

- [Mojolicious::Plugin::Fondation::I18N::Action::I18N](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AI18N%3A%3AAction%3A%3AI18N)

    Post-load action that scans and merges translation files at startup.
