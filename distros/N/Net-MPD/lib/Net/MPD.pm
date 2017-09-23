package Net::MPD;

use strict;
use warnings;
use version 0.77;

use Carp;
use IO::Socket::INET;
use Net::MPD::Response;
use Scalar::Util qw'looks_like_number';

use 5.010;

our $VERSION = '0.07';

=encoding utf-8

=head1 NAME

Net::MPD - Communicate with an MPD server

=head1 SYNOPSIS

  use Net::MPD;

  my $mpd = Net::MPD->connect();

  $mpd->stop();
  $mpd->clear();
  $mpd->search_add(Artist => 'David Bowie');
  $mpd->shuffle();
  $mpd->play();
  $mpd->next();

  while (1) {
    my @changes = $mpd->idle();
    print 'Changed: ' . join(', ', @changes) . "\n";
  }

=head1 DESCRIPTION

Net::MPD is designed as a lightweight replacment for L<Audio::MPD> which
depends on L<Moose> and is no longer maintained.

=cut

sub _debug {
  say STDERR @_ if $ENV{NET_MPD_DEBUG};
}

sub _connect {
  my ($self) = @_;

  my $socket;
  if ($self->{hostname} =~ /\//) {
    $socket = IO::Socket::UNIX->new($self->{hostname})
      or croak "Unable to connect to $self->{hostname}";
  } else {
    $socket = IO::Socket::INET->new(
      PeerHost => $self->{hostname},
      PeerPort => $self->{port},
      Proto    => 'tcp',
    ) or croak "Unable to connect to $self->{hostname}:$self->{port}";
  }

  binmode $socket, ':utf8';

  my $versionline = $socket->getline;
  my ($version) = ($versionline =~ /^OK MPD (\d+\.\d+\.\d+)$/);

  croak "Connection not to MPD" unless $version;

  $self->{socket} = $socket;
  $self->{version} = qv($version);

  if ($self->{password}) {
    my $result = $self->_send('password', $self->{password});
    croak $result->message if $result->is_error;
  }

  $self->update_status();
}

sub _send {
  my ($self, $command, @args) = @_;

  my $string = "$command";
  foreach my $arg (@args) {
    $arg =~ s/"/\\"/g;
    $string .= qq{ "$arg"};
  }
  $string .= "\n";

  # auto reconnect
  unless ($self->{socket}->connected) {
    $self->_connect();
    _debug '# Reconnecting';
  }

  $self->{socket}->print($string);
  _debug "> $string";

  my @lines = ();

  while (1) {
    my $line = $self->{socket}->getline;
    croak "Error reading line from socket" if not defined $line;
    chomp $line;
    _debug "< $line";

    if ($line =~ /^OK$|^ACK /) {
      return Net::MPD::Response->new($line, @lines);
    } else {
      push @lines, $line;
    }
  }
}

sub _require {
  my ($self, $version) = @_;
  $version = qv($version);
  croak "Requires MPD version $version" if $version > $self->version;
}

sub _inject {
  my ($class, $name, $sub) = @_;
  no strict 'refs';
  *{"${class}::$name"} = $sub;
}

sub _attribute {
  my ($class, $name, %options) = @_;

  (my $normal_name = $name) =~ s/_//g;

  $options{key}       //= $normal_name;
  $options{command}   //= $normal_name;
  $options{version}   //= 0;

  my $getter = sub {
    my ($self) = @_;
    $self->_require($options{version});
    return $self->{status}{$options{key}};
  };

  my $setter = sub {
    my ($self, $value) = @_;

    $self->_require($options{version});

    my $result = $self->_send($options{command}, $value);
    if ($result->is_error) {
      carp $result->message;
    } else {
      $self->{status}{$options{key}} = $value;
    }

    return $getter->(@_);
  };

  $class->_inject($name => sub {
    if ($options{readonly} or @_ == 1) {
      return $getter->(@_);
    } else {
      return $setter->(@_);
    }
  });
}

my $default_parser = sub {
  my $result = shift;

  my @items = ();
  my $item = {};
  foreach my $line ($result->lines) {
    my ($key, $value) = split /: /, $line, 2;
    if (exists $item->{$key}) {
      push @items, 2 > keys %$item ? values %$item : $item;
      $item = {};
    }
    $item->{$key} = $value;
  }

  push @items, 2 > keys %$item ? values %$item : $item;

  return wantarray ? @items : $items[0];
};

