package Music::Audioscrobbler::Submit;
our $VERSION = 0.05;

# Copyright (c) 2008 Edward J. Allen III

#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=pod

=for changes stop

=head1 NAME

Music::Audioscrobbler::Submit - Module providing routines to submit songs to last.fm using 1.2 protocol.

=for readme stop

=head1 SYNOPSIS

    use Music::Audioscrobbler::Submit
    my $mpds = Music::Audioscrobbler::Submit->new(\%options); 

    $mpds->submit("/path/to/song.mp3");

=for readme continue

=head1 DESCRIPTION

Music::Audioscrobbler::Submit is a scrobbler for MPD implementing the 1.2 protocol, including "Now Playing' feature. 

Items are submitted and stored in a queue.  This queue is stored as a file using Tie::File.  When you submit a track,
it will add the queue to the track and process the queue.  If it submits all items in the queue, the L<submit()> method
will return true.  A method called L<process_scrobble_queue()> allows you to try again in case of failure.  Do not submit
songs more than once!

=begin readme

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

   Encode
   File::Spec
   Digest::MD5
   Config::Options
   LWP
   Tie::File
   Music::Tag

=end readme

=cut

use strict;
use warnings;
use File::Spec;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode);
use IO::File;
use Config::Options;
use LWP::UserAgent;
use Tie::File;


sub default_options {
    {  lastfm_username => undef,
       lastfm_password => undef,
       mdb_opts        => {},
       musicdb         => 0,
       musictag        => 0,
       musictag_overwrite => 0,
       verbose         => 1,
       timeout         => 15,      # Set low to prevent missing a scrobble.  Rather retry submit.
       logfile            => undef,
       scrobble_queue     => $ENV{HOME} . "/.musicaudioscrobbler_queue",
       optionfile       => [ "/etc/musicmpdscrobble.conf", $ENV{HOME} . "/.musicmpdscrobble.conf" ],
       lastfm_client_id => "tst",
       lastfm_client_version => "1.0",
       get_mbid_from_mb => 0,
       proxy_server     => undef,
       #lastfm_client_id => "mam",
       #lastfm_client_version => "0.1",
       music_tag_opts        => {
                           quiet     => 1,
                           verbose   => 0,
                           ANSIColor => 0,
                         },
    };
}

=pod

=head1 METHODS

=over 4

=item new()

    my $mas = Music::Audioscrobbler::Submit->new($options);

=cut

sub new {
    my $class   = shift;
    my $options = shift || {};
    my $self    = {};
    bless $self, $class;
    $self->options( $self->default_options );
    if ($options->{optionfile}) {
        $self->options->options("optionfile", $options->{optionfile});
    }
    $self->options->fromfile_perl( $self->options->{optionfile} );
    $self->options($options);
    $self->{scrobble_ok} = 1;

    unless ( $self->options('lastfm_md5password') ) {
        if ( $self->options('lastfm_password') ) {
            $self->options->{lastfm_md5password} =
              Digest::MD5::md5_hex( $self->options->{lastfm_password} );
            delete $self->options->{lastfm_password};
        }
        else {
            $self->status(0, "ERORR: lastfm_password option is not set. Please update config file. This error is fatal.");
            die "Bad password info."
        }
    }

    if ($self->options->{lastfm_client_id} eq "tst") {
        $self->status(0, "WARNING: Using client id 'tst' is for testing only.  Please use an assigned ID");
    }
    return $self;
}

=pod

=item options()

Get or set options via hash.  Here is a list of available options:

=over 4

=item lastfm_username        

lastfm username

=item lastfm_password        

lastfm password.  Not needed if lastfm_md5password is set.

=item lastfm_md5password 

MD5 hash of lastfm password. 

=item lastfm_client_id

Client ID provided by last.fm.  Defaults to "tst", which is valid for testing only.

=item lastfm_client_version

Set to the version of your program when setting a valid client_id.  Defaults to "1.0"

