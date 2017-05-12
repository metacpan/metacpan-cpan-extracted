package Mojolicious::Plugin::Surveil;

=head1 NAME

Mojolicious::Plugin::Surveil - Surveil user actions

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Mojolicious::Plugin::Surveil> is a plugin which allow you to see every
event a user trigger on your web page. It is meant as a debug tool for
seeing events, even if the browser does not have a JavaScript console.

Note: With great power, comes great responsibility.

CAVEAT: The JavaScript that is injected require WebSocket in the browser to
run. The surveil events are attached to the "body" element, so any other event
that prevent events from bubbling will not emit this to the WebSocket
resource.

=head1 SYNOPSIS

Use default logging:

  use Mojolicious::Lite;
  plugin "surveil";
  app->start;

Use custom route:

  use Mojolicious::Lite;
  use Mojo::JSON "j";

  plugin surveil => { path => "/surveil" };

  websocket "/surveil" => sub {
    my $c = shift;

    $c->on(message => sub {
      my ($c, $action) = @_;
      warn "User event: $action\n";
    });
  };

  app->start;

=head1 CONFIG

This plugin can take the following config params:

=over 4

=item * enable_param = "..."

Used to specify a query parameter to be part of the URL to enable surveil.

Default is not to require any query parameter.

=item * events = [...]

The events that should be reported back over the WebSocket.

Defaults to click, touchstart, touchcancel and touchend.
(The default list is EXPERIMENTAL).

=item * path = "...";

The path to the WebSocket route.

Defaults to C</mojolicious/plugin/surveil>. Emitting the "path" parameter will
also add a default WebSocket route which simply log with "debug" the action
that was taken. (The format of the logging is EXPERIMENTAL)

=back

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'j';

our $VERSION = '0.01';

=head1 METHODS

=head2 register

  $self->register($app, $config);

Used to add an "after_render" hook into the application which adds a
JavaScript to every HTML document.

=cut

sub register {
  my ($self, $app, $config) = @_;

  $config->{events} ||= [qw( click touchstart touchcancel touchend )];

  push @{ $app->renderer->classes }, __PACKAGE__;
  $self->_after_render_hook($app, $config);
  $self->_default_route($app, $config) unless $config->{path};
}

sub _after_render_hook {
  my ($self, $app, $config) = @_;
  my $enable_param = $config->{enable_param};

  $app->hook(after_render => sub {
    my ($c, $output, $format) = @_;
    return if $format ne 'html';
    return if $enable_param and !$c->param($enable_param);
    my $js = $self->_javascript_code($c, $config);
    $$output =~ s!<head>!<head>$js!;
  });
}

sub _default_route {
  my ($self, $app, $config) = @_;

  $config->{path} = '/mojolicious/plugin/surveil';

  $app->routes->websocket($config->{path})->to(cb => sub {
    my $c = shift;
    $c->inactivity_timeout(60);
    $c->on(message => sub {
      my $action = j $_[1];
      my ($type, $target) = (delete $action->{type}, delete $action->{target});
      $app->log->debug(qq(Event "$type" on "$target" @{[j $action]}));
    });
  });
}

sub _javascript_code {
  my ($self, $c, $config) = @_;
  my $scheme = $c->req->url->to_abs->scheme || 'http';

  $scheme =~ s!^http!ws!;

  $c->render_to_string(
    template => 'mojolicious/plugin/surveil',
    events => j($config->{events}),
    surveil_url => $c->url_for($config->{path})->to_abs->scheme($scheme),
  );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
__DATA__
@@ mojolicious/plugin/surveil.html.ep
<script type="text/javascript">
window.addEventListener('load', function(e) {
  var events = <%== $events %>;
  var socket = new WebSocket('<%= $surveil_url %>');
  socket.onopen = function() {
    socket.send(JSON.stringify({ type: 'load', target: 'window' }));
    for (i = 0; i < events.length; i++) {
      document.body.addEventListener(events[i], function(e) {
        var data = { extra: {} };
        for (var prop in e) {
          if (!(typeof e[prop]).match(/^(boolean|number|string)$/)) continue;
          if (prop.match(/^[A-Z]/)) continue;
          data[prop] = e[prop];
        }
        console.log(e);
        data.target = [e.target.tagName.toLowerCase(), e.target.id ? '#' + e.target.id : '', e.target.className ? '.' + e.target.className.replace(/ /g, '.') : ''].join('');
        if (data.target.href) data.extra.href = '' + data.target.href;
        socket.send(JSON.stringify(data));
      });
    }
  }
});
</script>
