package Mojolicious::Plugin::Fondation::I18N;
$Mojolicious::Plugin::Fondation::I18N::VERSION = '0.01';
# ABSTRACT: Fondation I18N plugin -- JSON-backed localization for the Fondation ecosystem

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::JSON qw(encode_json);
use I18N::LangTags;
use I18N::LangTags::Detect;


=head1 SYNOPSIS

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

=head1 DESCRIPTION

This plugin provides real dictionary-based translation for Fondation
applications, overriding the identity fallback helpers (C<l> and C<i18n_js>)
from Fondation core.

=head2 How it works

A post-load action (declared via C<provides_actions =E<gt> ['I18N']>) scans
every plugin's C<share/translations/E<lt>langE<gt>.json> at startup and merges
them into a single lexicon per language. The merged lexicons are stored on
C<$app> and exposed via the C<i18n_lexicons> helper.

At request time, a C<before_dispatch> hook detects the user's language
(from URL prefix or C<Accept-Language> header) and caches the appropriate
lexicon reference in C<$c-E<gt>stash('i18n_lexicon')>. The C<l()> helper
then performs a single hash lookup -- no chasing.

=head2 Client-side JavaScript

The C<i18n_js> helper injects a C<E<lt>scriptE<gt>> tag with the current
language's translations as a JSON object. Application JavaScript calls
C<window.l('key')> for zero-overhead lookups.

An C</i18n/E<lt>langE<gt>.json> endpoint is also registered for dynamic
lookups.

=head1 CONFIGURATION

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

=head2 Options

=over

=item C<default>

Fallback language when detection fails (default: C<en>).

=item C<support_url_langs>

Language codes that may appear as the first URL path segment
(e.g. C</fr/users>). These are detected in C<before_dispatch>.

=back

=head1 TRANSLATION FILES

Plugins ship translations in C<share/translations/E<lt>langE<gt>.json>:

  share/translations/en.json   {"Home": "Home", "Save": "Save"}
  share/translations/fr.json   {"Home": "Accueil", "Save": "Enregistrer"}

Keys are the English strings passed to C<l()>. Files from all plugins are
merged at startup by the I18N action; last write wins for duplicate keys.

=head1 SEE ALSO

=over

=item L<Mojolicious::Plugin::Fondation>

Core framework providing the identity fallback helpers that this plugin overrides.

=item L<Mojolicious::Plugin::Fondation::I18N::Action::I18N>

Post-load action that scans and merges translation files at startup.

=back

=cut

# ---------------------------------------------------------------------------
# fondation_meta -- declares itself to Fondation core
# ---------------------------------------------------------------------------

sub fondation_meta {
    return {
        dependencies      => [],
        provides_actions  => ['I18N'],
        defaults          => {
            default           => 'en',
            support_url_langs => [],
            fondation_clean   => ['share/i18n/'],
        },
    };
}

# ---------------------------------------------------------------------------
# register -- set up hooks, helpers, and routes
# ---------------------------------------------------------------------------

sub register ($self, $app, $config) {

    my $default = $config->{default} // 'en';
    $self->{default} = $default;

    # ── i18n_lexicons helper -- exposes translations loaded by Action::I18N ──

    $app->helper(i18n_lexicons => sub { $app->{i18n_lexicons} //= {} });

    # ── before_dispatch: detect language + cache lexicon ref in stash ───

    $app->hook(before_dispatch => sub ($c) {
        $self->_detect_language($c, $config);

        # Cache the current language's lexicon ref in stash for fast l() lookup
        my $lang    = $c->stash('i18n_lang') // $default;
        my $lexicon = $c->i18n_lexicons->{$lang} // {};
        $c->stash(i18n_lexicon => $lexicon);
    });

    # ── l() helper -- one hash lookup, no chasing ────────────────────────
    # Overrides the identity fallback from Fondation core.

    $app->helper(l => sub {
        my $c       = shift;
        my $text    = shift;
        my $lexicon = $c->stash('i18n_lexicon') // {};
        return $lexicon->{$text} // $text;
    });

    # ── languages() helper -- get/set current language, refresh cache ─────

    $app->helper(languages => sub {
        my $c    = shift;
        my $lang = shift;
        if (defined $lang) {
            $c->stash(i18n_lang => $lang);
            $c->stash(i18n_lexicon =>
                $c->i18n_lexicons->{$lang} // {});
        }
        return $c->stash('i18n_lang') // $default;
    });

    # ── i18n_js helper -- injects current lexicon as JS object ────────────
    # Overrides the identity fallback from Fondation core.
    # Called by layout via %== i18n_js before any app JS.

    $app->helper(i18n_js => sub ($c) {
        my $lang = $c->stash('i18n_lang') // $self->{default};

        # Memoize serialized JSON per language (lexicon loaded once at startup)
        $app->{i18n_js_json}{$lang} //= do {
            my $lexicon = $c->i18n_lexicons->{$lang} // {};
            my $json = encode_json($lexicon);
            utf8::decode($json);
            $json;
        };

        my $json = $app->{i18n_js_json}{$lang};
        return Mojo::ByteStream->new(
            qq{<script>window._i18n=$json;window.l=function(k){return _i18n[k]||k;};</script>}
        );
    });

    # ── /i18n/<lang>.json endpoint for client-side JS ────────────────────

    $app->routes->get('/i18n/<lang>.json')->to(cb => sub ($c) {
        my $lang = $c->param('lang');
        $lang =~ s/[^a-z_\-]//g;
        return $c->reply->not_found unless length $lang;

        my $lexicon = $c->i18n_lexicons->{$lang};
        return $c->reply->not_found unless $lexicon && %$lexicon;

        $c->render(json => $lexicon);
    });


    return $self;
}

# ---------------------------------------------------------------------------
# _detect_language -- parse Accept-Language header, set stash
# ---------------------------------------------------------------------------

sub _detect_language ($self, $c, $config) {
    my @languages;

    # 1) URL prefix detection
    if (my $langs = $config->{support_url_langs}) {
        if (my $path = $c->req->url->path) {
            my $part = $path->parts->[0];
            if ($part && grep { $part eq $_ } @$langs) {
                unshift @languages, $part;
            }
        }
    }

    # 2) Accept-Language header
    my @header_langs = I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
            $c->req->headers->accept_language
        )
    );
    push @languages, @header_langs;

    # 3) Default
    push @languages, $self->{default};

    $c->stash(i18n_lang => $languages[0]) if $languages[0];
}

1;