sub _command {
  my ($class, $name, %options) = @_;

  (my $normal_name = $name) =~ s/_//g;

  $options{command} //= $normal_name;
  $options{args}    //= [];
  $options{parser}  //= $default_parser;

  $class->_inject($name => sub {
    my $self = shift;
    my $result = $self->_send($options{command}, @_);
    if ($result->is_error) {
      carp $result->message;
      return undef;
    } else {
      return $options{parser}->($result);
    }
  });
}

=head1 METHODS

=head2 connect [$address]

Connect to the MPD running at the given address.  Address takes the form of
password@host:port.  Both the password and port are optional.  If no password is
given, none will be used.  If no port is given, the default (6600) will be used.
If no host is given, C<localhost> will be used.

If the hostname contains a "/", it will be interpretted as the path to a UNIX
socket try to connect that way instead of using TCP.

Return a Net::MPD object on success and croaks on failure.

=cut

sub connect {
  my ($class, $address) = @_;

  $address ||= 'localhost';

  my ($pass, $host, $port) = ($address =~ /(?:([^@]+)@)?([^:]+)(?::(\d+))?/);

  $port ||= 6600;

  my $self = bless {
    hostname => $host,
    port     => $port,
    password => $pass,
  }, $class;

  $self->_connect;

  return $self;
}

=head2 version

Return the API version of the connected MPD server.

=cut

sub version {
  my $self = shift;
  return $self->{version};
}

=head2 update_status

Issue a C<status> command to MPD and stores the results in the local object.
The results are also returned as a hashref.

=cut

sub update_status {
  my ($self) = @_;
  my $result = $self->_send('status');
  if ($result->is_error) {
    warn $result->message;
  } else {
    $self->{status} = $result->make_hash;
  }
}

=head1 MPD ATTRIBUTES

Most of the "status" attributes have been written as combined getter/setter
methods.  Calling the L</update_status> method will update these values.  Only
the items marked with an asterisk are writable.

=over 4

=item volume*

=item repeat*

=item random*

=item single*

=item consume*

=item playlist

=item playlist_length

=item state

=item song

=item song_id

=item next_song

=item next_song_id

=item time

=item elapsed

=item bitrate

=item crossfade*

=item mix_ramp_db*

=item mix_ramp_delay*

=item audio

=item updating_db

=item error

=item replay_gain_mode*

=back

=cut

__PACKAGE__->_attribute('volume', command => 'setvol');
__PACKAGE__->_attribute('repeat');
__PACKAGE__->_attribute('random');
__PACKAGE__->_attribute('single', version => 0.15);
__PACKAGE__->_attribute('consume', version => 0.15);
__PACKAGE__->_attribute('playlist', readonly => 1);
__PACKAGE__->_attribute('playlist_length', readonly => 1);
__PACKAGE__->_attribute('state', readonly => 1);
__PACKAGE__->_attribute('song', readonly => 1);
__PACKAGE__->_attribute('song_id', readonly => 1);
__PACKAGE__->_attribute('next_song', readonly => 1);
__PACKAGE__->_attribute('next_song_id', readonly => 1);
__PACKAGE__->_attribute('time', readonly => 1);
__PACKAGE__->_attribute('elapsed', readonly => 1, version => 0.16);
__PACKAGE__->_attribute('bitrate', readonly => 1);
__PACKAGE__->_attribute('crossfade', key => 'xfade');
__PACKAGE__->_attribute('mix_ramp_db');
__PACKAGE__->_attribute('mix_ramp_delay');
__PACKAGE__->_attribute('audio', readonly => 1);
__PACKAGE__->_attribute('updating_db', key => 'updating_db', readonly => 1);
__PACKAGE__->_attribute('error', readonly => 1);

sub replay_gain_mode {
  my $self = shift;

  if (@_) {
    my $result = $self->_send('replay_gain_mode', @_);
    carp $result->message if $result->is_error;
  }

  my $result = $self->_send('replay_gain_status');
  if ($result->is_error) {
    carp $result->message;
    return undef;
  } else {
    return $result->make_hash->{replay_gain_mode};
  }
}

=head1 MPD COMMANDS

The commands are mostly the same as the L<MPD
protocol|http://www.musicpd.org/doc/protocol/index.html> but some have been
renamed slightly.

=head2 clear_error

