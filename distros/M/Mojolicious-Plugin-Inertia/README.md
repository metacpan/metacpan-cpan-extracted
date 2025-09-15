[![Actions Status](https://github.com/kfly8/Mojolicious-Plugin-Inertia/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Mojolicious-Plugin-Inertia/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Mojolicious-Plugin-Inertia.svg)](https://metacpan.org/release/Mojolicious-Plugin-Inertia)
# NAME

Mojolicious::Plugin::Inertia - Inertia.js adapter for Mojolicious

# SYNOPSIS

```perl
# Mojolicious
$app->plugin('Inertia' => {
  version => '1.0.0',  # Asset version for cache busting
  layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
});

# Mojolicious::Lite
plugin 'Inertia' => {
  version => md5_sum($app->home->child('public/assets/manifest.json')->slurp),
  layout  => app->home->child('dist', 'index.html')
};

# In your controller
sub index {
  my $c = shift;

  # Render Inertia page with props
  $c->inertia('Home', {
    user => { name => 'John Doe' },
    posts => \@posts
  });
}

# With lazy evaluation
sub dashboard {
  my $c = shift;

  $c->inertia('Dashboard', {
    # Regular prop
    user => $c->current_user,

    # Lazy prop - only evaluated when needed
    stats => sub {
      return $c->calculate_expensive_stats;
    }
  });
}
```

# DESCRIPTION

[Mojolicious::Plugin::Inertia](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AInertia) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin that provides server-side
adapter for [Inertia.js](https://inertiajs.com/), allowing you to build single-page
applications without building an API.

Inertia.js lets you quickly build modern single-page React, Vue and Svelte apps using
classic server-side routing and controllers. It works by intercepting requests and
converting the responses to either full page loads or JSON with just the page component
name and props.

## Features

- Automatic handling of Inertia and standard HTTP requests
- Asset versioning for automatic cache busting
- Partial reloads to optimize data transfer
- Lazy evaluation of props for performance
- History encryption support

# OPTIONS

[Mojolicious::Plugin::Inertia](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AInertia) supports the following options.

## version

```perl
plugin 'Inertia' => {version => '1.0.0'};
```

**Required**. Asset version string used for cache busting. When the version changes,
Inertia will force a full page reload to ensure users get the latest assets.

Common approaches:

```perl
# Static version
version => '1.0.0'

# MD5 hash of manifest file
version => md5_sum($app->home->child('manifest.json')->slurp)
```

## layout

```perl
plugin 'Inertia' => {layout => 'layouts/inertia.html.ep'};
```

**Required**. HTML template or template name containing the root element for your
JavaScript application. Must include a `<%= $data_page %>` placeholder where
the page data will be inserted.

Example template:

```
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>My App</title>
  </head>
  <body>
    <div id="app" data-page='<%= $data_page %>'></div>
    <script src="/js/app.js"></script>
  </body>
</html>
```

## encrypt\_history

```perl
plugin 'Inertia' => {encrypt_history => 1};
```

Optional. Enable history encryption by default (defaults to 0). When enabled,
page data in the browser's history state will be encrypted.

## clear\_history

```perl
plugin 'Inertia' => {clear_history => 1};
```

Optional. Clear history on navigate by default (defaults to 0). When enabled,
the browser's history state will be cleared on each navigation.

# HELPERS

[Mojolicious::Plugin::Inertia](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AInertia) implements the following helpers.

## inertia

```
$c->inertia($component, \%props, \%options);
```

Render an Inertia response. Returns either a JSON response for Inertia requests
or a full HTML page for standard requests.

### Arguments

- `$component` - Name of the JavaScript component to render (e.g., 'Users/Index')
- `\%props` - Hash reference of props to pass to the component
- `\%options` - Optional hash reference of options

### Options

- `encrypt_history` - Override the default history encryption setting
- `clear_history` - Override the default clear history setting

### Examples

```perl
# Basic usage
$c->inertia('Home', { message => 'Welcome!' });

# With nested components
$c->inertia('Users/Show', {
  user => $user,
  permissions => \@permissions
});

# With lazy props
$c->inertia('Dashboard', {
  user => $c->current_user,

  # This will only be evaluated if needed (e.g., partial reload)
  stats => sub {
    my $c = shift;  # Controller is passed to the sub
    return $c->db->calculate_stats;
  }
});

# With options
$c->inertia('SecurePage', $props, {
  encrypt_history => 1,
  clear_history => 1
});
```

## Request Headers

- `X-Inertia` - Indicates this is an Inertia request
- `X-Inertia-Version` - Asset version from the client
- `X-Inertia-Partial-Data` - Comma-separated list of props to include (partial reload)
- `X-Inertia-Partial-Component` - Component name for partial reload validation

## Response Headers

- `X-Inertia` - Set to "true" for Inertia responses
- `X-Inertia-Location` - URL for redirect on version mismatch (409 response)
- `Vary` - Set to "X-Inertia" to ensure proper caching

## Response Codes

- `200` - Successful response with page data
- `409` - Asset version mismatch, triggers full page reload

# SEE ALSO

- [Inertia.js Documentation](https://inertiajs.com)
- [Mojolicious](https://metacpan.org/pod/Mojolicious)
- [https://github.com/kfly8/Mojolicious-Plugin-Inertia](https://github.com/kfly8/Mojolicious-Plugin-Inertia)

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
