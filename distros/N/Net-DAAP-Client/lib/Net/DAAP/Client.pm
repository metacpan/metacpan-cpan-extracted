use strict;
package Net::DAAP::Client;
use Net::DAAP::Client::v2;
use Net::DAAP::Client::v3;
use Net::DAAP::DMAP 1.22;
use Net::DAAP::DMAP qw(:all);
use LWP;
use HTTP::Request::Common;
use Carp;
use sigtrap qw(die untrapped normal-signals);
use vars qw( $VERSION );
$VERSION = '0.42';

=head1 NAME

  Net::DAAP::Client - client for Apple iTunes DAAP service

=head1 SYNOPSIS

  my $daap;  # see WARNING below
  $daap = Net::DAAP::Client->new(SERVER_HOST => $hostname,
                                 SERVER_PORT => $portnum,
                                 PASSWORD    => $password);
  $dsn = $daap->connect;

  $dbs_hash = $daap->databases;
  $current_db = $daap->db;
  $daap_db($new_db_id);

  $songs_hash = $daap->songs;
  $playlists_hash = $daap->playlists;
  $array_of_songs_in_playlist = $daap->playlist($playlist_id);

  $url = $daap->url($song_or_playlist_id);

  $binary_audio_data = $obj->get($song_id);
  $binary_audio_data = $obj->get(@song_ids);
  $song_id = $obj->save($dir, $song_id);
  @song_ids = $obj->get($dir, @song_ids);

  $daap->disconnect;

  if ($daap->error) {
      warn $daap->error;  # returns error string
  }

=head1 DESCRIPTION

Net::DAAP::Client provides objects representing connections to DAAP
servers.  You can fetch databases, playlists, and songs.  This module
was written based on a reverse engineering of Apple's iTunes 4 sharing
implementation.  As a result, features that iTunes 4 doesn't support
(browsing, searching) aren't supported here.

Each connection object has a destructor, so that you can forget to
C<disconnect> without leaving the server expecting you to call back.

=head2 WARNING

If you store your object in a global variable, Perl can't seem to
disconnect gracefully from the server.  Until I figure out why, always
store your object in a lexical (C<my>) variable.

=head1 METHODS

=cut

my $DAAP_Port = 3689;
my @User_Columns = qw( SERVER_HOST SERVER_PORT PASSWORD DEBUG SONG_ATTRIBUTES );
my %Defaults = (
    # user-specified
    SERVER_HOST   => "",
    SERVER_PORT   => $DAAP_Port,
    PASSWORD      => "",
    DEBUG         => 0,
    SONG_ATTRIBUTES => [ qw(dmap.itemid dmap.itemname dmap.persistentid
                            daap.songalbum daap.songartist daap.songformat
                            daap.songsize) ],

    # private
    ERROR         => "",
    CONNECTED     => 0,
    DATABASE_LIST => undef,
    DATABASE      => undef,
    SONGS         => undef,
    PLAYLISTS     => undef,
    VALIDATOR     => undef,
   );


sub new {
    my $class = shift;
    my $self = bless { %Defaults } => $class;

    if (@_ > 1) {
        $self->_init(@_);
    } elsif (@_) {
        $self->{SERVER_HOST} = shift;
    } else {
        warn "Why are you calling new with no arguments?";
        die "Need to implement get/set for hostname and port";
    }

    return $self;
}

=head2 * new()

    $obj = Net::DAAP::Client->new(OPTNAME => $value, ...);

The allowed options are:

=over 4

=item SERVER_NAME

The hostname or IP address of the server.

=item SERVER_PORT

The port number of the server.

=item PASSWORD

The password to use when authenticating.

=item DEBUG

Print some debugging output


=item SONG_ATTRIBUTES

The attributes to retrieve for a song as an array reference.  The
default list is:

 [qw( dmap.itemid dmap.itemname dmap.persistentid daap.songalbum
      daap.songartist daap.songformat daap.songsize )]

=back

=cut

sub _init {
    my $self = shift;
    my %opts = @_;

    foreach my $key (@User_Columns) {
        $self->{$key} = $opts{$key} || $Defaults{$key};
    }
}

sub _debug {
    my $self = shift;
    warn "$_[0]\n" if $self->{DEBUG};
}

