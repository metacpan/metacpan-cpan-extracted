use strict;
use warnings;
package Mojolicious::Plugin::Pubsub;
#ABSTRACT: Pubsub plugin for Mojolicious
$Mojolicious::Plugin::Pubsub::VERSION = '0.006';
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::IOLoop;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Util qw( b64_decode b64_encode deprecated );
use IO::Socket::UNIX;

my $client;
my $conf;

sub register {
  my ($self, $app, $cfg) = @_;

  $cfg->{cbs} = [];
  push @{ $cfg->{subs} }, $cfg->{cb} if exists $cfg->{cb};
  $cfg->{socket} = $app->home->child($app->moniker . '.pubsub') unless exists $cfg->{socket};
  $conf = $cfg;

  my $loop = Mojo::IOLoop->singleton;

  pipe my $in, my $out or die "Could not open pipe pair: $!";

  my $pid = fork();
  die "Could not fork: $!" if not defined $pid;

  if ($pid) {
    close $out;
    chomp(my $result = readline $in);
    close $in;

    die "Could not establish pubsub socket: $result" if $result ne 'DONE';
  } else {
    # now in fork
    close $in;
    $loop->reset;

    my @streams;

    unless (-e $conf->{socket} and IO::Socket::UNIX->new(Peer => $conf->{socket})) {
      my $server = eval { $loop->server(
        {path => $conf->{socket}} => sub {
          my (undef, $stream) = @_;
          push @streams, $stream;

          my $msg;
          $stream->on(
            read => sub {
              my ($stream, $bytes) = @_;
              $msg .= $bytes;

              while (length $msg) {
                if ($msg =~ s/^(.+\n)//) {
                  my $line = $1;
                  foreach my $str (@streams) { $str->write($line); }
                } else {
                  return;
                }
              }
            }
          );

          $stream->on(
            close => sub {
              @streams = grep $_ ne $_[0], @streams;
              $loop->stop unless @streams;
            }
          );

          $stream->timeout(0);
        }
      ); };

      if (not defined $server) {
        print $out $@;
        close $out;
        exit;
      }
    }

    print $out "DONE\n";
    close $out;

    $loop->start unless $loop->is_running;
    exit;
  }

  $loop->next_tick(sub { _connect() });

  $app->helper(
    'pubsub.publish' => sub {
      my $self = shift;
      my $msg = b64_encode(encode_json([@_]), "");

      _send($msg . "\n");

      return $self;
    }
  );

  $app->helper(
    'pubsub.subscribe' => sub {
      my $self = shift;
      my $cb = shift;

      push @{ $conf->{subs} }, $cb;

      return $self;
    }
  );

  $app->helper(
    'pubsub.unsubscribe' => sub {
      my $self = shift;
      my $cb = shift;

      @{ $conf->{subs} } = grep { $_ != $cb } @{ $conf->{subs} };

      return $self;
    }
  );

  $app->helper(
    publish => sub {
      deprecated '->publish is deprecated in favour of ->pubsub->publish';
      shift->pubsub->publish(@_);
    });
  $app->helper(
    subscribe => sub {
      deprecated '->subscribe is deprecated in favour of ->pubsub->subscribe';
      shift->pubsub->subscribe(@_);
    });
  $app->helper(
    unsubscribe => sub {
      deprecated '->unsubscribe is deprecated in favour of ->pubsub->unsubscribe';
      shift->pubsub->unsubscribe(@_);
    });

}

sub _send {
  my ($msg) = @_;

  if (not defined $client) {
    return _connect(sub { $_[0]->write($msg); });
  }

  $client->write($msg);
}

sub _connect {

  my $cb = shift;

  Mojo::IOLoop->singleton->client(
    { path => $conf->{socket} } => sub {
      my ($loop, $err, $stream) = @_;
      die sprintf "Could not connect to %s: %s", $conf->{socket}, $err if defined $err;

      if (defined $client) {
        $stream->close();
        $cb->($client) if defined $cb;

        return;
      }

      $client = $stream;

      my $msg;
      $stream->on(read => sub {
        my ($stream, $bytes) = @_;

        $msg .= $bytes;

        while (length $msg) {
          if ($msg =~ s/^(.+)\n//) {
            my $b64 = $1;
            my $args = decode_json(b64_decode($b64));
            foreach my $subscriber (@{ $conf->{subs} }) {
              $subscriber->(@{ $args });
            }
          }
          else {
            return
          }

        }
      });

      $stream->timeout(0);

      $cb->($stream) if defined $cb;

    }
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Pubsub - Pubsub plugin for Mojolicious

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # Mojolicious
  my $pubsub = $app->plugin('Pubsub', { cb => sub { print "Message: $_[0]\n"; }, socket => 'myapp.pubsub', });
  $app->pubsub->publish("message");
  
  # Mojolicious::Lite
  my $pubsub = plugin Pubsub => { cb => sub { print "Message: $_[0]\n"; }, socket => 'myapp.pubsub', };
  app->pubsub->publish("message");

=head1 DESCRIPTION

Easy way to add pubsub to your L<Mojolicious> apps; it hooks into the L<Mojo::IOLoop> to send and receive messages asynchronously.

Each time you run your L<Mojolicious> app and the plugin gets loaded, it'll spawn a new daemon that'll try to connect to the socket if it already exists, and if it fails it will replace the socket assuming that the underlying daemon is dead. If it succeeds, it will cancel the new daemon and leave the old one to continue doing its work.

B<Note:> MSWin32 is not supported because it has no proper C<UNIX> socket support.

=head1 NAME

Mojolicious::Plugin::Pubsub - Pubsub plugin for Mojolicious

=head1 OPTIONS

=head2 cb

Takes a callback C<CODE> reference.

=head2 socket

A path to a C<UNIX> socket used to communicate between the publishers. By default this will be C<< $app->home->child($app->moniker . '.pubsub') >>.

=head1 HELPERS

=head2 pubsub->publish

  $c->pubsub->publish("message");
  $c->pubsub->publish(@args);

Publishes a message that the subscribing callbacks will receive.

=head2 pubsub->subscribe

  $c->pubsub->subscribe($cb);

Add the C<$cb> code reference to the callbacks that get published messages.

=head2 pubsub->unsubscribe

  $c->pubsub->unsubscribe($cb);

Remove the C<$cb> code reference from the callbacks that get published messages.

=head1 SUBSCRIBERS

  my $subscriber = sub {
    my @args = @_;
    ...
  };

Subscribers sent to the C<cb> option, or the C<< pubsub->subscribe >> helper should simply be C<CODE> references that handle the arguments passed in. The C<@args> will be the same as what was passed in to the C<< pubsub->publish >> helper, except they will have gotten C<JSON> encoded via L<Mojo::JSON> on the way, so only data structures that consist of regular scalars, arrays, hashes, and objects that implement C<TO_JSON> or that stringify will work correctly. See L<Mojo::JSON> for more details.

=head1 METHODS

=head2 register

  my $pubsub = $plugin->register(Mojolicious->new, { cb => sub { ... }, socket => $path });

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Redis2>.

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
