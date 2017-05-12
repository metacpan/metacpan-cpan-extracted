package Mojolicious::Plugin::Multiplex;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use Mojolicious::Plugin::Multiplex::Multiplexer;

sub register {
  my ($plugin, $app, $conf) = @_;

  push @{ $app->static->classes }, __PACKAGE__;

  $app->helper(multiplex => sub {
    my $c = shift;
    my $tx = $c->tx;
    return undef unless $tx->is_websocket;
    $c->rendered(101) unless $tx->established;
    return $c->stash->{'multiplex.multiplexer'} ||= Mojolicious::Plugin::Multiplex::Multiplexer->new(tx => $tx);
  });
}

1;

=head1 NAME

Mojolicious::Plugin::Multiplex - A websocket multiplexing layer for Mojolicious applications

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'Multiplex';

  get '/' => 'index';

  websocket '/multiplex' => sub {
    my $c = shift;
    my $multiplex = $c->multiplex;
    $multiplex->on(subscribe   => sub { ... });
    $multiplex->on(message     => sub { ... });
    $multiplex->on(unsubscribe => sub { ... });
  };

  __DATA__

  @@ index.html.ep

  %= javascript 'websocket_multiplex';
  <script>
    var ws = new WebSocket('<%= url_for('multiplex')->to_abs %>');
    var multiplex = new WebSocketMultiplex(ws);
    var foo = multiplex.channel('foo');
    foo.onmessage = function (e) { console.log('foo channel got: ' + e.data) };
    var bar = multiplex.channel('bar');
    bar.onmessage = function (e) { console.log('bar channel got: ' + e.data) };
  </script>

=head1 CAUTION

This module is in its infancy and things can and will change in incompatible ways until this warning is removed.
That said, the author is using it for real work so hopefully incompatible changes will be minimal (for his own sanity).

=head1 DESCRIPTION

L<Mojolicious::Plugin::Multiplex> implements a mechanism proposed by L<SockJS|https://github.com/sockjs/websocket-multiplex> for the multiplexing of data on a single websocket.
Rather than proposing both a protocol and a programmatic api to use it, they L<propose|https://www.rabbitmq.com/blog/2012/02/23/how-to-compose-apps-using-websockets/> a very simple protocol and reusing the api of the existing Javascript WebSocket api.
This has the immediate advantage (beyond having to dream up a client api) that existing front-end code that is written for a WebSocket can immediately use the multiplexer with no changes necessary.

Their proposal only includes a partially implemented reference implementation.
This module extends the protocol slightly in order to enough of the L<"WebSocket API"|https://developer.mozilla.org/en-US/docs/Web/API/WebSocket> to be useful.
More extensions may be necessary if the API is to be completely implemented, however those last few details are rarely used and will likely not be missed.

On the server-side the logic is entirely up to the application author.
The module simply parses the multiplexed messages and emits events in accordance with them.
A typical use case may be to relay message to a bus, subscribing and unsubscribing from topics that it presents.
Another might be to stream updates to multiple types of data (perhaps in multiple parts of a single page application).
(Indeed those might not be distinct cases from each other).

For reference, the distribution comes with an example which uses L<Mojo::Pg> as a message broker for a multi-channel chat application.
The example may also be seen on L<GitHub|https://github.com/jberger/Mojolicious-Plugin-Multiplex/blob/master/ex/vue_chat.pl>.

=head1 HELPERS

=head2 multiplex

  my $multiplex = $c->multiplex;