=head2 * connect()

    $name = $obj->connect
        or die $obj->error;

Attempts to fetch the server information, log in, and learn the latest
revision number.  It returns the name of the server we've connected to
(as that server reported it).  It returns C<undef> if any of the steps
fail.  If it fails fetching the revision number, it logs out before
returning C<undef>.

=cut


sub connect {
    my $self = shift;
    my $ua = ($self->{UA} ||= Net::DAAP::Client::UA->new(keep_alive => 1) );
    my ($dmap, $id);

    $self->_devine_validator;


    $self->error("");
    $self->{DATABASE_LIST} = undef;

    # get content codes
    $dmap = $self->_do_get("content-codes") or return;
    update_content_codes(dmap_unpack($dmap));

    # check server name/version
    $dmap = $self->_do_get("server-info") or return;

    my %hash = dmap_flat_list( dmap_unpack ($dmap) );
    my $data_source_name = $hash{'/dmap.serverinforesponse/dmap.itemname'};
    $self->{DSN} = $data_source_name;
    $self->_debug("Connected to iTunes share '$data_source_name'");

    # log in
    $dmap = $self->_do_get("login") or return;
    $id = dmap_seek(dmap_unpack($dmap), "dmap.loginresponse/dmap.sessionid");
    $self->{ID} = $id;
    $self->_debug("my id is $id");

    $self->{CONNECTED} = 1;

    # fetch databases
    my $dbs = $self->databases()
      or return;

    # autoselect if only one database present
    if (keys(%$dbs) == 1) {
        $self->db((keys %$dbs)[0])
          or return;
    }

    return $self->{DSN};
}

=head2 * databases()

    $dbs = $self->databases();

Returns a hash reference.  Sample:

=cut

sub databases {
    my $self = shift;

    $self->error("");

    unless ($self->{CONNECTED}) {
        $self->error("Not connected--can't fetch databases list");
        return;
    }

    my $res = $self->_do_get("databases");
    my $listing = dmap_seek(dmap_unpack($res),
                            "daap.serverdatabases/dmap.listing");

    unless ($listing) {
        $self->error("databases query didn't return a list of databases");
        return;
    }

    my $struct = $self->_unpack_listing_to_hash($listing);

    $self->{DATABASE_LIST} = $struct;
    return $struct;
}

=head2 * db()

    $db_id = $obj->db;     # learn current database ID
    $obj->db($db_id);      # set current database

A database ID is a key from the hash returned by
C<< $obj->databases >>.

Setting the database loads the playlists and song list for that
database.  This can take some time if there are a lot of songs in
either list.

This method returns true if an error occurred, false otherwise.
If an error occurs, you can't rely on the song list or play list
having been loaded.

=cut

sub db {
    my ($self, $db_id) = @_;
    my $db;

    unless ($self->{DATABASE_LIST}) {
        $self->error("You haven't fetched the list of databases yet");
        return;
    }

    unless (defined $db_id) {
        return $self->{DATABASE};
    }

    $db = $self->{DATABASE_LIST}{$db_id};
    if (defined $db) {
        $self->{DATABASE} = $db_id;
        $self->_debug("Loading songs from database $db->{'dmap.itemname'}");
        $self->{SONGS} = $self->_get_songs($db_id)
          or return;
        $self->_debug("Loading playlists from database $db->{'dmap.itemname'}");
        $self->{PLAYLISTS} = $self->_get_playlists($db_id)
          or return;
    } else {
        $self->error("Database ID $db_id not found");
        return;
    }

    return $self;
}

=head2 * songs()

    $songs = $obj->songs();

Returns a hash reference.  Keys are song IDs, values are hashes with
information on the song.  Information fetched is specified by
SONG_ATTRIBUTES, the default set is:

=over

=item dmap.itemid

Unique ID for the song.

=item dmap.itemname

Title of the track.

=item dmap.persistentid

XXX [add useful explanation here]

=item daap.songalbum

Album name that the track came from.

=item daap.songartist

Artist who recorded the track.

=item daap.songformat

A string, "mp3", "aiff", etc.

=item daap.songsize

Size in bytes of the file.

=back