=item verbose                

Set verbosity level (1 through 4)

=item logfile                

File to output log info to. If set to "STDERR" or undef, will print messages to STDERR. If set to "STDOUT" will print messages to STDOUT.

=item scrobble_queue        

Path to file to queue info to.  Defaults to  ~/.musicaudioscrobbler_queue

=item get_mbid_from_mb

Use the Music::Tag::MusicBrainz plugin to get missing "mbid" value.  Defaults false.

=item musictag            

True if you want to use L<Music::Tag> to get info from file.  This is important if you wish to use filenames to submit from.

=item musictag_overwrite			

True if you want to Music::Tag info to override file info.  Defaults to false, which with the unicode problems with Music::Tag is a good thing.

=item music_tag_opts        

Options for L<Music::Tag>

=item proxy_server

URL for proxy_server in the form http://my.proxy.ca:8080

=back

=cut

sub options {
    my $self = shift;
    if ( exists $self->{_options} ) {
        return $self->{_options}->options(@_);
    }
    else {
        $self->{_options} = Config::Options->new();
        return $self->{_options}->options(@_);
    }
}

=item default_options()

Returns a reference to the default options.

=cut

=item now_playing()

Takes a file, hashref, or Music::Tag object and submits the song to Last.FM now playing info. For example: 

    $mas->now_playing("/path/to/file.mp3");

The hash reference is of the form:

        { artist   => "Artist Name",   # Mandatory
          title    => "Song Title"     # Mandatory
          secs     => 300,             # Length of time in seconds (integers only please). Mandatory
          album    => "Album",         # Optional
          tracknum => 12,              # Optional
          mbid     => '6299a467-95bc-4bc1-925d-71c4e556770d'  # Optional
        }
 
=cut

sub now_playing {
    my $self = shift;
    my $info = shift;
    my $h    = $self->info_to_hash($info);
    return unless ( defined $h );
    unless ( $self->{session_id} && ( ( time - $self->{timestamp} ) < 3600 ) ) {
        my $h = $self->handshake();
        unless ($h) { return $h; }
    }
    my @sub = ();
    push @sub, "s", $self->{session_id};
    push @sub, "a", $h->{artist};
    push @sub, "t", $h->{title};
    push @sub, "b", $h->{album};
    push @sub, "l", $h->{secs};
    push @sub, "n", $h->{track};
    push @sub, "m", $h->{mbid};
    my $q = $self->_makequery(@sub);
    my $req = HTTP::Request->new( 'POST', $self->{nowplaying_url} );

    unless ($req) {
        die 'Could not create the submission request object';
    }
    $self->status( 2,
                   "Notifying nowplaying info to ",
                   $self->{nowplaying_url},
                   " with query: $q\n" );
    $req->content_type('application/x-www-form-urlencoded; charset="UTF-8"');
    $req->content($q);
    my $resp = $self->ua->request($req);
    $self->status( 2, "Response to submission is: ",
                   $resp->content, " and success is ",
                   $resp->is_success );
    my @lines = split /[\r\n]+/, $resp->content;
    my $status = shift @lines;

    if ( $status eq "OK" ) {
        $self->status( 1, "Notification OK" );
        return 1;
    }
    elsif ( $status eq "BADSESSION" ) {
        $self->status( 0, "Bad session code: ", @lines );
        $self->{session_id} = 0;
        return 0;
    }
    else {
        $self->status( 0, "Unknown Error: ", $status, " ", @lines );
        return undef;
    }
}

=item submit() 


To submit a song pass an arrayref whose first entry is a File, Music::Tag object, or hashref (see L<now_playing()>) for format) and whose second entry is
an integer representing the seconds since epoch (UNIX time).  Several songs can be submitted simultaneously.  For example:

    $mas->submit->(["/path/to/file.mp3", time]);