Establishes the WebSocket connection (if it hasn't been already) and returns an instance of L<Mojolicious::Plugin::Multiplex::Multiplexer>.
The multiplexer is attached to the websocket stream and begins listening for messages.
The multiplexer emits events for incoming messages and has methods to send outgoing messages; more details about those are contained in its own documentation.

Note that for each websocket connection the same instance of the multiplexer will be returned on any subsequent call.
Though not prevented, the user is highly discouraged from sending other traffic over any websocket connection that is managed by a multiplexer.

=head1 BUNDLED FILES

=head2 websocket_multiplex.js

  # in your template
  %= javascript 'websocket_multiplex.js';

  var ws = new WebSocket(url);
  var multiplex = new WebSocketMultiplex(ws);
  var channel = multiplex.channel(topic);

Bundled with this plugin is a javascript file which provides the front-end code to create a multiplexer entitled C<websocket_multiplex.js>.
It provides the new class C<WebSocketMultiplex> whose constructor takes as its only argument an existing WebSocket object.
This then is used to open new channel objects via the C<channel> method which takes a topic string as an arugment.
Topics can be almost any string, however they must not contain a comma (a limitation of the protocol).
The resulting channel objects implement the same API as a WebSocket (though they do not inherit from it).

The client-side multiplexer will also attempt to reconnect to closed sockets and when successful will automatically resubscribe to the channels that were subscribed.

N.B. This library is the least stable of the entire project.
Use with caution.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-Multiplex>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joel Berger

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The multiplexer protocol and javascript code (both extended by this project) are copyright their original authors and by their nature are assumed to be in the public domain.

=cut

__DATA__

@@ websocket_multiplex.js

// original at https://github.com/sockjs/websocket-multiplex/blob/master/multiplex_client.js

var WebSocketMultiplex = (function(){


    // ****

    var DumbEventTarget = function() {
        this._listeners = {};
    };
    DumbEventTarget.prototype._ensure = function(type) {
        if(!(type in this._listeners)) this._listeners[type] = [];
    };
    DumbEventTarget.prototype.addEventListener = function(type, listener) {
        this._ensure(type);
        this._listeners[type].push(listener);
    };
    DumbEventTarget.prototype.emit = function(type) {
        this._ensure(type);
        var args = Array.prototype.slice.call(arguments, 1);
        if(this['on' + type]) this['on' + type].apply(this, args);
        for(var i=0; i < this._listeners[type].length; i++) {
            this._listeners[type][i].apply(this, args);
        }
    };


    // ****

    var WebSocketMultiplex = function(ws) {
        this.ws = ws;
        this.channels = {};
        this.open();
    };

    WebSocketMultiplex.prototype.open = function() {
        var multiplex = this;

        if (multiplex.ws.readyState > WebSocket.OPEN) {
          multiplex.ws = new WebSocket(multiplex.ws.url);

          multiplex.ws.addEventListener('open', function(e) {
              multiplex.eachChannel(function(channel) {
                  setTimeout(function(){ channel.subscribe() }, 0);
              });
          });
        }

        multiplex.ws.addEventListener('close', function(e) {
            multiplex.eachChannel(function(channel) {
                channel.readyState = WebSocket.CONNECTING;
            });
            setTimeout(function(){ multiplex.open() }, 500);
        });

        multiplex.ws.addEventListener('message', function(e) {
            var t = e.data.split(',');
            var type = t.shift(), name = t.shift(),  payload = t.join();
            if(!(name in multiplex.channels)) {
                return;
            }
            var sub = multiplex.channels[name];

            switch(type) {
            case 'sta':
                if (payload === 'true') {
                    var was_open = sub.readyState === WebSocket.OPEN;
                    sub.readyState = WebSocket.OPEN;
                    if (! was_open) { sub.emit('open') }
                } else if (payload === 'false') {
                    var was_closed = sub.readyState === WebSocket.CLOSED;
                    sub.readyState = WebSocket.CLOSED;
                    delete multiplex.channels[name];
                    if (! was_closed) { sub.emit('close', {}) }
                }
                //TODO implement status request handler
                break;
            case 'uns':
                delete multiplex.channels[name];
                sub.emit('close', {});
                break;
            case 'msg':
                sub.emit('message', {data: payload});
                break;
            case 'err':
                sub.emit('error', payload);
                break;
            }
        });
    };

    WebSocketMultiplex.prototype.eachChannel = function(cb) {
        for (var channel in this.channels) {
            if (this.channels.hasOwnProperty(channel)) {
                console.log('setting callback for ' + channel);
                cb(this.channels[channel]);
            }
        }
    };

    WebSocketMultiplex.prototype.channel = function(raw_name) {
        var name = escape(raw_name);
        if (! this.channels[name] ) {
            this.channels[name] = new Channel(this, name);
        }
        return this.channels[name];
    };


    var Channel = function(multiplex, name) {
        DumbEventTarget.call(this);
        var that = this;
        this.multiplex = multiplex;
        var ws = multiplex.ws;
        this.name = name;
        this.readyState = WebSocket.CONNECTING;
        if(ws.readyState > WebSocket.CONNECTING) {
            setTimeout(function(){ that.subscribe() }, 0);
        } else {
            ws.addEventListener('open', function(){ that.subscribe() });
        }
    };
    Channel.prototype = new DumbEventTarget();

    Channel.prototype.subscribe = function () {
        this.multiplex.ws.send('sub,' + this.name);
    };
    Channel.prototype.send = function(data) {
        this.multiplex.ws.send('msg,' + this.name + ',' + data);
    };
    Channel.prototype.close = function() {
        this.readyState = WebSocket.CLOSING;
        this.multiplex.ws.send('uns,' + this.name);
    };

    return WebSocketMultiplex;
})();

