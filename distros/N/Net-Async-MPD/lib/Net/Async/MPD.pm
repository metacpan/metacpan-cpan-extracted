package Net::Async::MPD;

use strict;
use warnings;

our $VERSION = '0.005';

use IO::Async::Loop;
use IO::Async::Stream;
use IO::Socket::IP;
use Future::Utils qw( repeat );
use Scalar::Util qw( weaken );
use Carp;

use namespace::clean;

use Moo;
use MooX::HandlesVia;
with 'Role::EventEmitter';

use Types::Standard qw(
  InstanceOf Int ArrayRef HashRef Str Maybe Bool CodeRef
);

use Log::Any;
my $log = Log::Any->get_logger( category => __PACKAGE__ );

has auto_connect => (
  is => 'ro',
  isa => Bool,
  default => 0,
);

has state => (
  is => 'rw',
  isa => Str,
  init_arg => undef,
  default => 'created',
  trigger => sub {
    $_[0]->emit( state => $_[0]->{state} );
  },
);

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has read_queue => (
  is => 'ro',
  isa => ArrayRef [CodeRef],
  lazy => 1,
  init_arg => undef,
  default => sub { [] },
  handles_via => 'Array',
  handles => {
    push_read    => 'push',
    pop_read     => 'pop',
    shift_read   => 'shift',
    unshift_read => 'unshift',
  },
);

has password => (
  is => 'ro',
  isa => Maybe[Str],
  lazy => 1,
);