Clear the current error message in status.  This can also be done by issuing any
command that starts playback.

=head2 current_song

Return the song info for the current song.

=head2 idle [@subsystems]

Block until a noteworth change in one or more of MPD's subsystems.  As soon as
there is one, a list of all changed subsystems will be returned.  If any
subsystems are given as arguments, only those subsystems will be monitored.  The
following subsystems are available:

=over 4

=item database

The song database has been changed after an update.

=item udpate

A database update has started or finished.

=item stored_playlist

A stored playlist has been modified.

=item playlist

The current playlist has been modified.

=item player

Playback has been started stopped or seeked.

=item mixer

The volume has been adjusted.

=item output

An audio output has been enabled or disabled.

=item sticker

The sticket database has been modified.

=item subscription

A client has subscribed or unsubscribed from a channel.

=item message

A message was received on a channel this client is watching.

=back

=head2 stats

Return a hashref with some stats about the database.

=head2 next

Play the next song in the playlist.

=head2 pause $state

Set the pause state.  Use 0 for playing and 1 for paused.

=head2 play [$position]

Start playback (optionally at the given position).

=head2 play_id [$id]

Start playback (optionally with the given song).

=head2 previous

Play the previous song in the playlist.

=head2 seek $position $time

Seek to $time seconds in the given song position.

=head2 seek_id $id $time

Seek to $time seconds in the given song.

=head2 seek_cur $time

Seek to $time seconds in the current song.

=head2 stop

Stop playing.

=head2 add $path

Add the file (or directory, recursively) at $path to the current playlist.

=head2 add_id $path [$position]

Add the file at $path (optionally at $position) to the playlist and return the
id.

=head2 clear

Clear the current playlist.

=head2 delete $position

Remove the song(s) in the given position from the current playlist.

=head2 delete_id $id

Remove the song with the given id from the current playlist.

=head2 move $from $to

Move the song from position $from to $to.

=head2 move_id $id $to

Move the song with the given id to position $to.

=head2 playlist_find $tag $search

Search the current playlist for songs with $tag exactly matching $search.

=head2 playlist_id $id

Return song information for the song with the given id.

=head2 playlist_info [$position]

Return song information for every song in the current playlist (or optionally
the one at the given position).

=head2 playlist_search $tag $search

Search the current playlist for songs with $tag partially matching $search.

=head2 playlist_changes $version

Return song information for songs changed since the given version of the current
playlist.

=head2 playlist_changes_pos_id $version

Return position and id information for songs changed since the given version of
the current playlist.

=head2 prio $priority $position

Set the priority of the song at the given position.

=head2 prio_id $priority $id

Set the priority of the song with the given id.

=head2 shuffle

Shuffle the current playlist.

=head2 swap $pos1 $pos2

Swap the positions of the songs at the given positions.

=head2 swapid $id1 $id2

Swap the positions of the songs with the given ids.

=head2 list_playlist $name

Return a list of all the songs in the named playlist.

=head2 list_playlist_info $name

Return all the song information for the named playlist.

=head2 list_playlists

Return a list of the stored playlists.

=head2 load $name

Add the named playlist to the current playlist.

=head2 playlist_add $name $path

Add the given path to the named playlist.

=head2 playlist_clear $name

Clear the named playlist.

=head2 playlist_delete $name $position

Remove the song at the given position from the named playlist.

=head2 playlist_move $name $id $pos

Move the song with the given id to the given position in the named playlist.

=head2 rename $name $new_name

Rename the named playlist to $new_name.

=head2 rm $name

Delete the named playlist.

=head2 save $name

Save the current playlist with the given name.

=head2 count $tag $search ...

Return a count and playtime for all items with $tag exactly matching $search.
Multiple pairs of $tag/$search parameters can be given.

=head2 find $tag $search ...

Return song information for all items with $tag exactly matching $search.  The
special tag 'any' can be used to search all tag.  The special tag 'file' can be
used to search by path.

=head2 find_add $tag $search

Search as with C<find> and add any matches to the current playlist.

=head2 list $tag [$artist]

Return all the values for the given tag.  If the tag is 'album', an artist can
optionally be given to further limit the results.

=head2 list_all [$path]

Return a list of all the songs and directories (optionally under $path).

=head2 list_all_info [$path]

Return a list of all the songs as with C<listall> but include metadata.

=head2 search $tag $search ...

As C<find> but with partial, case-insensitive searching.

