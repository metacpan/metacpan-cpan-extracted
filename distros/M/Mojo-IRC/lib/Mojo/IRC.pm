package Mojo::IRC;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::Promise;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use IRC::Utils   ();
use Parse::IRC   ();
use Scalar::Util ();
use Unicode::UTF8;
use constant DEBUG        => $ENV{MOJO_IRC_DEBUG}     || 0;
use constant DEFAULT_CERT => $ENV{MOJO_IRC_CERT_FILE} || catfile dirname(__FILE__), 'mojo-irc-client.crt';
use constant DEFAULT_KEY  => $ENV{MOJO_IRC_KEY_FILE}  || catfile dirname(__FILE__), 'mojo-irc-client.key';

our $VERSION = '0.46';

our %NUMERIC2NAME = (470 => 'ERR_LINKCHANNEL');

my %CTCP_QUOTE = ("\012" => 'n', "\015" => 'r', "\0" => '0', "\cP" => "\cP");

my @DEFAULT_EVENTS = qw(
  irc_ping irc_nick irc_notice irc_rpl_welcome err_nicknameinuse
  irc_rpl_isupport ctcp_ping ctcp_time ctcp_version
);

has connect_timeout => sub { $ENV{MOJO_IRC_CONNECT_TIMEOUT} || 30 };
has ioloop          => sub { Mojo::IOLoop->singleton };
has local_address   => '';
has name            => 'Mojo IRC';
has nick            => sub { shift->_build_nick };
has parser          => sub { Parse::IRC->new; };
has pass            => '';
has real_host       => '';

has server_settings => sub {
  return {chantypes => '#', prefix => '(ov)@+'};
};

has tls => undef;
has user => sub { $ENV{USER} || getlogin || getpwuid($<) || 'anonymous' };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->on(message => \&_legacy_dispatch_message);
  return $self;
}

sub server {
  my ($self, $server) = @_;
  my $old = $self->{server} || '';

  Scalar::Util::weaken($self);
  return $old unless defined $server;
  return $self if $old and $old eq $server;
  $self->{server} = $server;
  return $self unless $self->{stream_id};
  $self->disconnect(sub {
    $self->connect(sub { });
  });
  $self;
}

sub connect {
  my ($self, $cb) = @_;
  my ($host, $port) = split /:/, $self->server;
  my @extra;

  if (!$host) {
    $self->ioloop->next_tick(sub { $self->$cb('server() is not set.') });
    return $self;
  }
  if ($self->{stream_id}) {
    $self->ioloop->next_tick(sub { $self->$cb('') });
    return $self;
  }

  if ($self->local_address) {
    push @extra, local_address => $self->local_address;
  }
  if (my $tls = $self->tls) {
    push @extra, tls      => 1;
    push @extra, tls_ca   => $tls->{ca} if $tls->{ca};     # not sure why this should be supported, but adding it anyway
    push @extra, tls_cert => $tls->{cert} || DEFAULT_CERT;
    push @extra, tls_key  => $tls->{key} || DEFAULT_KEY;
    push @extra, tls_verify => 0x00 if $tls->{insecure}; # Mojolicious < 9.0
    push @extra, tls_options => {SSL_verify_mode => 0x00} if $tls->{insecure}; # Mojolicious >= 9.0
  }

  $port ||= 6667;
  $self->{buffer} = '';
  $self->{debug_key} ||= "$host:$port";
  $self->register_default_event_handlers;

  Scalar::Util::weaken($self);
  $self->{stream_id} = $self->ioloop->client(
    address => $host,
    port    => $port,
    timeout => $self->connect_timeout,
    @extra,
    sub {
      my ($loop, $err, $stream) = @_;

      if ($err) {
        delete $self->{stream_id};
        return $self->$cb($err);
      }

      $stream->timeout(0);
      $stream->on(
        close => sub {
          $self or return;
          warn "[$self->{debug_key}] : close\n" if DEBUG;
          delete $self->{stream};
          delete $self->{stream_id};
          $self->emit('close');
        }
      );
      $stream->on(
        error => sub {
          $self or return;
          $self->ioloop or return;
          $self->ioloop->remove(delete $self->{stream_id});
          $self->emit(error => $_[1]);
        }
      );
      $stream->on(read => sub { $self->_read($_[1]) });

      $self->{stream} = $stream;
      $self->ioloop->next_tick(sub {
        my @promises;
        push @promises, $self->write_p(PASS => $self->pass) if length $self->pass;
        push @promises, $self->write_p(NICK => $self->nick);
        push @promises, $self->write_p(USER => $self->user, 8, '*', ':' . $self->name);
        Mojo::Promise->all(@promises)->finally(sub { $self->$cb('') });
      });
    }
  );

  return $self;
}

