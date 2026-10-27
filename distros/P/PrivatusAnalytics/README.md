# Privatus Analytics for Perl

Adds the cookieless [Privatus Analytics](https://privatusanalytics.com)
tracking script to your Perl web app. There is a plugin for Mojolicious, a
plugin for Dancer2, a Plack middleware for any PSGI app, and a plain module
you can use anywhere.

Privatus Analytics counts visits, sources, pages and conversions without
cookies, local storage or fingerprinting, so analytics does not need a consent
banner by itself. Check with your own counsel for your country.

This distribution only prints the browser script and a few HTML attributes. It
never sends events from your server and sets no cookies. You need a Privatus
Analytics account to see reports, and there is a free plan. Sign up at
https://privatusanalytics.com.

## Requirements

* Perl 5.20 or later.
* Optional: Mojolicious 9 or later, Dancer2 0.400000 or later, or Plack.
* A Privatus Analytics site id (it starts with `pa_`). You find it under
  Site settings, Tracking.

## Install

```sh
cpanm PrivatusAnalytics
```

For the full setup guide and every tracker option, see the [Privatus Analytics
docs](https://privatusanalytics.com/docs).

Set your site id with an environment variable:

```sh
PRIVATUS_SITE_ID=pa_YOURSITEID
```

or pass it as the `site_id` setting, as shown below.

## Add the tag

### Mojolicious

```perl
# Mojolicious::Lite
plugin PrivatusAnalytics => { site_id => 'pa_YOURSITEID' };

# Full app, in startup
$self->plugin(PrivatusAnalytics => { site_id => 'pa_YOURSITEID' });
```

Settings in your app config under `privatus_analytics` work too. Put the helper
in the `<head>` of your layout:

```
<head>
  <title>My app</title>
  %= privatus_analytics_tag
</head>
```

### Dancer2

```yaml
# config.yml
plugins:
  PrivatusAnalytics:
    site_id: pa_YOURSITEID
```

```perl
package MyApp;
use Dancer2;
use Dancer2::Plugin::PrivatusAnalytics;
```

In a Template Toolkit layout:

```
<head>
  <title>My app</title>
  [% privatus_analytics_tag() %]
</head>
```

### Plack (any PSGI app)

```perl
# app.psgi
use Plack::Builder;

builder {
    enable 'PrivatusAnalytics', site_id => 'pa_YOURSITEID';
    $app;
};
```

The middleware adds the tag for you (see auto inject below).

### Plain Perl

```perl
use PrivatusAnalytics;

my $privatus = PrivatusAnalytics->new(site_id => 'pa_YOURSITEID', environment => 'production');
print $privatus->tag;
```

### What it prints

In production it prints:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

The tag prints nothing when there is no site id, and nothing outside
production (see below). The one exception is the queue stub: when it is on,
it still prints (see [Track from your own JavaScript](#track-from-your-own-javascript)). If your app uses a Content Security Policy nonce (a
random code that lets a script run), pass it as the `nonce` setting. The
Mojolicious plugin also uses the `csp_nonce` stash value, the Dancer2 plugin
the `csp_nonce` var, and the Plack middleware `$env->{'plack.csp_nonce'}`.

### Or let it add the tag for you

If you would rather not touch your layouts, switch on auto inject:

```perl
plugin PrivatusAnalytics => { site_id => 'pa_YOURSITEID', auto_inject => 1 };
```

```yaml
plugins:
  PrivatusAnalytics:
    site_id: pa_YOURSITEID
    auto_inject: 1
```

In Mojolicious it uses an `after_render` hook, and in Dancer2 an `after` hook.
The Plack middleware always does it (set `auto_inject => 0` to stop it).

It adds the tag just before `</head>` in uncompressed `text/html` responses
with status 200. It skips Ajax requests, pages without a `<head>`, and pages
that already have the tag. Responses that carry a `Content-Encoding` header
are left alone, and so are streamed Plack responses. With Plack, enable the
middleware after `Plack::Middleware::Deflater` (so it runs inside it), or use
the helper instead. The `Content-Length` header is fixed for you.

## Configuration

Every setting is optional except the site id. Each plugin takes the same
settings.

```perl
plugin PrivatusAnalytics => {
    site_id          => 'pa_YOURSITEID',                  # or $ENV{PRIVATUS_SITE_ID}
    script_host      => 'https://privatusstats.com',      # or $ENV{PRIVATUS_SCRIPT_HOST}
    modules          => [qw(engage auto vitals clicks ask)],
    excluded_paths   => [qw(/admin/* /preview/*)],
    domains          => [qw(example.com www.example.com)],
    spa              => 'auto',    # auto, history, hash or off
    manual           => 0,         # 1 turns off the automatic pageview
    auto_inject      => 0,
    extra_attributes => { 'data-mask' => '/orders/*->/orders/:id' },
    props            => sub { my ($c) = @_; { plan => $c->stash('plan') } },
    queue_stub       => 0,
};
```

| Setting | Default | What it does |
|---|---|---|
| `site_id` | `$ENV{PRIVATUS_SITE_ID}` | The `data-site` attribute. Nothing prints without it |
| `script_host` | `https://privatusstats.com` | Where `/js/pa.js` is served. Change it only if you host your own copy |
| `modules` | tracker default (`engage`) | The `data-modules` attribute. Setting it replaces the default, so keep `engage` for time on page and scroll depth. `[]` loads none |
| `excluded_paths` | none | The `data-exclude` attribute. Path patterns the tracker never counts |
| `domains` | all hosts | The `data-domains` attribute. Count only these hostnames |
| `spa` | `auto` | The `data-spa` attribute, for single-page apps |
| `manual` | `0` | The `data-manual` attribute |
| `enabled` | `undef` | `1` or `0` forces the tag on or off in every environment |
| `enabled_environments` | `['production']` | Environments that get the tag. The Plack middleware uses `['deployment', 'production']` |
| `environment` | the framework's | The current environment. Mojolicious uses the app mode, Dancer2 its environment, and the rest `$ENV{PLACK_ENV}` |
| `auto_inject` | `0` | Adds the tag to the head of HTML pages. On by default in the Plack middleware |
| `extra_attributes` | `{}` | Any other `data-*` attribute |
| `props` | `{}` | Page props sent with every pageview and event. A hash ref, or a code ref that gets the request. See below |
| `queue_stub` | `0` | Prints a small script first, so `privatus.track` calls made before the tracker loads are kept and sent later. It still prints when the tag is off, so those calls never fail |
| `nonce` | none | The Content Security Policy nonce. A string, or a code ref that gets the request |

Lists can be array refs or comma separated text. Each tracker attribute is
explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

You can also override a setting for one page:

```
%= privatus_analytics_tag modules => [qw(engage auto)], excluded_paths => ['/preview/*']
```

### Development and test

Development and test requests are not counted by default, so your own
clicking around never reaches your reports. The tag is on when:

* Mojolicious: the app mode is `production`.
* Dancer2: the environment is `production`.
* Plack: `PLACK_ENV` is `deployment` or `production`.

To see the tag while you build, set `enabled => 1`. The tracker also ignores
`localhost` unless you pass `data-allow-local` or `data-debug` (see [Debug
mode](https://privatusanalytics.com/docs/tracker/debug)):

```perl
extra_attributes => { 'data-debug' => 'true' }
```

### Leaving people out

Use `data-exclude` through `excluded_paths` for admin areas. To leave out
signed-in staff, print the helper only for other people:

```
%= privatus_analytics_tag unless current_user_is_admin
```

## Product analytics: see which features people use

Privatus can show which buttons, forms and features people really use. You
add a few attributes to your HTML. The tracker reads them in the browser and
sends the events. Your server still sends nothing.

### Name events well

Use a short "Noun verb" name, like `Report exported` or `Invite sent`. Put the
details in props, not in the name. So write `Report exported` with
`format => 'csv'`, not `Report exported as CSV`. Then all exports add up in
one place, and you can split them by format.

### Events on buttons, links and forms

`privatus_event` prints the attributes inside a tag you write yourself.

Mojolicious:

```
<button <%= privatus_event 'Report exported', { format => 'csv', source => 'toolbar' } %>>Export</button>
```

Dancer2 (Template Toolkit):

```
<button [% privatus_event('Report exported', { format => 'csv', source => 'toolbar' }) %]>Export</button>
```

Plain Perl:

```perl
use PrivatusAnalytics qw(event_attrs click_attr);
my $attrs = event_attrs('Report exported', { format => 'csv', source => 'toolbar' });
```

They print:

```html
<button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">Export</button>
```

Props can be a hash ref (the keys are sorted), an array ref of pairs, or a
plain list of pairs (both keep your order). With the Mojolicious `tag` and
`link_to` helpers, use `privatus_event_data`. It returns the attributes as a
list of pairs:

```
%= link_to 'Read the guide' => '/guide', privatus_event_data('Guide opened')
```

On a form, the event is sent when the form is submitted:

```
<form action="/newsletter" method="post" <%= privatus_event 'Newsletter joined', { list => 'weekly' } %>>
```

The rules:

* The name is trimmed and cut to 120 characters. An empty name prints nothing.
* Prop keys are made lowercase. Anything that is not a letter, a digit or `_`
  becomes `_`, so `"Report Type"` becomes `report_type`. Keys are cut to 64
  characters.
* At most 30 props. Values become text: numbers as written, lists joined with
  commas, `\1` and `\0` (or `JSON::PP::true` and `JSON::PP::false`) become
  `true` and `false`. `undef` values are left out. Values are cut to 500
  characters.
* Everything is escaped for HTML.
* The attributes print in every environment, even when the tag is off. They do
  nothing without the tracker, so your pages look the same in development and
  production.

### Click maps

A click map shows where people click on a page. Give the important parts a
name so they stay easy to find, even when the page changes:

```
<a href="/pricing" <%= privatus_click 'pricing.cta' %>>See plans</a>
%= link_to 'See plans' => '/pricing', privatus_click_data('pricing.cta')
```

In Dancer2 use `[% privatus_click('pricing.cta') %]`, and in plain Perl
`click_attr('pricing.cta')`. A name may use letters, digits and `_ . : -`, up
to 100 characters. Anything else prints nothing, and outside production the
Mojolicious and Dancer2 plugins write a warning to the app log.

### Page props: plan, role and other groups

Page props are sent with every pageview and event on the page. Use them to
split your reports by plan, role, app version, feature flag or account tier.

Set them for every page with a code ref. It runs on each request and gets the
request: the controller in Mojolicious, the request in Dancer2, and a
`Plack::Request` in the Plack middleware.

```perl
plugin PrivatusAnalytics => {
    site_id => 'pa_YOURSITEID',
    props   => sub {
        my ($c) = @_;
        return { plan => $c->stash('plan'), role => $c->stash('role'), app_version => '2.4' };
    },
};
```

A plain hash ref works too. You can also set or change props for one page.
They are merged over the configured ones, and `undef` removes one:

```
%= privatus_analytics_tag props => { section => 'billing', role => undef }
```

The tag then prints a small script before the tracker, with your nonce when
you have one, and points the tracker at it:

```html
<script nonce="...">window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID" data-props="privatusPageProps"></script>
```

Keys follow the same rules as event props. Numbers and true or false stay as
they are, and lists stay lists (up to 30 items). The props are escaped so they
are safe inside a script. Auto inject uses the same setting.

**Never put names, emails, user ids or anything that points to one person in
props.** Privatus counts visitors without any id. Put groups (like the plan or
the role), not people. The server also removes emails and long ids it finds.

### Track from your own JavaScript

For things that are not a click or a submit, call the tracker from your
JavaScript, as the [JavaScript API
docs](https://privatusanalytics.com/docs/tracker/javascript-api) explain:

```js
privatus.track("Feature used", { feature: "export" })
```

If your code may run before the tracker has loaded, switch on the queue stub.
It prints a tiny script before the tracker that keeps your calls in a list and
sends them once the tracker is ready:

```perl
queue_stub => 1
```

or for one layout: `%= privatus_analytics_tag queue_stub => 1`. The stub
prints even where the tag is off (in development, with `enabled => 0`, or with
no site id). Then only the stub prints: no tracker and no page props. So you
can always call `privatus.track(...)`. In development the calls just wait in
the queue and are never sent.

### See the results

* [Funnels](https://privatusanalytics.com/docs/features/funnels): how many
  people go from one step to the next.
* [Click maps](https://privatusanalytics.com/docs/features/click-maps): where
  people click.
* [Goals](https://privatusanalytics.com/docs/features/goals): turn an event
  into a goal to count conversions.
* [Events](https://privatusanalytics.com/docs/events): every custom event and
  its props.

## Privacy

The script sets no cookies and stores nothing in the browser. The event, click
and props helpers only print HTML attributes and a small script. Nothing here
reads IP addresses or browser details, and nothing is sent from your server.
Keep people out of your props and event props: no names, emails or user ids.
See the [privacy documentation](https://privatusanalytics.com/docs/privacy)
for what is collected.

If you have a privacy policy, it should say which tools handle your visitors' data. You can paste this:

> This website uses [Privatus Analytics](https://privatusanalytics.com/privacy-analytics) to count visits. It
> does not use cookies and does not follow you from one website to another. Your IP address is used for a moment
> to count visits and is never stored.

Change it to fit your site. The [privacy policy generator](https://privatusanalytics.com/tools/privacy-policy-generator)
makes a longer version with your site's name in it.

## Development

The tests run in Docker so your local Perl does not matter:

```sh
./run-docker.sh
```

It runs the Test::More suite (with Test::Mojo, Plack::Test and a small Dancer2
app), Perl::Critic, a perltidy check, and `make dist`.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/perl.

## License

MIT. See [LICENSE](LICENSE). Privatus Analytics is a product of Two Phase LLC,
Wyoming, USA.