or:

    $mas->submit->( ["/var/mp3s/song1.mp3", time - 600 ], 
                    ["/var/mp3s/song2.mp3", time - 300 ], 
                    ["/var/mp3s/song3.mp3", time ] );

Returns true if song was scrobbled, false otherwise. submit calls L<process_scrobble_queue()>.  If it fails, L<process_scrobble_queue()> can be called
again.

The following is taken from L<http://www.audioscrobbler.net/development/protocol/>: 

The client should monitor the user's interaction with the music playing service to whatever extent the service allows. In order to qualify for submission all of the following criteria must be met:

1. The track must be submitted once it has finished playing. Whether it has finished playing naturally or has been manually stopped by the user is irrelevant.

2. The track must have been played for a duration of at least 240 seconds or half the track's total length, whichever comes first. Skipping or pausing the track is irrelevant as long as the appropriate amount has been played.

3. The total playback time for the track must be more than 30 seconds. Do not submit tracks shorter than this.

4. Unless the client has been specially configured, it should not attempt to interpret filename information to obtain metadata instead of tags (ID3, etc).

=cut

sub submit {
    my $self = shift;
    foreach my $s (@_) {
        my ( $info, $timestamp ) = @{$s};
        my $h = $self->info_to_hash($info);
        if ($h) {
            push @{ $self->scrobble_queue }, $self->_serialize_info( $h, $timestamp );
        }
    }
    $self->process_scrobble_queue;
}

=item process_scrobble_queue()

Processes the current scrobble queue.  Call this if submit fails and you wish to try again.  Do not resubmit a song.

=cut

# Process up to 50 files from scrobble_queue. Recursivly calls itself if necessary / possible to empty scrobble_queue
sub process_scrobble_queue {
    my $self = shift;
    return -1 unless scalar @{ $self->scrobble_queue };
    my @submit = ();
    foreach ( @{ $self->scrobble_queue } ) {
        push @submit, [ $self->_deserialize_info($_) ];
        if ( scalar @submit >= 50 ) {
            last;
        }
    }
    my $ok = $self->_do_submit(@submit);
    if ($ok) {
        foreach (@submit) {
            shift @{ $self->scrobble_queue };
        }
        if ( scalar @{ $self->scrobble_queue } ) {
            $self->process_scrobble_queue;
        }
    }
    return $ok;
}

sub _do_submit {
    my $self = shift;
    unless ( $self->{session_id} && ( ( time - $self->{timestamp} ) < 3600 ) ) {
        my $h = $self->handshake();
        unless ($h) { return $h; }
    }
    my @sub = ();
    push @sub, "s", $self->{session_id};
    my $n = 0;
    foreach my $s (@_) {
        my ( $info, $timestamp ) = @{$s};
        my $h = $self->info_to_hash($info);
        next unless ( defined $h );
        push @sub, "a[$n]", $h->{artist};
        push @sub, "t[$n]", $h->{title};
        push @sub, "i[$n]", $timestamp;
        push @sub, "o[$n]", "P";            # Nothing but P supported yet.
        push @sub, "r[$n]", "";             # Not supported yet.
        push @sub, "l[$n]", $h->{secs};
        push @sub, "b[$n]", $h->{album};
        push @sub, "n[$n]", $h->{track};
        push @sub, "m[$n]", $h->{mbid};
        $self->status( 1, "Submitting: ", scalar localtime($timestamp),
                       " ", $h->{artist}, " - ", $h->{title} );
        $n++;
    }
    my $q = $self->_makequery(@sub);
    my $req = HTTP::Request->new( 'POST', $self->{submission_url} );
    unless ($req) {
        die 'Could not create the submission request object';
    }
    $self->status( 2, "Performing submission to ", $self->{submission_url}, " with query: $q\n" );
    $req->content_type('application/x-www-form-urlencoded; charset="UTF-8"');
    $req->content($q);
    my $resp = $self->ua->request($req);
    $self->status( 2, "Response to submission is: ",
                   $resp->content, " and success is ",
                   $resp->is_success );

    my @lines = split /[\r\n]+/, $resp->content;

    my $status = shift @lines;
    if ( $status eq "OK" ) {
        $self->status( 1, "Submission OK" );
        return 1;
    }
    elsif ( $status eq "BADSESSION" ) {
        $self->status( 0, "Bad session code: ", @lines );
        $self->{session_id} = 0;
        return 0;
    }
    else {
        $self->status( 0, "Unknown Error: ", $status, " ", @lines );
        return undef;
    }
}