sub ctcp {
  my $self = shift;
  local $_ = join ' ', @_;
  s/([\012\015\0\cP])/\cP$CTCP_QUOTE{$1}/g;
  s/\001/\\a/g;
  ":\001${_}\001";
}

sub disconnect {
  my ($self, $cb) = @_;

  if (my $tid = delete $self->{ping_tid}) {
    $self->ioloop->remove($tid);
  }

  if ($self->{stream}) {
    Scalar::Util::weaken($self);
    $self->{stream}->write(
      "QUIT\r\n",
      sub {
        $self->{stream}->close;
        $self->$cb if $cb;
      }
    );
  }
  elsif ($cb) {
    $self->ioloop->next_tick(sub { $self->$cb });
  }

  $self;
}

sub register_default_event_handlers {
  my $self = shift;

  for my $event (@DEFAULT_EVENTS) {
    $self->on($event => $self->can($event)) unless $self->has_subscribers($event);
  }

  return $self;
}

sub track_any {
  warn 'DEPRECATED! Just listen to $self->on(message => sub {}) instead.';
  my $self = shift;
  return $self->{track_any} || 0 unless @_;
  $self->{track_any} = shift;
  $self;
}

sub write {
  no warnings 'utf8';
  my $cb   = ref $_[-1] eq 'CODE' ? pop : sub { };
  my $self = shift;
  my $buf  = Unicode::UTF8::encode_utf8(join(' ', @_), sub { $_[0] });

  Scalar::Util::weaken($self);
  if (ref $self->{stream}) {
    warn "[$self->{debug_key}] <<< $buf\n" if DEBUG;
    $self->{stream}->write("$buf\r\n", sub { $self->$cb(''); });
  }
  else {
    $self->ioloop->next_tick(sub { $self->$cb('Not connected.') });
  }

  $self;
}

sub write_p {
  my ($self, @args) = @_;
  my $p = Mojo::Promise->new->ioloop($self->ioloop);
  $self->write(@args, sub { length $_[1] ? $p->reject($_[1]) : $p->resolve(1) });
  return $p;
}

sub ctcp_ping {
  my ($self, $message) = @_;
  my $ts   = $message->{params}[1];
  my $nick = IRC::Utils::parse_user($message->{prefix});

  return $self unless $ts;
  return $self->write('NOTICE', $nick, $self->ctcp(PING => $ts));
}

sub ctcp_time {
  my ($self, $message) = @_;
  my $nick = IRC::Utils::parse_user($message->{prefix});

  $self->write(NOTICE => $nick, $self->ctcp(TIME => scalar localtime));
}

sub ctcp_version {
  my ($self, $message) = @_;
  my $nick = IRC::Utils::parse_user($message->{prefix});

  $self->write(NOTICE => $nick, $self->ctcp(VERSION => 'Mojo-IRC', $VERSION));
}

sub irc_nick {
  my ($self, $message) = @_;
  my $old_nick = ($message->{prefix} =~ /^[~&@%+]?(.*?)!/)[0] || '';

  if (lc $old_nick eq lc $self->nick) {
    $self->nick($message->{params}[0]);
  }
}

sub irc_notice {
  my ($self, $message) = @_;

  # NOTICE AUTH :*** Ident broken or disabled, to continue to connect you must type /QUOTE PASS 21105
  if ($message->{params}[0] =~ m!Ident broken.*QUOTE PASS (\S+)!) {
    $self->write(QUOTE => PASS => $1);
  }
}

sub irc_ping {
  my ($self, $message) = @_;
  $self->write(PONG => $message->{params}[0]);
}

sub irc_rpl_isupport {
  my ($self, $message) = @_;
  my $params          = $message->{params};
  my $server_settings = $self->server_settings;
  my %got;

  for my $i (1 .. @$params - 1) {
    next unless $params->[$i] =~ /([A-Z]+)=?(\S*)/;
    my ($k, $v) = (lc $1, $2);
    $got{$k} = 1;
    $server_settings->{$k} = $v || 1;
  }
}

sub irc_rpl_welcome {
  my ($self, $message) = @_;
  $self->nick($message->{params}[0]);

  Scalar::Util::weaken($self);
  $self->real_host($message->{prefix});
  $self->{ping_tid} ||= $self->ioloop->recurring(
    $self->{ping_pong_interval} || 60,    # $self->{ping_pong_interval} is EXPERIMENTAL
    sub {
      $self->write(PING => $self->real_host);
    }
  );
}

sub err_nicknameinuse {
  my ($self, $message) = @_;
  my $nick = $message->{params}[1];

  $self->nick($nick . '_');
  $self->write(NICK => $self->nick, sub { });
}

