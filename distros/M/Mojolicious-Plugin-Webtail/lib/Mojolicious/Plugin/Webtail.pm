package Mojolicious::Plugin::Webtail;

use strict;
use warnings;
our $VERSION = '0.07';

use Mojo::Base 'Mojolicious::Plugin';
use Carp ();
use Encode ();

use constant DEFAULT_TAIL_OPTIONS => '-f -n 0';

has 'template' => <<'TEMPLATE';
<html><head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <title><%= $file %> - Webtail</title>
  %= stylesheet begin
  /* Stolen from https://github.com/r7kamura/webtail */
  *  {
    margin: 0;
    padding: 0;
  }
  body {
    margin: 1em 0;
    color: #ddd;
    background: #111;
  }
  pre {
    padding: 0 1em;
    line-height: 1.25;
    font-family: "Monaco", "Consolas", monospace;
  }
  #message {
    position:fixed;
    top:1em;
    right:1em;
  }
  % end
  %= javascript 'https://ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js'
  %= javascript begin
  $(function() {
    var autoscroll = true;
    // press 's' key to toggle autoscroll
    $(window).keydown(function(e) { if (e.keyCode == 83 ) autoscroll = (autoscroll) ? false : true });

    var ws = new (WebSocket || MozWebSocket)('<%= $ws_url %>');
    var timer_id;
    ws.onopen = function() {
      console.log('Connection opened');
      timer_id = setInterval(
        function() {
          console.log('Connection keepalive');
          ws.send('keepalive');
        },
        1000 * 240
      );
    };
    ws.onmessage = function(msg) {
      if (msg.data == '\n' && $('pre:last').text() == '\n') return;
      $('<pre>').text(msg.data).appendTo('body');
      if (autoscroll) $('html, body').scrollTop($(document).height());

      % if ($webtailrc) {
      // webtailrc
      <%== $webtailrc %>
      % }
    };
    ws.onclose = function() {
      console.warn('Connection closed');
      clearInterval(timer_id);
    };
    ws.onerror = function(msg) {
      console.error(msg.data);
    };
  });
  % end
</head><body>
<div id="message">press 's' to toggle autoscroll</div>
</body></html>
TEMPLATE

has 'file';
has 'webtailrc';
has 'tail_opts' => sub { DEFAULT_TAIL_OPTIONS };

has '_tail_stream';
has '_clients' => sub { +{} };

sub DESTROY {
    my $self = shift;
    $self->_tail_stream->close if $self->_tail_stream;
}

sub _prepare_stream {
    my ( $self, $app ) = @_;

    return if ( $self->_tail_stream );

    my ( $fh, $pid );
    my $read_from = 'STDIN';
    if ( $self->file ) {
        require Text::ParseWords;
        my @opts = Text::ParseWords::shellwords( $self->tail_opts );
        my @cmd  = ('tail', @opts, $self->file);
        $pid = open( $fh, '-|', @cmd ) or Carp::croak "fork failed: $!";
        $read_from = join ' ', @cmd;
    }
    else {
        $fh = *STDIN;
    }
    $app->log->debug("reading from: $read_from");

    my $stream    = Mojo::IOLoop::Stream->new($fh)->timeout(0);
    my $stream_id = Mojo::IOLoop->stream($stream);
    $stream->on( read => sub {
        my ($stream, $chunk) = @_;
        for my $key (keys %{ $self->_clients }) {
            my $tx = $self->_clients->{$key};
            next unless $tx->is_websocket;
            $tx->send( Encode::decode_utf8($chunk) );
            $app->log->debug( sprintf('sent %s', $key ) );
        }
    } );
    $stream->on( error => sub {
        $app->log->error( sprintf('error %s', $_[1] ) );
        Mojo::IOLoop->remove($stream_id);
        $self->_tail_stream(undef);
    });
    $stream->on( close => sub {
        $app->log->debug('close tail stream');
        if ($pid) {
            kill 'TERM', $pid if ( kill 0, $pid );
            waitpid( $pid, 0 );
        };
        Mojo::IOLoop->remove($stream_id);
        $self->_tail_stream(undef);
    });

    $self->_tail_stream($stream);
    $app->log->debug( sprintf('connected tail stream %s', $stream_id ) );
}

sub register {
    my $plugin = shift;
    my ( $app, $args ) = @_;

    $plugin->file( $args->{file} || '' );
    $plugin->webtailrc( $args->{webtailrc} || '' );
    $plugin->tail_opts( $args->{tail_opts} || DEFAULT_TAIL_OPTIONS );

    $app->hook(
        before_dispatch => sub {
            my $c    = shift;
            my $path = $c->req->url->path;

            return unless ($c->req->url->path =~ m|^/webtail/?$|);

            if ( $c->tx->is_websocket ) {
                $plugin->_prepare_stream($app);
                my $tx = $c->tx;
                $plugin->_clients->{"$tx"} = $tx;
                $c->app->log->debug( sprintf('connected %s', "$tx" ) );
                Mojo::IOLoop->stream( $tx->connection )->timeout(300)->on( timeout => sub {
                    $c->finish;
                    delete $plugin->_clients->{"$tx"};
                    $c->app->log->debug( sprintf('timeout %s', $tx ) );
                });
                $c->on( message => sub {
                    $c->app->log->debug( sprintf('message "%s" from %s', $_[1], $tx ) );
                } );
                $c->on( finish => sub {
                    delete $plugin->_clients->{"$tx"};
                    $c->app->log->debug( sprintf('finish %s', $tx ) );
                } );
                $c->res->headers->content_type('text/event-stream');
                return;
            }

            my $ws_url = $c->req->url->to_abs->scheme('ws')->to_string;
            $c->render(
                inline    => $plugin->template,
                ws_url    => $ws_url,
                webtailrc => ( $plugin->webtailrc ) ? Mojo::File->new( $plugin->webtailrc )->slurp : '',
                file      => $args->{file} || 'STDIN',
            );
        },
    );
    return $app;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Webtail - display tail to your browser

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin( 'Webtail', file => "/path/to/logfile", webtailrc => '/path/to/webtail.rc' );
  app->start;

  or

  > perl -Mojo -e 'a->plugin("Webtail", file => "/path/to/logfile", webtailrc => "/path/to/webtail.rc")->start' daemon

  or

  > tail -f /path/to/logfile | perl -Mojo -e 'a->plugin("Webtail", webtailrc => "/path/to/webtail.rc")->start' daemon

  and access "http://host:port/webtail" in your web browser.

=head1 DESCRIPTION

Mojolicious::Plugin::Webtail is display tail to your browser by WebSocket.

=head1 METHODS

L<Mojolicious::Plugin::Webtail> inherits all methods from L<Mojolicious::Plugin>.

=head1 OPTIONS

L<Mojolicious::Plugin::Webtail> supports the following options.

=head2 C<file>

displays the contents of C<file> or, by default, its C<STDIN>.

=head2 C<webtailrc>

define your custom callback in C<webtail> file.

the code in C<webtail> file is executed when a new line is inserted.

=head2 C<tail_opts>

define tail options.

default: '-f -n 0'

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<https://github.com/r7kamura/webtail>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