A sample record:

    '127' => {
        'daap.songsize' => 2597221,
        'daap.songalbum' => 'Live (Disc 2)',
        'dmap.persistentid' => '4081440092921832180',
        'dmap.itemname' => 'Down To The River To Pray',
        'daap.songartist' => 'Alison Krauss + Union Station',
        'dmap.itemid' => 127,
        'daap.songformat' => 'mp3'
        },

To find out what other attributes you can request consult the DAAP
spec at http://tapjam.net/daap/draft.html

=cut

sub songs {
    my $self = shift;

    return $self->{SONGS};
}

=head2 * playlists()

    $songlist = $obj->playlists();

Returns a hash reference.  Keys are playlist IDs, values are hashes
with information on the playlist.

XXX: explain keys

A sample record:

    '2583' => {
        'dmap.itemcount' => 335,
        'dmap.persistentid' => '4609413108325671202',
        'dmap.itemname' => 'Recently Played',
        'com.apple.itunes.smart-playlist' => 0,
        'dmap.itemid' => 2583
    }

=cut

sub playlists {
    my $self = shift;

    return $self->{PLAYLISTS};
}

sub _get_songs {
    my ($self, $db_id) = @_;

    my $path = "databases/$db_id/items?type=music&meta=" .
      join ",", @{ $self->{SONG_ATTRIBUTES} };
    my $res = $self->_do_get($path) or return;

    my $listing = dmap_seek(dmap_unpack($res),
                            "daap.databasesongs/dmap.listing");
    if (!$listing) {
        $self->error("no song database in response from server");
        return;
    }

    my $struct = $self->_unpack_listing_to_hash($listing);
    delete @{%$struct}{ grep { $struct->{$_}{'daap.songsize'} == 0 } keys %$struct };  # remove deleted songs

    return $struct;
}

sub _get_playlists {
    my ($self, $db_id) = @_;

    my $res = $self->_do_get("databases/$db_id/containers?meta=dmap.itemid,dmap.itemname,dmap.persistentid,com.apple.itunes.smart-playlist")
        or return;

    my $listing = dmap_seek(dmap_unpack($res),
                            "daap.databaseplaylists/dmap.listing");
    if (!$listing) {
        $self->error("no playlist in response from server");
        return;
    }

    return $self->_unpack_listing_to_hash($listing);
}

=head2 * playlist

    $playlist = $obj->playlist($playlist_id);

A playlist ID is a key from the hash returned from the C<playlists>
method.  Returns an array of song records.

=cut

sub playlist {
    my ($self, $playlist_id) = @_;

    my $db_id = $self->{DATABASE};
    if (!$db_id) {
        $self->error("No database selected so can't fetch playlist");
        return;
    }

    if (!exists $self->{PLAYLISTS}->{$playlist_id}) {
        $self->error("No such playlist $playlist_id");
        return;
    }

    my $res = $self->_do_get("databases/$db_id/containers/$playlist_id/items?type=music&meta=dmap.itemkind,dmap.itemid,dmap.containeritemid")
        or return;

    my $listing = dmap_seek(dmap_unpack($res),
                            "daap.playlistsongs/dmap.listing");
    if (!$listing) {
        $self->error("Couldn't fetch playlist $playlist_id");
    }

    my $struct = [];

    foreach my $item (@$listing) {
        my $record = {};
        my $field_array_ref = $item->[1];
        foreach my $field_pair_ref (@$field_array_ref) {
            my ($field, $value) = @$field_pair_ref;
            $record->{$field} = $value;
        }
        push @$struct, $self->{SONGS}->{ $record->{"dmap.itemid"} };
    }

    return $struct;
}

sub _unpack_listing_to_hash {
    my ($self, $listing) = @_;

    my $struct = {};

    foreach my $item (@$listing) {
        my $record = {};
        my $field_array_ref = $item->[1];
        foreach my $field_pair_ref (@$field_array_ref) {
            my ($field, $value) = @$field_pair_ref;
            $record->{$field} = $value;
        }
        $struct->{$record->{'dmap.itemid'}} = $record;
    }

    return $struct;
}

=head2 * url

    $url = $obj->url($song_id);
    $url = $obj->url($playlist_id);

Returns the persistent URL for the track or playlist.

=cut

