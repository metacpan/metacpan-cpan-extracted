#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Time::HiRes ();
use Punk ();

# The template thread: `{% locale.welcome %}`.
#
# A hash on the render data, the way Punk::Plugin::CSP puts `csp_nonce`
# there - so this needs no change to Stencil at all. The filter form the
# sketch proposed, `{% 'welcome' | locale %}`, does not parse: Stencil tag
# heads are paths, and a string literal is only a filter ARGUMENT.
#
# The hash is built once per catalogue rather than per request, because
# building one per request would copy the catalogue into SVs on every page -
# the cost phase 0 exists to avoid.
#
# The two tests that matter here fail in opposite directions and both have to
# pass at once: markup in the catalogue must survive, and markup in a
# substitution must not.

BEGIN {
    eval { require Template::Stencil; 1 }
        or plan skip_all => 'Template::Stencil required for the template half';
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $cat = File::Temp::tempdir(CLEANUP => 1);

sub write_file {
    my ($path, $body) = @_;
    open my $fh, '>:raw', $path or die $!;
    print $fh $body;
    close $fh;
}

write_file(File::Spec->catfile($cat, 'en.json'), <<'JSON');
{
  "welcome":  "Welcome to <a href=\"/\">the site</a>",
  "plain":    "just words",
  "amp":      "Fish &amp; Chips",
  "greeting": "Hello, {name}",
  "items":    { "one": "1 item", "other": "many items" },
  "deep":     { "a": { "b": "down here" } }
}
JSON
write_file(File::Spec->catfile($cat, 'fr.json'),
    '{ "plain": "des mots", "welcome": "Bienvenue" }');

my %tmpl = (
    plain   => '{% locale.plain %}',
    welcome => '{% locale.welcome %}',
    rawwel  => '{% raw locale.welcome %}',
    amp     => '{% locale.amp %}',
    nested  => '{% locale.items.one %}',
    deep    => '{% locale.deep.a.b %}',
    missing => '{% locale.no_such_key %}',
    tag     => '{% lang %}',
    sub     => '{% greeting %}',
);
write_file(File::Spec->catfile($dir, "$_.tmpl"), $tmpl{$_}) for keys %tmpl;

eval qq{
    package TApp;
    use Punk;
    plugin 'I18n' => { dir => '$cat', default => 'en' };
    views Stencil => { template_dir => '$dir' };
    get '/:name' => sub {
        my \$c = shift;
        \$c->render(\$c->param('name'));
    };
    get '/x/tag' => sub {
        my \$c = shift;
        \$c->render('tag', { lang => \$c->locale });
    };
    get '/x/sub' => sub {
        my \$c = shift;
        \$c->render('sub', {
            greeting => \$c->locale('greeting', name => '<script>x</script>'),
        });
    };
    get '/x/miss' => sub { \$_[0]->text(\$_[0]->locale('no_such_key')) };
    1;
} or die $@;

my $app = TApp->to_app;
sub render {
    my (%o) = @_;
    my $r = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $o{path},
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        ($o{lang} ? (HTTP_ACCEPT_LANGUAGE => $o{lang}) : ()),
    });
    return $r->[2][0];
}

# ---- it resolves at all, with nothing passed by the handler ------------------
{
    is(render(path => '/plain'), 'just words',
        '{% locale.plain %} resolves with nothing passed by the handler - the '
      . 'hash is put on the render data the way CSP puts its nonce there');
    is(render(path => '/plain', lang => 'fr'), 'des mots',
        'and it is the NEGOTIATED catalogue, not the default one');
}

# ---- the escaping, from both directions --------------------------------------
# These are the two that must hold together.
{
    is(render(path => '/welcome'),
        'Welcome to &lt;a href=&quot;/&quot;&gt;the site&lt;/a&gt;',
        'a path is ESCAPED by default - the safe answer needs no thought '
      . 'from whoever writes the template');

    is(render(path => '/rawwel'), 'Welcome to <a href="/">the site</a>',
        '`raw` keeps a catalogue entry\'s markup - and it is safe here '
      . 'precisely because this path takes no substitutions: the trap is '
      . 'about substituted VALUES reaching markup, and a hash has nowhere to '
      . 'put one');

    like(render(path => '/x/sub'), qr/&lt;script&gt;/,
        'a substituted value IS escaped - that is the handler path, where '
      . 'substitutions exist');
    unlike(render(path => '/x/sub'), qr/<script>/,
        '...and the raw tag never reaches the page');
}

# ---- nothing is escaped twice ------------------------------------------------
# The failure that looks cosmetic and means both escaping layers are running.
{
    is(render(path => '/amp'), 'Fish &amp;amp; Chips',
        'an entity in a catalogue entry is escaped ONCE by the template - '
      . 'the plugin does not escape on the way out, so what you see is '
      . 'Stencil escaping and nothing else');
    is(render(path => '/rawwel'), 'Welcome to <a href="/">the site</a>',
        'and through raw it is not escaped at all');
}

# ---- nesting -----------------------------------------------------------------
{
    is(render(path => '/nested'), '1 item',
        'a nested catalogue is a dotted path: locale.items.one');
    is(render(path => '/deep'), 'down here', 'to whatever depth it goes');
}

# ---- a missing key is VISIBLE in a template too ------------------------------
# A template resolves a missing path to the empty string, so a plain hash here
# would swallow {% locale.typo %} while $c->locale('typo') rendered the key -
# the same omission visible in a handler and invisible in a template.
#
# That is the whole reason this hash is TIED: FETCH answers for a key the
# catalogue does not have. It needed Template::Stencil 0.10, whose resolver
# did not go through tie magic - a tied hash used to read as empty rather than
# as anything, which is what this test asserted against until it was fixed
# there rather than worked around here.
{
    is(render(path => '/missing'), 'no_such_key',
        'a missing key renders as the KEY in a template, exactly as it does '
      . 'in a handler');

    is(render(path => '/x/miss'), 'no_such_key',
        '...and the two paths agree, which is the property worth having: an '
      . 'omission cannot be visible in code and invisible on the page');
}

# ---- the tag ------------------------------------------------------------------
{
    is(render(path => '/x/tag', lang => 'fr'), 'fr',
        '$c->locale is the tag, for <html lang=> and a switcher');
}

# ---- the hash is per REQUEST --------------------------------------------------
{
    is(render(path => '/plain', lang => 'fr'), 'des mots', 'a French request');
    is(render(path => '/plain'), 'just words',
        'and the next request is not still French - the hash is bound per '
      . 'request, so a handler holding a data hashref between requests '
      . 'cannot serve one language for ever');
}

# ---- what the per-catalogue hash costs ---------------------------------------
# The plan said to measure rather than to prefer. Built once per catalogue, a
# render pays one hv_stores of an existing reference.
{
    my $n = 2000;
    my $t0 = Time::HiRes::time();
    render(path => '/plain') for 1 .. $n;
    my $el = Time::HiRes::time() - $t0;
    note sprintf 'one-lookup render: %.1fus each over %d renders',
        $el / $n * 1e6, $n;
    ok($el >= 0, 'measured');
}

done_testing;