=head2 search_add $tag $search ...

As C<search> but adds the results to the current playlist.

=head2 search_add_pl $name $tag $search ...

As C<search> but adds the results the named playlist.

=head2 update [$path]

Update the database (optionally under $path) and return a job id.

=head2 rescan [$path]

As <update> but forces rescan of unmodified files.

=head2 sticker_value $type $path $name [$value]

Return the sticker value for the given item after optionally setting it to
$value.  Use an undefined value to delete the sticker.

=cut

sub sticker_value {
  my ($self, $type, $path, $name, $value) = @_;

  if (@_ > 4) {
    if (defined $value) {
      my $result = $self->_send('sticker', 'set', $type, $path, $name, $value);
      carp $result->message and return undef if $result->is_error;
      return $value;
    } else {
      my $result = $self->_send('sticker', 'delete', $type, $path, $name);
      carp $result->message if $result->is_error;
      return undef;
    }
  } else {
    my $result = $self->_send('sticker', 'get', $type, $path, $name);
    carp $result->message and return undef if $result->is_error;

    my ($line) = $result->lines;
    my ($val) = ($line =~ /^sticker: \Q$name\E=(.*)$/);
    return $val;
  }
}

=head2 sticker_list $type $path

Return a hashref of the stickers for the given item.

=cut

sub sticker_list {
  my ($self, $type, $path) = @_;

  my $result = $self->_send('sticker', 'list', $type, $path);
  carp $result->message and return undef if $result->is_error;

  my $stickers = {};
  foreach my $line ($result->lines) {
    my ($key, $value) = ($line =~ /^sticker: (.*)=(.*)$/);
    $stickers->{$key} = $value;
  }

  return $stickers;
}

=head2 sticker_find $type $name [$path]

Return a list of all the items (optionally under $path) with a sticker of the given name.

=cut

sub sticker_find {
  my ($self, $type, $name, $path) = @_;
  $path //= '';

  my $result = $self->_send('sticker', 'find', $type, $path, $name);
  carp $result->message and return undef if $result->is_error;

  my @items = ();
  my $file = '';

  foreach my $line ($result->lines) {
    my ($key, $value) = split /: /, $line, 2;
    if ($key eq 'file') {
      $file = $value;
    } elsif ($key eq 'sticker') {
      my ($val) = ($value =~ /^\Q$name\E=(.*)$/);
      push @items, { file => $file, sticker => $val };
    }
  }

  return @items;
}

=head2 close

Close the connection.  This is pretty worthless as the library will just
reconnect for the next command.

=head2 kill

Kill the MPD server.

=head2 ping

Do nothing.  This can be used to keep an idle connection open.  If you want to
wait for noteworthy events, the C<idle> command is better suited.

=head2 disable_output $id

Disable the given output.

=head2 enable_output $id

Enable the given output.

=head2 outputs

Return a list of the available outputs.

=head2 commands

Return a list of the available commands.

=head2 not_commands

Return a list of the unavailable commands.

=head2 tag_types

Return a list of all the avalable song metadata.

=head2 url_handlers

Return a list of available url handlers.

=head2 decoders

Return a list of available decoder plugins, along with the MIME types and file
extensions associated with them.

=head2 subscribe $channel

Subscribe to the named channel.

=head2 unsubscribe $channel

Unsubscribe from the named channel.

=head2 channels

Return a list of the channels with active clients.

=head2 read_messages

Return a list of any available messages for this clients subscribed channels.

=head2 send_message $channel $message

Send a message to the given channel.

=cut

my $song_parser = sub {
  my $result = shift;

  my @songs = ();
  my $song = {};

  foreach my $line ($result->lines) {
    my ($key, $value) = split /: /, $line, 2;

    if ($key =~ /^(?:file|directory|playlist)$/) {
      push @songs, $song if exists $song->{type};
      $song = { type => $key, uri => $value };
    } else {
      $song->{$key} = $value;
    }
  }

  return @songs, $song;
};

my $decoder_parser = sub {
  my $result = shift;

  my @plugins = ();
  my $plugin = {};

  foreach my $line ($result->lines) {
    my ($key, $value) = split /: /, $line, 2;

    if ($key eq 'plugin') {
      push @plugins, $plugin if exists $plugin->{name};
      $plugin = { name => $value };
    } else {
      push @{$plugin->{$key}}, $value;
    }
  }

  return @plugins, $plugin;
};