sub _serialize_info {
    my $self = shift;
    my ( $h, $timestamp ) = @_;
    my $ret = join( "\0", timestamp => $timestamp, %{$h} );
}

sub _deserialize_info {
    my $self = shift;
    my $in   = shift;
    my %ret  = split( "\0", $in );
    return ( \%ret, $ret{timestamp} );
}

sub _get_mbid {
    my $self = shift;
    my $info = shift;
    unless ($info->mb_trackid) {
        my $mb = $info->add_plugin("MusicBrainz");
        $mb->get_tag();
    }
}

=item handshake()

Perform handshake with Last.FM.  You don't need to call this, it will be called by L<submit()> or L<now_playing()> when necessary.

=cut

sub handshake {
    my $self      = shift;
    my $timestamp = time;
    my $auth      = md5_hex( $self->options->{lastfm_md5password} . $timestamp );
    my @query = ( 'hs' => "true",
                  'p'  => "1.2",
                  'c'  => $self->options->{lastfm_client_id},
                  'v'  => $self->options->{lastfm_client_version},
                  'u'  => $self->options->{lastfm_username},
                  't'  => $timestamp,
                  'a'  => $auth
                );
    my $q = $self->_makequery(@query);

    $self->status( 2, "Performing Handshake with query: $q\n" );

    my $req = new HTTP::Request( 'GET', "http://post.audioscrobbler.com/?$q" );
    unless ($req) {
        die 'Could not create the handshake request object';
    }
    my $resp = $self->ua->request($req);
    $self->status( 2, "Response to handshake is: ",
                   $resp->content, " and success is ",
                   $resp->status_line );
    unless ( $resp->is_success ) {
        $self->status( 0, "Response failed: ", $resp->status_line );
        return 0;
    }

    my @lines = split /[\r\n]+/, $resp->content;

    my $status = shift @lines;
    if ( $status eq "OK" ) {
        $self->{session_id}     = shift @lines;
        $self->{nowplaying_url} = shift @lines;
        $self->{submission_url} = shift @lines;
        $self->{timestamp}      = $timestamp;
        return $self->{session_id};
    }
    elsif ( $status eq "FAILED" ) {
        $self->status( 0, "Temporary Failure: ", @lines );
        return 0;
    }
    elsif ( $status eq "BADAUTH" ) {
        $self->status( 0, "Bad authorization code (I have the wrong password): ", @lines);
        die "Bad password\n";
    }
    elsif ( $status eq "BADTIME" ) {
        $self->status( 0, "Bad time stamp: ", @lines );
        return undef;
    }
    else {
        $self->status( 0, "Unknown Error: ", $status, " ", @lines );
        return undef;
    }
}



=item music_tag_opts()

Get or set the current options for new Music::Tag objects.

=cut

sub music_tag_opts {
    my $self    = shift;
    my $options = shift || {};
    my $mt_opts = { ( %{ $self->options->{music_tag_opts} }, %{$options} ) };
    return $mt_opts;
}


=item logfileout()