###
### XXX: I go from Math::BigInt to
### string to Math::BigInt again.  Some of these helper methods are surely
### not necessary?
###

sub url {
    my ($self, @arg) = @_;

    $self->error("");

    if (!$self->{CONNECTED}) {
        $self->error("Can't fetch URL when not connected");
        return;
    }

    my $song_list = $self->{SONGS};
    my $playlists = $self->{PLAYLISTS};
    my $db = $self->{DATABASE_LIST}{$self->{DATABASE}}{"dmap.persistentid"};
    my @urls = ();
    my @skipped = ();

    foreach my $id (@arg) {
        if (exists $song_list->{$id}) {
            my $song = $song_list->{$id};
            push @urls, $self->
            _build_resolve_url(database => $db,
                               song     => $song->{"dmap.persistentid"});
        } elsif (exists $playlists->{$id}) {
            my $playlist = $playlists->{$id};
            push @urls, $self->
            _build_resolve_url(database => $db,
                              playlist => $playlist->{"dmap.persistentid"});
        } else {
            push @skipped, $id;
        }
    }

    if (@skipped) {
        $self->error("skipped: @skipped");
    }

    if (wantarray) {
        return @urls;
    } else {
        return $urls[0];
    }
}

sub _build_resolve_url {
    my ($self, %specs) = @_;

    return "daap://$self->{SERVER_HOST}:$self->{SERVER_PORT}/resolve?" .
      join('&', map {my $id = $self->_persistentid_as_text($specs{$_});
                     "$_-spec='dmap.persistentid:$id'"} keys %specs);
}

sub _persistentid_as_text {
    my ($self, $id) = @_;

    $id = new Math::BigInt($id);

    return sprintf("0x%08x%08x", $id->brsft(32), $id->band(0xffffffff));
}


=head2 * get

    @tracks = $obj->get(@song_ids);

Returns the binary data of the song.  A song ID is a key from
the hash returned by C<songs>, or the C<dmap.itemid> from one of
the elements in the array returned by C<playlist>.

=cut

sub get {
    my ($self, @arg) = @_;
    $self->_download_songs(undef, @arg);
}

sub _download_songs {
    my ($self, $dir, @arg) = @_;
    my $song_list = $self->{SONGS};
    my @songs;
    my @skipped;

    foreach my $song_id (@arg) {
        my $song = $song_list->{$song_id};

        if (!defined $song) {  # ok to blur defined() and exists() here
            push @skipped, $song_id;
            next;
        }
        my $response = $self->_get_song($self->{DATABASE}, $song, $dir);
        if (!$response) {
            push @skipped, $song_id;
        } else {
            push @songs, $dir ? $song_id : $response;
        }
    }

    if (@skipped) {
        $self->error("skipped: @skipped");
    }
    if (wantarray) {
        return @songs;
    } else {
        return $songs[0];
    }
}

sub _get_song {
    my ($self, $db_id, $song, $dir) = @_;
    my ($song_id, $format) =
        ($song->{"dmap.itemid"}, $song->{"daap.songformat"});
    my $filename = "$song_id.$format";

    ++$self->{REQUEST_ID};

    if ($dir) {
        return $self->_do_get("databases/$db_id/items/$filename",
                              "$dir/$filename");
    } else {
        return $self->_do_get("databases/$db_id/items/$filename");
    }
}

=head2 * save

    $tracks_saved = $obj->save($dir, @song_ids);

Saves the binary data of the song to the directory.  Returns the
number of songs saved.

=cut

sub save {
    my ($self, @arg) = @_;
    $self->_download_songs(@arg);
}

=head2 * disconnect()

    $obj->disconnect;

Logs out of the database.  Returns C<undef> if an error occurred, a
true value otherwise.  If an error does occur, there's probably not
much you can do about it.

=cut

sub disconnect {
    my $self = shift;

    $self->error("");
    if ($self->{CONNECTED}) {
        (undef) = $self->_do_get("logout");
    }
    undef $self->{CONNECTED};
    return $self->error;
}

sub DESTROY {
    my $self = shift;
    $self->_debug("Destroying $self->{ID} to $self->{SERVER_HOST}");
    $self->disconnect;
}

=head2 * error()

    $string = $obj->error;

Returns the most recent error code.  Empty string if no error occurred.

