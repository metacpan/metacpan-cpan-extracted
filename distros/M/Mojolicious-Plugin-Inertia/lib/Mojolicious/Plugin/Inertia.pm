package Mojolicious::Plugin::Inertia;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(encode_json);
use Scalar::Util qw(reftype);
use Carp qw(croak);

our $VERSION = "0.01";

sub register {
    my ($self, $app, $conf) = @_;
    $conf ||= {};

    croak "Inertia plugin requires a 'version' configuration option" unless $conf->{version};
    croak "Inertia plugin requires a 'layout' configuration option" unless $conf->{layout};

    # Asset versioning. e.g. md5sum of your assets manifest file.
    my $version = $conf->{version};

    # Layout template for non-Inertia requests.
    # It must contain a <%= data_page %> placeholder at the application root.
    my $layout = ref $conf->{layout} ? $conf->{layout}->slurp : $conf->{layout};

    # History encryption settings (optional).
    # Ref: https://inertiajs.com/history-encryption
    my $default_encrypt_history = defined $conf->{encrypt_history} ? $conf->{encrypt_history} : 0;
    my $default_clear_history   = defined $conf->{clear_history} ? $conf->{clear_history} : 0;

    $app->helper(inertia => sub {
        my ($c, $component, $props, $options) = @_;
        $props ||= {};
        $options ||= {};

        # Options
        my $encrypt_history = defined $options->{encrypt_history} ? $options->{encrypt_history} : $default_encrypt_history;
        my $clear_history   = defined $options->{clear_history} ? $options->{clear_history} : $default_clear_history;

        # If the client's asset version does not match the server's version,
        # then the client must do a full page reload.
        # So, we respond with a 409 status and an X-Inertia-Location header
        # Ref: https://inertiajs.com/the-protocol#asset-versioning
        my $inertia_version = $c->req->headers->header('X-Inertia-Version');
        if ($c->req->method eq 'GET' && $inertia_version && $inertia_version ne $version) {
            $c->res->headers->header('X-Inertia-Location' => $c->req->url->to_string);
            return $c->rendered(409);
        }

        # Partial reloads allows you to request a subset of the props (data) from the server on subsequent visits to the same page component.
        # Ref: https://inertiajs.com/the-protocol#partial-reloads
        my $partial_data      = $c->req->headers->header('X-Inertia-Partial-Data');
        my $partial_component = $c->req->headers->header('X-Inertia-Partial-Component');
        if ($partial_data && $partial_component) {
            my @only_keys = split /,/, $partial_data;
            $props = { map { $_ => $props->{$_} } @only_keys };
        }

        # Resolve props that are coderefs by calling them with the current controller context.
        # Code refs are useful for lazy loading data only when needed.
        my $resolved_props = {};
        for my $key (keys %$props) {
            my $prop = $props->{$key};
            $resolved_props->{$key} = (reftype($prop) || '') eq 'CODE' ? $prop->($c) : $prop;
        }

        # Construct the page object.
        # Ref: https://inertiajs.com/the-protocol#the-page-object
        my $page_object = {
            component      => $component,
            props          => $resolved_props,
            url            => $c->req->url->to_string,
            version        => $version,
            encryptHistory => $encrypt_history,
            clearHistory   => $clear_history,
        };

        # Check if the request is an Inertia request.
        # If so, return a JSON response.
        # Else, return an HTML response with embedded page object.
        # Ref: https://inertiajs.com/the-protocol#inertia-responses
        my $is_inertia = $c->req->headers->header('X-Inertia');

        if ($is_inertia) {
            $c->res->headers->header('X-Inertia' => 'true');
            $c->res->headers->header('Vary' => 'X-Inertia');
            return $c->render(json => $page_object);
        }
        else {
            $c->res->headers->header('Vary' => 'X-Inertia');
            return $c->render(
                inline    => $layout,
                format    => 'html',
                data_page => encode_json($page_object)
            );
        }
    });
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Inertia - Inertia.js adapter for Mojolicious

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::Inertia> is a L<Mojolicious> plugin that provides server-side
adapter for L<Inertia.js|https://inertiajs.com/>, allowing you to build single-page
applications without building an API.

Inertia.js lets you quickly build modern single-page React, Vue and Svelte apps using
classic server-side routing and controllers. It works by intercepting requests and
converting the responses to either full page loads or JSON with just the page component
name and props.

=head2 Features

=over 4

=item * Automatic handling of Inertia and standard HTTP requests

=item * Asset versioning for automatic cache busting

=item * Partial reloads to optimize data transfer

=item * Lazy evaluation of props for performance

=item * History encryption support

=back

=head1 OPTIONS

L<Mojolicious::Plugin::Inertia> supports the following options.

=head2 version

  plugin 'Inertia' => {version => '1.0.0'};

B<Required>. Asset version string used for cache busting. When the version changes,
Inertia will force a full page reload to ensure users get the latest assets.

Common approaches:

  # Static version
  version => '1.0.0'

  # MD5 hash of manifest file
  version => md5_sum($app->home->child('manifest.json')->slurp)

=head2 layout

  plugin 'Inertia' => {layout => 'layouts/inertia.html.ep'};

B<Required>. HTML template or template name containing the root element for your
JavaScript application. Must include a C<< <%= $data_page %> >> placeholder where
the page data will be inserted.

Example template:

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

=head2 encrypt_history

  plugin 'Inertia' => {encrypt_history => 1};

Optional. Enable history encryption by default (defaults to 0). When enabled,
page data in the browser's history state will be encrypted.

=head2 clear_history

  plugin 'Inertia' => {clear_history => 1};

Optional. Clear history on navigate by default (defaults to 0). When enabled,
the browser's history state will be cleared on each navigation.

=head1 HELPERS

L<Mojolicious::Plugin::Inertia> implements the following helpers.

=head2 inertia

  $c->inertia($component, \%props, \%options);

Render an Inertia response. Returns either a JSON response for Inertia requests
or a full HTML page for standard requests.

=head3 Arguments

=over 4

=item * C<$component> - Name of the JavaScript component to render (e.g., 'Users/Index')

=item * C<\%props> - Hash reference of props to pass to the component

=item * C<\%options> - Optional hash reference of options

=back

=head3 Options

=over 4

=item * C<encrypt_history> - Override the default history encryption setting

=item * C<clear_history> - Override the default clear history setting

=back

=head3 Examples

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

=head2 Request Headers

=over 4

=item * C<X-Inertia> - Indicates this is an Inertia request

=item * C<X-Inertia-Version> - Asset version from the client

=item * C<X-Inertia-Partial-Data> - Comma-separated list of props to include (partial reload)

=item * C<X-Inertia-Partial-Component> - Component name for partial reload validation

=back

=head2 Response Headers

=over 4

=item * C<X-Inertia> - Set to "true" for Inertia responses

=item * C<X-Inertia-Location> - URL for redirect on version mismatch (409 response)

=item * C<Vary> - Set to "X-Inertia" to ensure proper caching

=back

=head2 Response Codes

=over 4

=item * C<200> - Successful response with page data

=item * C<409> - Asset version mismatch, triggers full page reload

=back

=head1 SEE ALSO

=over 4

=item * L<Inertia.js Documentation|https://inertiajs.com>

=item * L<Mojolicious>

=item * L<https://github.com/kfly8/Mojolicious-Plugin-Inertia>

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

