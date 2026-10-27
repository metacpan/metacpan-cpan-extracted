# Changelog

## 1.0.0 - 2026-10-25

- Initial release.
- `PrivatusAnalytics` builds the script tag, with settings for site id, script
  host, modules, excluded paths, domains, single-page app mode, manual mode,
  extra attributes, a Content Security Policy nonce and more.
- Off outside production by default.
- `event_attrs` and `event_data` for custom events on buttons, links and forms.
- `click_attr` and `click_data` for click map names.
- Page props (`props`): a hash ref, an array ref of pairs, or a code ref that
  gets the request. They print the `privatusPageProps` script and `data-props`.
- `queue_stub` setting, so `privatus.track` calls made before the tracker loads are kept.
- `Mojolicious::Plugin::PrivatusAnalytics` with the `privatus_analytics_tag`,
  `privatus_event` and `privatus_click` helpers and optional auto inject.
- `Dancer2::Plugin::PrivatusAnalytics` with the same keywords, template
  helpers and optional auto inject.
- `Plack::Middleware::PrivatusAnalytics` adds the tag to the head of HTML
  responses from any PSGI app.
- Changed: with `queue_stub` on, a tag that is off (outside production, `enabled => 0` or no site id) now
  prints the queue stub and nothing else, so `privatus.track(...)` calls in your own JavaScript never fail.
  Before, it printed nothing. With `queue_stub` off it still prints nothing. The props code ref is still not
  called when the tag is off.
- Added `example/`, a small Mojolicious app for the conformance tests.
- README: a privacy policy paragraph you can paste.