=cut

sub error {
    my $self = shift;
    if ($self->{DEBUG} and defined($_[0]) and length($_[0])) {
        warn "Setting error to $_[0]\n";
    }
    if (@_) { $self->{ERROR} = shift } else { $self->{ERROR} }
}

sub _devine_validator {
    my $self = shift;
    $self->{VALIDATOR} = undef;
    $self->{M4p_evil}  = 0;

    my $response = $self->{UA}->get( $self->_server_url.'/server-info' );
    my $server = $response->header('DAAP-Server');

    if ($server =~ m{^iTunes/4.2 }) {
        $self->{VALIDATOR} = __PACKAGE__."::v2";
        return;
    }

    if ($server =~ m{^iTunes/}) {
        $self->{M4p_evil} = 1;
        $self->{VALIDATOR} = __PACKAGE__."::v3"
    }
}


sub _validation_cookie {
    my $self = shift;
    return unless $self->{VALIDATOR};
    return ( "Client-DAAP-Validation" => $self->{VALIDATOR}->validate( @_ ) );
}

sub _server_url {
    my $self = shift;
    sprintf("http://%s:%d", $self->{SERVER_HOST}, $self->{SERVER_PORT});
}

# quite the fugly hack
my @credentials;
{
    package Net::DAAP::Client::UA;
    use base qw( LWP::UserAgent );
    sub get_basic_credentials { return @credentials }

}

sub _do_get {
    my ($self, $req, $file) = @_;
    if (!defined wantarray) { carp "_do_get's result is being ignored" }

    my $id = $self->{ID};
    my $revision = $self->{REVISION};
    my $ua = $self->{UA};

    my $url = $self->_server_url . "/$req";
    my $res;

    # append session-id and revision-number query args automatically
    if ($self->{ID}) {
        $url .= $req =~ m{ \? }x ? "&" : "?";
        $url .= "session-id=$id";
    }

    if ($revision && $req ne 'logout') {
        $url .= "&revision-number=$revision";
    }

    # fetch into memory or save to disk as needed

    $self->_debug($url);

    # form the request ourself so we have magic headers.
    my $path = $url;
    $path =~ s{http://.*?/}{/};

    my $reqid = $self->{REQUEST_ID};
    my $request = HTTP::Request::Common::GET(
        $url,
        "Client-DAAP-Version"      => '3.0',
        "Client-DAAP-Access-Index" => 2,
        $reqid ? ( "Client-DAAP-Request-ID" => $reqid ) : (),
        $self->_validation_cookie( $path, 2, $reqid ),
       );

    #print ">>>>\n", $request->as_string, ">>>>>\n";

    # It would seem that 4.{5,6} are using their internal MD5/M4p for
    # their digest auth, or some other form of evil, certainly the
    # regular Digest auth that works with 4.2 gets refused.

    #local *Digest::MD5::new = sub { shift; Digest::MD5::M4p->new( @_ ) }
    #  if $self->{M4p_evil};

    @credentials = $self->{PASSWORD} ? ('iTunes_4.6', $self->{PASSWORD}) : ();

    if ($file) {
        $res = $ua->request($request, $file);
    } else {
        $res = $ua->request($request);
    }
    # complain if the server sent back the wrong response
    unless ($res->is_success) {
        $self->error("$url\n" . $res->as_string);
        return;
    }

    my $content_type = $res->header("Content-Type");
    if ($req !~ m{(?:/items/\d+\.|logout)} && $content_type !~ /dmap/) {
        $self->error("Broken response (content type $content_type) on $url");
        return;
    }

    if ($file) {
        return $res;           # return obj to avoid copying huge string
    } else {
        return $res->content;
    }
}

1;

__END__

=head1 LIMITATIONS

No authentication.  No updates.  No browsing.  No searching.

=head1 AUTHOR

Nathan Torkington, <nathan AT torkington.com>.  For support, join the
DAAP developers mailing list by sending mail to <daap-dev-subscribe
AT develooper.com>.  See the AUTHORS file in the distribution for other
contributors.

Richard Clamp <richardc@unixbeard.net> took on maintainership duties
for the 0.4 and subsequent releases.

=head1 SEE ALSO

Net::DAAP::DMAP

=cut