__PACKAGE__->_command('clear_error');
__PACKAGE__->_command('current_song', parser => $song_parser);
__PACKAGE__->_command('idle');
__PACKAGE__->_command('stats');
__PACKAGE__->_command('next');
__PACKAGE__->_command('pause');
__PACKAGE__->_command('play');
__PACKAGE__->_command('play_id');
__PACKAGE__->_command('previous');
__PACKAGE__->_command('seek');
__PACKAGE__->_command('seek_id');
__PACKAGE__->_command('seek_cur');
__PACKAGE__->_command('stop');
__PACKAGE__->_command('add');
__PACKAGE__->_command('add_id');
__PACKAGE__->_command('clear');
__PACKAGE__->_command('delete');
__PACKAGE__->_command('delete_id');
__PACKAGE__->_command('move');
__PACKAGE__->_command('move_id');
__PACKAGE__->_command('playlist_find', parser => $song_parser);
__PACKAGE__->_command('playlist_id', parser => $song_parser);
__PACKAGE__->_command('playlist_info', parser => $song_parser);
__PACKAGE__->_command('playlist_search', parser => $song_parser);
__PACKAGE__->_command('playlist_changes', command => 'plchanges', parser => $song_parser);
__PACKAGE__->_command('playlist_changes_pos_id', command => 'plchangesposid');
__PACKAGE__->_command('prio');
__PACKAGE__->_command('prio_id');
__PACKAGE__->_command('shuffle');
__PACKAGE__->_command('swap');
__PACKAGE__->_command('swapid');
__PACKAGE__->_command('list_playlist', parser => $song_parser);
__PACKAGE__->_command('list_playlist_info', parser => $song_parser);
__PACKAGE__->_command('list_playlists');
__PACKAGE__->_command('load');
__PACKAGE__->_command('playlist_add');
__PACKAGE__->_command('playlist_clear');
__PACKAGE__->_command('playlist_delete');
__PACKAGE__->_command('playlist_move');
__PACKAGE__->_command('rename');
__PACKAGE__->_command('rm');
__PACKAGE__->_command('save');
__PACKAGE__->_command('count');
__PACKAGE__->_command('find', parser => $song_parser);
__PACKAGE__->_command('find_add');
__PACKAGE__->_command('list');
__PACKAGE__->_command('list_all', parser => $song_parser);
__PACKAGE__->_command('list_all_info', parser => $song_parser);
__PACKAGE__->_command('ls_info', parser => $song_parser);
__PACKAGE__->_command('search', parser => $song_parser);
__PACKAGE__->_command('search_add');
__PACKAGE__->_command('search_add_pl');
__PACKAGE__->_command('update');
__PACKAGE__->_command('rescan');
__PACKAGE__->_command('sticker');
__PACKAGE__->_command('close');
__PACKAGE__->_command('kill');
__PACKAGE__->_command('ping');
__PACKAGE__->_command('disable_output');
__PACKAGE__->_command('enable_output');
__PACKAGE__->_command('outputs');
__PACKAGE__->_command('config');
__PACKAGE__->_command('commands');
__PACKAGE__->_command('not_commands');
__PACKAGE__->_command('tag_types');
__PACKAGE__->_command('url_handlers');
__PACKAGE__->_command('decoders', parser => $decoder_parser);
__PACKAGE__->_command('subscribe');
__PACKAGE__->_command('unsubscribe');
__PACKAGE__->_command('channels');
__PACKAGE__->_command('read_messages');
__PACKAGE__->_command('send_message');

1;

=head1 TODO

=head2 Command Lists

MPD supports sending batches of commands but that is not yet available with this API.

=head2 Asynchronous IO

Event-based handling of the idle command would make this module more robust.

=head1 BUGS

=head2 Idle connections

MPD will close the connection if left idle for too long.  This module will
reconnect if it senses that this has occurred, but the first call after a
disconnect will fail and have to be retried.  Calling the C<ping> command
periodically will keep the connection open if you do not have any real commands
to issue.  Calling the C<idle> command will block until something interesting
happens.

=head2 Reporting

Report any issues on L<GitHub|https://github.com/bentglasstube/Net-MPD/issues>

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Alan Berndt

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<Audio::MPD>, L<MPD Protocol|http://www.musicpd.org/doc/protocol/index.html>

=cut
