package Test::Mojo::IRC;
use Mojo::Base -base;

use Mojo::File;
use Mojo::IOLoop::Server;
use Mojo::IRC;

$ENV{TEST_MOJO_IRC_SERVER_TIMEOUT} ||= $ENV{TEST_MOJO_IRC_SERVER} ? 10 : 4;

has server => '';

has welcome_message => <<'HERE';
:hybrid8.local NOTICE AUTH :*** Looking up your hostname...
:hybrid8.local NOTICE AUTH :*** Checking Ident
:hybrid8.local NOTICE AUTH :*** Found your hostname
:hybrid8.local NOTICE AUTH :*** No Ident response
HERE

sub on {
  my ($self, $irc, $event, $cb) = @_;
  push @{$self->{subscriptions}}, $irc, $event, $irc->on($event => $cb);
  $self;
}

sub run {
  my ($self, $reply_on, $cb) = @_;
  my $guard = Mojo::IOLoop->timer($ENV{TEST_MOJO_IRC_SERVER_TIMEOUT}, sub { Mojo::IOLoop->stop });
  my @subscriptions;

  local $self->{from_client}   = '';
  local $self->{reply_on}      = $reply_on;
  local $self->{subscriptions} = \@subscriptions;

  $self->$cb;
  Mojo::IOLoop->remove($guard);

  while (@subscriptions) {
    my ($irc, $event, $cb) = splice @subscriptions, 0, 3, ();
    $irc->unsubscribe($event => $cb);
  }

  $self;
}

sub start_server {
  my $self = shift;

  return $self->new->tap('start_server') unless ref $self;
  return $self->server if $self->server;
  return $ENV{TEST_MOJO_IRC_SERVER} if $ENV{TEST_MOJO_IRC_SERVER};

  my $port = Mojo::IOLoop::Server->generate_port;
  my $write;

  $write = sub {
    return unless length $self->{server_buf};
    return shift->write(substr($self->{server_buf}, 0, int(10 + rand 20), ''), sub { shift->$write });
  };

  $self->{server_id} = Mojo::IOLoop->server(
    {address => '127.0.0.1', port => $port},
    sub {
      my ($ioloop, $stream) = @_;

      $stream->on(
        read => sub {
          my ($stream, $buf) = @_;
          $self->{from_client} .= $buf;

          while ($buf =~ /[\015\012]/g) {
            last unless @{$self->{reply_on} || []};
            last unless $self->{from_client} =~ $self->{reply_on}[0];
            $self->_concat_server_buf($self->{reply_on}[1]);
            splice @{$self->{reply_on}}, 0, 2, ();
          }

          $stream->$write;
        }
      );

      $self->_concat_server_buf($self->welcome_message);
      $stream->$write;
    }
  );

  $self->{server_buf} = '';
  $self->server("127.0.0.1:$port")->server;
}

sub _concat_server_buf {
  my ($self, $buf) = @_;

  if (ref $buf eq 'ARRAY') {
    $buf = Mojo::Loader::data_section(@$buf == 1 ? ('main', @$buf) : @$buf);
  }
  elsif (ref $buf) {
    $buf = Mojo::File::path(split '/', $$buf)->slurp;
  }

  $buf =~ s/[\015\012]/\015\012/g;
  $self->{server_buf} .= $buf;
}

sub import {
  my $class  = shift;
  my $arg    = shift // '';
  my $caller = caller;

  return unless $arg =~ /^(?:-basic|-ua)$/;
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
  eval "require Mojo::IRC::UA;1" or die $@ if $arg eq '-ua';
  eval "package $caller; use Test::More; 1" or die $@;
}

1;

=encoding utf8

=head1 NAME

Test::Mojo::IRC - Module for testing Mojo::IRC

=head1 SYNOPSIS

  use Test::Mojo::IRC -basic;

  my $t   = Test::Mojo::IRC->start_server;
  my $irc = Mojo::IRC->new(server => $t->server);

  # simulate server/client communication
  $t->run(
    [
      # Send "welcome.irc" from the DATA section when client sends "NICK"
      qr{\bNICK\b} => [qw(main motd.irc)],
    ],
    sub {
      my $err;
      my $motd = 0;
      $t->on($irc, irc_rpl_motd => sub { $motd++ });
      $t->on($irc, irc_rpl_endofmotd => sub { Mojo::IOLoop->stop; }); # need to manually stop the IOLoop
      $irc->connect(sub { $err = $_[1]; });
      Mojo::IOLoop->start; # need to manually start the IOLoop
      is $err, "", "connected";
      is $motd, 3, "message of the day";
    },
  );

  done_testing;

  __DATA__
  @@ motd.irc
  :spectral.shadowcat.co.uk 375 test123 :- spectral.shadowcat.co.uk Message of the Day -
  :spectral.shadowcat.co.uk 372 test123 :- We scan all connecting clients for open proxies and other
  :spectral.shadowcat.co.uk 372 test123 :- exploitable nasties. If you don't wish to be scanned,
  :spectral.shadowcat.co.uk 372 test123 :- don't connect again, and sorry for scanning you this time.
  :spectral.shadowcat.co.uk 376 test123 :End of /MOTD command.

=head1 DESCRIPTION

L<Test::Mojo::IRC> is a module for making it easier to test L<Mojo::IRC>
applications.

=head1 ENVIRONMENT VARIABLES

=head2 TEST_MOJO_IRC_SERVER

C<TEST_MOJO_IRC_SERVER> can be set to point to a live server. If the variable
is set, L</start_server> will simply return L<TEST_MOJO_IRC_SERVER> instead
of setting up a server.

=head1 ATTRIBUTES

=head2 server

  $str = $self->server;

Returns the server address, "host:port", that L</start_server> set up.

=head2 welcome_message

  $str = $self->welcome_message;
  $self = $self->welcome_message($str);

Holds a message which will be sent to the client on connect.

=head1 METHODS

=head2 on

  $self->on($irc, $event, $cb);

Will attach events to the L<$irc|Mojo::IRC> object which is removed
after L</run> has completed. See L</SYNOPSIS> for example code.

=head2 run

  $self->run($reply_on, sub { my $self = shift });

Used to simulate communication between IRC server and client. The way this
works is that the C<$cb> will initiate L<connect|Mojo::IRC/connect> or
L<write|Mojo::IRC/write> to the server and the server will then respond
with the data from either L</welcome_message> or C<$reply_on> on these
events.

C<$reply_on> is an array-ref of regex/buffer pairs. Each time a message
from the client match the first regex in the C<$reply_on> array the
buffer will be sent back to the client and the regex/buffer will be removed.
This means that the order of the pairs are important. The buffer can be...

=over 4

=item * Scalar

Plain text.

=item * Scalar ref

Path to file on disk.

=item * Array ref

The module name and file passed on to L<Mojo::Loader/data_section>. The default
package is "main", meaning the two examples below is the same:

  $self->run([qr{JOIN}, ["join-reply.irc"]], sub { my $self = shift });
  $self->run([qr{JOIN}, ["main", "join-reply.irc"]], sub { my $self = shift });

=back

Note that starting and stopping the L<IOLoop|Mojo::IOLoop> is up to you, but
there is also a master timeout which will stop the IOLoop if running for too
long.

See L</SYNOPSIS> for example.

=head2 start_server

  $server = $self->start_server;
  $self   = Test::Mojo::IRC->start_server;

Will start a test server and return L</server>. It can also be called as
a class method which will return a new object.

=head2 import

  use Test::Mojo::IRC -basic;

Loading this module with "-basic" will import L<strict>, L<warnings>, L<utf8>,
L<Test::More> and 5.10 features into the caller namespace.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