Glob reference (or IO::File) to current log file.  If passed a value, will use this instead of what the logfile option is set to.  Any glob reference that can be printed to will work (that's all we ever do). 

=cut

sub logfileout {
    my $self = shift;
    my $fh   = shift;
    if ($fh) {
        $self->{logfile} = $fh;
    }
    unless ( ( exists $self->{logfile} ) && ( $self->{logfile} ) ) {
        if ((not $self->options->{logfile}) or ($self->options->{logfile} eq "STDERR" )) {
            return \*STDERR;
        }
        elsif ($self->options->{logfile} eq "STDOUT" ) {
            return \*STDOUT;
        }
        my $fh = IO::File->new( $self->options->{logfile}, ">>" );
        unless ($fh) {
            print STDERR "Error opening log, using STDERR: $!";
            return \*STDERR;
        }
        $fh->autoflush(1);
        $self->{logfile} = $fh;
    }
    return $self->{logfile};
}


=item status()

Print to log. First argument is a level (0 - 4).  For example:

    $mas->status($level, @message);

=cut

sub status {
    my $self  = shift;
    my $level = shift;
    if ( $level <= $self->options->{verbose} ) {
        my $out = $self->logfileout;
        print $out scalar localtime(), " ", @_, "\n";
    }
}

=item scrobble_queue()

Returns a reference to the current scrobble_queue.  This is a tied hash using Tie::File.  Useful to found out how many items still need to be
scrobbled after a failed L<submit()>.

=cut

sub scrobble_queue {
    my $self = shift;
    unless ( ( exists $self->{scrobble_queue} ) && ( $self->{scrobble_queue} ) ) {
        my @q;
        tie @q, 'Tie::File', $self->options("scrobble_queue")
          or die "Couldn't tie array to scrobble_queue: " . $self->options("scrobble_queue");
        $self->{scrobble_queue} = \@q;
    }
    return $self->{scrobble_queue};
}


=item ua()

Returns the LWP::UserAgent used. If passed a value, will use that as the new LWP::UserAgent object.

=cut

sub ua {
    my $self = shift;
    my $ua   = shift;
    unless ( ( exists $self->{ua} ) && ( ref $self->{ua} ) ) {
        $self->{ua} = LWP::UserAgent->new();
        $self->{ua}->env_proxy();
        $self->{ua}->agent( 'scrobbler-helper/1.0 ' . $self->{ua}->_agent() );
        $self->{ua}->timeout( $self->options->{timeout} );
        if ($self->options->{proxy_server}) {
            $self->{ua}->proxy('http', $self->options->{proxy_server}) 
        }
    }
    unless ( $self->{'ua'} ) {
        die 'Could not create an LWP UserAgent object?!?';
    }
    return $self->{'ua'};
}

sub _URLEncode($) {
    my $theURL = shift;
    if (defined $theURL) {
        utf8::upgrade($theURL);
        $theURL =~ s/([^a-zA-Z0-9_\.])/'%' . uc(sprintf("%2.2x",ord($1)));/eg;
        return $theURL;
    }
}

sub _makequery {
    my $self  = shift;
    my @query = @_;
    my $q     = "";
    for ( my $i = 0 ; $i < @query ; $i += 2 ) {
        if ($q) { $q .= "&" }
        $q .= $query[$i] . "=" . _URLEncode( $query[ $i + 1 ] );
    }
    return $q;
}

=item info_to_hash()

Takes a filename, hashref, or Music::Tag object and returns a hash with the structure required by L<submit()> or L<now_playing>.  
Normally this is called automatically by L<submit()> or L<now_playing>.  See L<now_playing> for syntax of hash.

Examples:

    my $hash = $mas->info_to_hash("/path/to/mp3/file.mp3");

is functionally equivalent to 

    my $hash = $mas->info_to_hash(Music::Tag->new("/path/to/mp3/file.mp3", $mas->music_tag_opts() ));

=cut

sub info_to_hash {
    my $self = shift;
    my $info = shift;
    if ( ref $info eq "HASH" ) {
        if ( exists $info->{filename} ) {
            eval {
                my $extra = $self->_get_info_from_file( $info->{filename} );
                while ( my ( $k, $v ) = each %{$extra} ) {
                    next if ( ( $k eq "secs" ) && ( exists $info->{secs} ) && ( $info->{secs} > 30 ) );
                    if (($self->options->{musictag_overwrite}) or ( not $info->{$k})) {
                        $self->status(4, "Setting $k to $v from Music::Tag\n");
                        $info->{$k} = $v;
                    }
                }
            };    # eval'd to protect from a bad Music::Tag plugin causing trouble.
            if ($@) { $self->status( 0, "Error with Music::Tag: ", $@ ) }
        }
        foreach (qw(artist title secs album track mbid tracknum)) {
            unless ( exists $info->{$_} ) {
                $info->{$_} = "";
            }
            if ( exists $info->{mb_trackid} ) {
                $info->{mbid} = $info->{mb_trackid};
            }
            if ( exists $info->{length} ) {
                $info->{secs} = $info->{length};
            }
            unless ( $info->{secs} ) {
                $info->{secs} = 300;
            }
        }
        return $info;
    }
    elsif ( ref $info ) {
        my $ret = {};
        $ret->{artist}   = $info->artist;
        $ret->{title}    = $info->title;
        $ret->{secs}     = int( $info->secs ) || 300;
        $ret->{album}    = $info->album || "";
        $ret->{track} = $info->track || "";
        if (($self->options->{get_mbid_from_mb}) && (not $info->mb_trackid)) {
            $self->status(2, "Attempting to get mbid from MusicBrainz");
            $self->_get_mbid($info, {quiet => 1, verbose => 0});
            if ($info->mb_trackid) {
                $self->status(2, "Got mbid: ", $info->mb_trackid);
            }
            else {
                $self->status(2, "Failed to get mbid from MusicBrainz");
            }
        }
        $ret->{mbid}     = $info->mb_trackid || "";
        return $ret;
    }
    elsif ( -f $info ) {
        return $self->_get_info_from_file($info);
    }
    $self->status( 0, "Hash or Music::Tag object or filename required!" );
    return undef;
}


sub _get_info_from_file {
    my $self = shift;
    my $file = shift;
    return unless ( $self->options->{musictag} );
    require Music::Tag;
    $self->status( 3, "Filename $file detected" );
    my $minfo = Music::Tag->new( $file, $self->music_tag_opts() );
    if ($minfo) {
        if ( $self->options->{musicdb} ) {
            $minfo->add_plugin("MusicDB");
        }
        $minfo->get_tag;
        $self->status( 4, "Filename $file is really " . $minfo->title );
        return $self->info_to_hash($minfo);
    }
}

=back

=head1 SEE ALSO

L<Music::Tag>, L<Music::Audioscrobbler::MPD>

=for changes continue

=head1 CHANGES

=over 4

=item Release Name: 0.05

=over 4

=item *

Added new option: proxy_server to set proxy_server.  Also now reads proxy server from enviroment.

=back

=back

=over 4

=item Release Name: 0.04

=over 4

=item *

I noticed that Music::Tag was called with a use function.  Removed this line to remove Music::Tag requirement. 

=item *

Added some more level 4 debuging messages.

=back

=back

=over 4

=item Release Name: 0.03

=over 4

=item *

Added musictag_overwrite option. This is false by default. It is a workaround for problems with Music::Tag and unicode.  Setting this to
true allows Music::Tag info to overwrite info from MPD.  Do not set this to true until Music::Tag returns proper unicode consistantly.

=back

=back

=over 4

=item Release Name: 0.02

=over 4

=item *

Will print error and die if lastfm_password is not set.

=item *

Will print error and die if BADAUTH is received. 

=back

=item Release Name: 0.01

=over 4

=item *

Initial Release

=back

=back

=for changes stop

=for readme continue

=head1 AUTHOR 

Edward Allen III <ealleniii _at_ cpan _dot_ org>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Edward Allen III. Some rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either:

a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

b) the "Artistic License" which comes with Perl.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA or visit their web page on the Internet at
http://www.gnu.org/copyleft/gpl.html.


=cut

1;