sub DESTROY {
  my $self   = shift;
  my $ioloop = $self->ioloop or return;
  my $tid    = $self->{ping_tid};
  my $sid    = $self->{stream_id};

  $ioloop->remove($sid) if $sid;
  $ioloop->remove($tid) if $tid;
}

sub _build_nick {
  my $nick = shift->user;
  $nick =~ s![^a-z_]!_!g;
  $nick;
}

sub _dispatch_message {
  my ($self, $msg) = @_;
  $self->emit(irc_any => $msg) if $self->{track_any};    # will be deprecated
  $self->emit(message => $msg);
}

sub _legacy_dispatch_message {
  my ($self, $msg) = @_;
  my $event = $msg->{event};

  $event = "irc_$event" unless $event =~ /^(ctcp|err)_/;
  warn "[$self->{debug_key}] === $event\n" if DEBUG == 2;
  $self->emit($event => $msg);
}

# Can be used in unittest to mock input data:
# $irc->_read($bytes);
sub _read {
  my $self = shift;

  no warnings 'utf8';
  $self->{buffer} .= Unicode::UTF8::decode_utf8($_[0], sub { $_[0] });

CHUNK:
  while ($self->{buffer} =~ s/^([^\015\012]+)[\015\012]//m) {
    warn "[$self->{debug_key}] >>> $1\n" if DEBUG;
    my $msg = $self->parser->parse($1);
    my $cmd = $msg->{command} or next CHUNK;
    $msg->{command} = $NUMERIC2NAME{$cmd} || IRC::Utils::numeric_to_name($cmd) || $cmd if $cmd =~ /^\d+$/;
    $msg->{event} = lc $msg->{command};
    $self->_dispatch_message($msg);
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::IRC - IRC Client for the Mojo IOLoop

=head1 VERSION

0.46

=head1 SYNOPSIS

  my $irc = Mojo::IRC->new(
              nick => 'test123',
              user => 'my name',
              server => 'irc.perl.org:6667',
            );

  $irc->on(irc_join => sub {
    my($self, $message) = @_;
    warn "yay! i joined $message->{params}[0]";
  });

  $irc->on(irc_privmsg => sub {
    my($self, $message) = @_;
    say $message->{prefix}, " said: ", $message->{params}[1];
  });

  $irc->connect(sub {
    my($irc, $err) = @_;
    return warn $err if $err;
    $irc->write(join => '#mojo');
  });

  Mojo::IOLoop->start;

=head1 DESCRIPTION

L<Mojo::IRC> is a non-blocking IRC client using L<Mojo::IOLoop> from the
wonderful L<Mojolicious> framework.

It features IPv6 and TLS, with additional optional modules:
L<IO::Socket::IP> and L<IO::Socket::SSL>.

By default this module will only emit standard IRC events, but by
settings L</parser> to a custom object it will also emit CTCP events.
Example:

  my $irc = Mojo::IRC->new;
  $irc->parser(Parse::IRC->new(ctcp => 1);
  $irc->on(ctcp_action => sub {
    # ...
  });

It will also set up some default events: L</ctcp_ping>, L</ctcp_time>,
and L</ctcp_version>.

This class inherits from L<Mojo::EventEmitter>.

=head1 TESTING

The module L<Test::Mojo::IRC> is useful if you want to write tests without
having a running IRC server.

L<MOJO_IRC_OFFLINE> (from v0.20) is now DEPRECATED in favor of
L<Test::Mojo::IRC>.

=head1 EVENTS

=head2 close

  $self->on(close => sub { my ($self) = @_; });

Emitted once the connection to the server closes.

=head2 error

  $self->on(error => sub { my ($self, $err) = @_; });

Emitted once the stream emits an error.

=head2 message

  $self->on(message => sub { my ($self, $msg) = @_; });

Emitted when a new IRC message arrives. Will dispatch to a default handler,
which will again emit L</err_event_name> L</ctcp_event_name> and
L</irc_event_name> below.

Here is an example C<$msg>:

  {
    command  => "PRIVMSG",
    event    => "privmsg",
    params   => ["#convos", "hey!"],
    prefix   => "jan_henning",
    raw_line => ":jan_henning PRIVMSG #convos :hey",
  }

=head2 err_event_name

Events that start with "err_" are emitted when there is an IRC response that
indicates an error. See L<Mojo::IRC::Events> for sample events.

=head2 ctcp_event_name

Events that start with "ctcp_" are emitted if the L</parser> can understand
CTCP messages, and there is a CTCP response.

  $self->parser(Parse::IRC->new(ctcp => 1);

See L<Mojo::IRC::Events> for sample events.

=head2 irc_event_name

Events that start with "irc_" are emitted when there is a normal IRC response.
See L<Mojo::IRC::Events> for sample events.

=head1 ATTRIBUTES

=head2 connect_timeout

  $int = $self->connect_timeout;
  $self = $self->connect_timeout(60);

Maximum amount of time in seconds establishing a connection may take before
getting canceled, defaults to the value of the C<MOJO_IRC_CONNECT_TIMEOUT>
environment variable or 30.

=head2 ioloop

Holds an instance of L<Mojo::IOLoop>.

=head2 local_address

  $str = $self->local_address;
  $self = $self->local_address("10.20.30.40");

Local address to bind to. See L<Mojo::IOLoop::Client/local_address>.

=head2 name

The name of this IRC client. Defaults to "Mojo IRC".

=head2 nick

IRC nick name accessor. Default to L</user>.

=head2 parser

  $self = $self->parser($obj);
  $self = $self->parser(Parse::IRC->new(ctcp => 1));
  $obj = $self->parser;

Holds a L<Parse::IRC> object by default.

=head2 pass

Password for authentication

=head2 real_host

Will be set by L</irc_rpl_welcome>. Holds the actual hostname of the IRC
server that we are connected to.

=head2 server

Server name and, optionally, a port to connect to. Changing this while
connected to the IRC server will issue a reconnect.

=head2 server_settings

  $hash = $self->server_settings;

Holds information about the server. See
L<https://github.com/jhthorsen/mojo-irc/blob/master/t/ua-channel-users.t> for
example data structure.

Note that this attribute is EXPERIMENTAL and the structure of the values it
holds.

=head2 user

IRC username. Defaults to current logged in user or falls back to "anonymous".

=head2 tls

  $self->tls(undef) # disable (default)
  $self->tls({}) # enable

Default is "undef" which disables TLS. Setting this to an empty hash will
enable TLS and this module will load in default certs. It is also possible
to set custom cert/key:

  $self->tls({ cert => "/path/to/client.crt", key => ... })

This can be generated using

  # certtool --generate-privkey --outfile client.key
  # certtool --generate-self-signed --load-privkey client.key --outfile client.crt

To disable the verification of server certificates, the "insecure" option
can be set:

  $self->tls({insecure => 1});

=head1 METHODS

=head2 connect

  $self = $self->connect(\&callback);

Will log in to the IRC L</server> and call C<&callback>. The
C<&callback> will be called once connected or if connect fails. The second
argument will be an error message or empty string on success.

=head2 ctcp

  $str = $self->ctcp(@str);

This message will quote CTCP messages. Example:

  $self->write(PRIVMSG => nickname => $self->ctcp(TIME => time));

The code above will write this message to IRC server:

  PRIVMSG nickname :\001TIME 1393006707\001

=head2 disconnect

  $self->disconnect(\&callback);

Will disconnect form the server and run the callback once it is done.

=head2 new

  $self = Mojo::IRC->new(%attrs);

Object constructor.

=head2 register_default_event_handlers

  $self->register_default_event_handlers;

This method sets up the default L</DEFAULT EVENT HANDLERS> unless someone has
already subscribed to the event.

=head2 write

  $self->write(@str, \&callback);

This method writes a message to the IRC server. C<@str> will be concatenated
with " " and "\r\n" will be appended. C<&callback> is called once the message is
delivered over the stream. The second argument to the callback will be
an error message: Empty string on success and a description on error.

=head2 write_p

  $promise = $self->write_p(@str);

Like L</"write">, but returns a L<Mojo::Promise> instead of taking a callback.
The promise will be resolved on success, or rejected with the error message on
error.

=head1 DEFAULT EVENT HANDLERS

=head2 ctcp_ping

Will respond to the sender with the difference in time.

  Ping reply from $sender: 0.53 second(s)

=head2 ctcp_time

Will respond to the sender with the current localtime. Example:

  TIME Fri Feb 21 18:56:50 2014

NOTE! The localtime format may change.

=head2 ctcp_version

Will respond to the sender with:

  VERSION Mojo-IRC $VERSION

NOTE! Additional information may be added later on.

=head2 irc_nick

Used to update the L</nick> attribute when the nick has changed.

=head2 irc_notice

Responds to the server with "QUOTE PASS ..." if the notice contains "Ident
broken...QUOTE PASS...".

=head2 irc_ping

Responds to the server with "PONG ...".

=head2 irc_rpl_isupport

Used to populate L</server_settings> with information about the server.

=head2 irc_rpl_welcome

Used to get the hostname of the server. Will also set up automatic PING
requests to prevent timeout and update the L</nick> attribute.

=head2 err_nicknameinuse

This handler will add "_" to the failed nick before trying to register again.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Marcus Ramberg - C<mramberg@cpan.org>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