has port => (
  is => 'ro',
  isa => Int,
  lazy => 1,
  default => sub { $ENV{MPD_PORT} // 6600 },
);

has host => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => sub { $ENV{MPD_HOST} // 'localhost' },
);

sub version { $_[0]->{version} };

sub _parse_block {
  my $self = shift;

  return sub {
    my ( $handle, $buffref, $eof ) = @_;

    while ( $$buffref =~ s/^(.*)\n// ) {
      my $line = $1;

      if ($line =~ /\w/) {
        $log->tracef('< %s', $line);
        if ($line =~ /^OK/) {
          if ($line =~ /OK MPD (.*)/) {
            $log->trace('Connection established');
            $self->{version} = $1;

            $self->send( password => $self->password )
              if $self->password;

            $self->state( 'ready' );
          }
          else {
            pop @{$self->{mpd_buffer}} unless @{$self->{mpd_buffer}[-1]};
            $self->shift_read->( 1, $self->{mpd_buffer} );
            $self->{mpd_buffer} = [[]];
          }
        }
        elsif ($line =~ /^list_OK/) {
          push @{$self->{mpd_buffer}}, [];
        }
        elsif ($line =~ /^ACK/) {
          $self->shift_read->( 0, $line );
          $self->{mpd_buffer} = [[]];
          last;
        }
        else {
          push @{$self->{mpd_buffer}[-1]}, $line;
        }
      }
    }

    return 0;
  };
}

# Set up response parsers for each command
my $parsers = { none => sub { @_ } };
{
  my $item = sub {
    return {
      map {
        my ($key, $value) = split /: /, $_, 2;
        $key => $value;
      } @{$_[0]}
    };
  };

  my $flat_list = sub { [ map { (split /: /, $_, 2)[1] } @{$_[0]} ] };

  my $base_list = sub {
    my @main_keys = @{shift()};
    my @list_keys = @{shift()};
    my @lines     = @{shift()};

    my @return;
    my $item = {};

    foreach my $line (@lines) {
      my ($key, $value) = split /: /, $line, 2;

      if ( grep { /$key/ } @main_keys ) {
        push @return, $item if defined $item->{$key};
        $item = { $key => $value };
      }
      elsif ( grep { /$key/ } @list_keys ) {
        unless (defined $item->{$key}) {
          $item->{$key} = []
        }
        push @{$item->{$key}}, $value;
      }
      else {
        $item->{$key} = $value;
      }
    }
    push @return, $item if keys %{$item};

    return \@return;
  };

  my $grouped_list = sub {
    my @lines = @{shift()};

    # Our main category comes at the top of the list of lines
    my ($main) = split /:\s+/, $lines[0], 2;

    # Make a list of any other categories we might have
    my @categories;
    foreach (@lines) {
      my ($key) = split /:\s+/, $_, 2;
      if ($key eq $main) {
        last if @categories;
      }
      else {
        push @categories, $key;
      };
    }

    my $return = {};

    while (@lines) {
      # Generate a has with all the data returned for a single item
      # This will be over several lines if we are grouping
      my $item = do {
        my $set;
        my %missing_keys = map { $_ => 1 } $main, @categories;

        while ( my $line = shift @lines ) {
          my ($key, $value) = split /:\s+/, $line, 2;

          $set->{$key} = $value;
          delete $missing_keys{$key};

          last unless %missing_keys;
        }

        $set;
      };

      # Find or create the array of results we need to push the data into
      my $pointer = $return;
      for my $category (@categories) {
        my $value = $item->{$category} // '';
        $pointer = $pointer->{$category}{$value} //= {};
      }

      push @{ $pointer->{$main} //= [] }, delete $item->{$main};
    }

    return $return;
  };

  # Untested commands: what do they return?
  # consume
  # crossfade

  my $file_list = sub { $base_list->( [qw( directory file )], [], @_ ) };

  $parsers->{$_} = $flat_list foreach qw(
    commands notcommands channels tagtypes urlhandlers listplaylist
  );

  $parsers->{$_} = $item foreach qw(
    currentsong stats idle status addid update
    readcomments replay_gain_status rescan
  );

  $parsers->{$_} = $file_list foreach qw(
    find playlistinfo listallinfo search find playlistid playlistfind
    listfiles plchanges listplaylistinfo playlistsearch listfind
  );

  $parsers->{list} = $grouped_list;

  foreach (
      [ outputs        => [qw( outputid )],  [] ],
      [ plchangesposid => [qw( cpos )],      [] ],
      [ listplaylists  => [qw( playlist )],  [] ],
      [ listmounts     => [qw( mount )],     [] ],
      [ listneighbors  => [qw( neighbor )],  [] ],
      [ listall        => [qw( directory )], [qw( file )] ],
      [ readmessages   => [qw( channel )],   [qw( message )] ],
      [ lsinfo         => [qw( directory file playlist )], [] ],
      [ decoders       => [qw( plugin )], [qw( suffix mime_type )] ],
    ) {

    my ($cmd, $header, $list) = @{$_};
    $parsers->{$cmd} = sub { $base_list->( $header, $list, @_ ) };
  }

  $parsers->{playlist} = sub {
    my $lines = [ map { s/^\w*?://; $_ } @{shift()} ];
    $flat_list->( $lines, @_ )
  };

  $parsers->{count} = sub {
    my $lines = shift;
    my ($main) = split /:\s+/, $lines->[0], 2;
    $base_list->( [ $main ], [qw( )], $lines, @_ )
  };

  $parsers->{sticker} = sub {
    my $lines = shift;
    return {} unless scalar @{$lines};

    my $single = ($lines->[0] !~ /^file/);

    my $base = $base_list->( [qw( file )], [qw( sticker )], $lines, @_ );
    my $return = [ map {
      $_->{sticker} = { map { split(/=/, $_, 2) } @{$_->{sticker}} }; $_;
    } @{$base} ];

    return $single ? $return->[0] : $return;
  };
}

sub idle {
  my ($self, @subsystems) = @_;

  $self->{idle_future} = $self->loop->new_future;

  weaken $self;
  repeat {
    $self->send( idle => @subsystems, sub {
      $self->emit( shift->{changed} );
    });
  } until => sub { $self->{idle_future}->is_ready };

  return $self->{idle_future};
}

sub noidle {
  my ($self) = @_;

  my $idle = $self->{idle_future};
  return unless defined $idle;
  return if $idle->is_ready;

  $self->send( 'noidle' );
  $idle->done;

  return;
}

sub send {
  my $self = shift;

  my $opt  = ( ref $_[0] eq 'HASH' ) ? shift : {};
  my $cb = pop if ref $_[-1] eq 'CODE';
  my (@commands) = @_;

  croak 'Need commands to send'
    unless @commands;

  # Normalise input
  if (ref $commands[0] eq 'ARRAY') {
    @commands = map {
      ( ref $_ eq 'ARRAY' ) ? join( q{ }, @{$_} ) : $_;
    } @{$commands[0]};
  }
  else {
    @commands = join q{ }, @commands;
  }

  my $command = '';
  # Remove underscores from (most) command names
  @commands = map {
    my $args;
    ($command, $args) = split /\s/, $_, 2;
    $command =~ s/_//g unless $command =~ /^(replay_gain_|command_list)/;
    $args //= q{};
    $command . ($args ne q{} ? " $args" : q{});
  } @commands;

  # Ensure a command list if sending multiple commands
  if (scalar @commands > 1) {
    my $list = $opt->{list} // 1;
    my $list_start =
      'command_list' . ( $list ? '_ok' : q{} ) . '_begin';

    unshift @commands, $list_start
      unless $commands[0] =~ /^command_list/;
    push @commands, 'command_list_end'
      unless $commands[-1] =~ /^command_list/;
  }

  my $parser;

  if (defined $opt->{parser}) {
    my $input = delete $opt->{parser};
    $parser = (ref $input eq 'CODE') ? $input : $parsers->{$input};
    croak 'Not a code reference or recognised parser name'
      unless defined $parser;
  }
  else {
    $parser = sub {
      my ($input, $commands) = @_;

      my @result =  map {
        my $command;
        do { $command = shift @{$commands} }
          until !defined $command or $command !~ /^command_list/;

        my $sub = $parsers->{$command // ''} // $parsers->{none};

        $sub->( $input->[$_] );
      } 0 .. $#{$input};

      return @result
    };
  }

  my $future = $self->loop->new_future;
  $future->on_done( $cb ) if $cb;

  return $future->fail('No connection to MPD server' )
    unless $self->{mpd_handle};

  $self->push_read( sub {
    my ($success, $result) = @_;

    if ($success) {
      $future->done( $parser->(
        $result, [ map { my ($name) = split /\s/, $_, 2 } @commands ]
      ));
    }
    else {
      $self->emit( error => $result );
      $future->fail( $result );
    }
  });

  $log->tracef( '> %s', $_ ) foreach @commands;
  $self->{mpd_handle}->write( join("\n", @commands) . "\n" );

  return $future;
}

sub get { shift->send( @_ )->get }

sub until {
  my ($self, $name, $check, $cb) = @_;

  weaken $self;
  my $wrapper;
  $wrapper = sub {
    if ($check->(@_)) {
      $self->unsubscribe($name => $wrapper);
      $cb->(@_);
    }
  };
  $self->on($name => $wrapper);
  weaken $wrapper;

  return $wrapper;
}

sub BUILD {
  my ($self, $args) = @_;
  $self->connect->get if $self->auto_connect;
  $self->catch( sub {} );
  $self->{mpd_buffer} = [[]];
}

sub connect {
  my ($self) = @_;
  my $loop = $self->loop;
  my $connected = $loop->new_future;

  return $connected->done if $self->state eq 'ready';

  my $socket = IO::Socket::IP->new($self->host . ':' . $self->port)
    or return $connected->fail("MPD connect failed: $!");

  $log->debugf('Connecting to %s:%s', $self->host, $self->port);

  my $on_error = sub { $self->emit( error => shift ) };

  my $handle = IO::Async::Stream->new(
    handle => $socket,
    on_read_error  => sub { $on_error->('Read error: '  . shift) },
    on_write_error => sub { $on_error->('Write error: ' . shift) },
    on_read_eof    => sub { shift->close },
    on_closed => sub {
      $self->{mpd_handle} = undef;
      $self->emit( 'close' );
    },
    on_read => $self->_parse_block,
  );

  unless ($self->{mpd_handle}) {
    $self->{mpd_handle} = $handle;
    $loop->add( $handle );
  }

  $self->until( state =>
    sub { $_[1] eq 'ready' },
    sub { $connected->done; }
  );

  return $connected;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Net::Async::MPD - A non-blocking interface to MPD

=head1 SYNOPSIS

  use Net::Async::MPD;

  my $mpd = Net::Async::MPD->new(
    host => 'localhost',
    auto_connect => 1,
  );

  my @subsystems = qw( player mixer database );

  # Register a listener
  foreach my $subsystem (@subsystems) {
    $mpd->on( $subsystem => sub {
      my ($self) = @_;
      print "$subsystem has changed\n";

      # Stop listening if mixer changes
      $mpd->noidle if $subsystem eq 'mixer';
    });
  }

  # Send a command
  my $stats = $mpd->send( 'stats' );

  # Or in blocking mode
  my $status = $mpd->send( 'status' )->get;

  # Which is the same as
  $status = $mpd->get( 'status' );

  print 'Server is in ', $status->{state}, " state\n";
  print 'Server has ', $stats->get->{albums}, " albums in the database\n";

  # Put the client in looping idle mode
  my $idle = $mpd->idle( @subsystems );

  # Set the emitter in motion, until the next call to noidle
  $idle->get;

=head1 DESCRIPTION

L<Net::Async::MPD> provides a non-blocking interface to an MPD server.

=head2 Command Lists

MPD supports sending command lists to make it easier to perform a series of
steps as a single one. No command is executed until all commands in the list
have been sent, and then the server returns the result for all of them together.
See the
L<MPD documentation|https://musicpd.org/doc/protocol/command_lists.html>
for more information.

L<Net::Async::MPD> fully supports sending command lists, and makes it easy to
structure the results received from MPD, or not to if the user so desires. See
the L</send> method for more information.

=head2 Error Handling

Most operations in this module return L<Future> objects, and to keep things
consistent, any errors that are encountered during processing will result in
those futures being failed or canceled as appropriate.

This module I<also> makes use of the events in L<Role::EventEmitter>, which
provides it's own method for error handling: the C<error> event. Normally,
if a class C<does> that role, it is expected that users will register some
listener to the C<error> event to handle failures. However, since errors are
alredy being handled by the Futures (one woudl hope), this distribution
registers a dummy listener to the C<error> event, and turns into one that is
mostly useful for debugging and monitoring.

Of course, the author cannot really stop overly zealous users from
L<unsubscribing|Role::EventEmitter/unsubscribe> the error dummy listener, but
they do so at their own risk.

=head2 Server Responses

MPD normally returns results as a flat list of response lines.
L<Net::Async::MPD> tries to make it easier to provide some structure to these
responses by providing pre-set parser subroutines for each command. Although
the default parser will be fine in most cases, it is possible to override this
with a custom parser, or to disable the parsing entirely to get the raw lines
from the server. For information on how to override the parser, see the
documentation for the L</send> method.

By default, the results of each command are parsed independently, and passed
to the L<Future> returned by the corresponding call to L</send>. This is true
regardless of whether those commands were sent as part of a list or not.

This means that, by default, the L<Future> that represents a given call to
L</send> will receive the results of as many commands as were originall sent.

This might not be desireable when eg. sending multiple commands whose results
should be aggregated. In those cases, it is possible to flatten the list by
passing a false value to the C<list> option to L</send> or L</get>.

This means that when calling

    ($stats, $status) = $mpd->get(
      { list => 1 }, # This is the default
      [ 'stats', 'status' ]
    );

C<$stats> and C<$status> will each have a hash reference with the results
of their respective commands; while when calling

    $combined_list = $mpd->get( { list => 0 }, [
      [ search => artist => '"Tom Waits"'   ],
      [ search => artist => '"David Bowie"' ],
    ]);

C<$combined_list> will hold an array reference with the combined results of
both C<search> commands.

=head1 ATTRIBUTES

=over 4

=item B<host>

The host to connect to. Defaults to B<localhost>.

=item B<port>

The port to connect to. Defaults to B<6600>.

=item B<password>

The password to use to connect to the server. Defaults to undefined, which
means to use no password.

=item B<auto_connect>

If set to true, the constructor will block until the connection to the MPD
server has been established. Defaults to false.

=back

=head1 METHODS

=over 4

=item B<connect>

Starts a connection to an MPD server, and returns a L<Future> that will be done
when the connection is complete (or failed if the connection couldn't be
established). If the client is already connected, this function will return an
immediately completed Future.

=item B<send>

    $future = $mpd->send( 'status' );
    $future = $mpd->send( { parser => 'none' }, 'stats' );

    $future = $mpd->send( search => artist => '"Tom Waits"' );

    # Note the dumb string quoting
    $future = $mpd->send( { list => 0 }, [
      [ search => artist => '"Tom Waits"'   ],
      [ search => artist => '"David Bowie"' ],
    ]);

    $future = $mpd->send( \%options, 'stats', sub { ... } );

Asynchronously sends a command to an MPD server, and returns a L<Future>. For
information on what the value of this Future will be, please see the L</"Server Responses"> section.

This method can be called in a number of different ways:

=over 4

=item * If called with a single string, then that string will be sent as the
command.

=item * If called with a list, the list will be joined with spaces and sent as
the command.

=item * If called with an array reference, then the value of each of item in
that array will be processed as above (with array references instead of plain
lists).

=back

If sending multiple commands in one request, the C<command_list...> commands
can be left out and they will be automatically provided for you.

An optional subroutine reference passed as the last argument will be set as the
the C<on_ready> of the Future, which will fire when there is a response from
the server.

A hash reference with additional options can be passed as the I<first>
argument. Valid keys to use are:

=over 4

=item B<list>

If set to false, results of command lists will be parsed as a single result.
When set to true, each command in a command list is parsed independently. See
L</"Server Responses"> for more details.

Defaults to true. This value is ignored when not sending a command list.

=item B<parser>

Specify the parser to use for the I<entire> response. Parser labels are MPD
commands. If the requested parser is not found, the fallback C<none> will be
used.

Alternatively, if the value itself is a code reference, then that will be
called as

    $parser->( \@response_lines, \@command_names );

Where each element in C<@response_lines> is a reference to the list of lines
received after completing the corresponding element in C<@command_names>.

When setting C<list> to false, C<@response_lines> will have a single value,
regardless of how many commands were sent.

=back

For ease of use, underscores in the final command name will be removed before
sending to the server (unless the command name requires them). So

    $client->send( 'current_song' );

is entirely equivalent to

    $client->send( 'currentsong' );

=item B<get>

Send a command in a blocking way. Internally calls B<send> and immediately
waits for the response.

=item B<idle>

Put the client in idle loop. This sends the C<idle> command and registers an
internal listener that will put the client back in idle mode after each server
response.

If called with a list of subsystem names, then the client will only listen to
those subsystems. Otherwise, it will listen to all of them.

If you are using this module for an event-based application (see below), this
will configure the client to fire the events at the appropriate times.

Returns a L<Future>. Waiting on this future will block until the next call to
B<noidle> (see below).

=item B<noidle>

Cancel the client's idle mode. Sends an undefined value to the future created
by B<idle> and breaks the internal idle loop.

=item B<version>

Returns the version number of the protocol spoken by the server, and I<not> the
version of the daemon.

As this is provided by the server, this is C<undef> until after a connection
has been established with the C<connect> method, or by setting C<auto_connect>
to true in the constructor.

=back

=head1 EVENTS

L<Net::Async::MPD> does the L<Role::EventEmitter> role, and inherits all the
methods defined therein. Please refer to that module's documentation for
information on how to register subscribers to the different events.

=head2 Additional methods

=over 4

=item B<until>

In addition to methods like C<on> and C<once>, provided by
L<Role::EventEmitter>, this module also exposes an C<until> method, which
registers a listener until a certain condition is true, and then deregisters it.

The method is called with two subroutine references. The first is subscribed
as a regular listener, and the second is called only when the first one returns
a true value. At that point, the entire set is unsubscribed.

=back

=head2 Event descriptions

After calling B<idle>, the client will be in idle mode, which means that any
changes to the specified subsystems will trigger a signal. When the client
receives this signal, it will fire an event named like the subsystem that fired
it.

The event will be fired with the client as the first argument, and the response
from the server as the second argument. This can safely be ignored, since the
server response will normally just hold the name of the subsystem that changed,
which you already know.

The existing events are the following, as defined by the MPD documentation.

=over 4

=item B<database>

The song database has been changed after B<update>.

=item B<udpate>

A database update has started or finished. If the database was modified during
the update, the B<database> event is also emitted.

=item B<stored_playlist>

A stored playlist has been modified, renamed, created or deleted.

=item B<playlist>

The current playlist has been modified.

=item B<player>

The player has been started stopped or seeked.

=item B<mixer>

The volume has been changed.

=item B<output>

An audio output has been added, removed or modified (e.g. renamed, enabled or
disabled)

=item B<options>

Options like repeat, random, crossfade, replay gain.

=item B<partition>

A partition was added, removed or changed.

=item B<sticker>

The sticker database has been modified.

=item B<subscription>

A client has subscribed or unsubscribed from a channel.

=item B<message>

A message was received on a channel this client is subscribed to.

=back

=head2 Other events

=over 4

=item B<close>

The connection to the server has been closed. This event is not part of the
MPD protocol, and is fired by L<Net::Async::MPD> directly.

=item B<error>

The C<error> event is inherited from L<Role::EventEmitter>. However, unlike
stated in that module's documentation, and as explained in L</"Error Handling">,
users are I<not> required to register to this event for safe execution.

=back

=head1 SEE ALSO

=over 4

=item * L<AnyEvent::Net::MPD>

A previous attempt at writing this distribution, based on L<AnyEvent>. Although
the design is largely the same, it is not as fully featured or as well tested
as this one.

=item * L<Net::MPD>

A lightweight blocking MPD library. Has fewer dependencies than this one, but
it does not curently support command lists. I took the idea of allowing for
underscores in command names from this module.

=item * L<AnyEvent::Net::MPD>

The original version of this module, which used L<AnyEvent>. The interface on
both of these modules is virtually identical.

=item * L<Audio::MPD>

The first MPD library on CPAN. This one also blocks and is based on L<Moose>.
However, it seems to be unmaintained at the moment.

=item * L<Dancer::Plugin::MPD>

A L<Dancer> plugin to connect to MPD. Haven't really tried it, since I
haven't used Dancer...

=item * L<POE::Component::Client::MPD>

A L<POE> component to connect to MPD. This uses Audio::MPD in the background.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
