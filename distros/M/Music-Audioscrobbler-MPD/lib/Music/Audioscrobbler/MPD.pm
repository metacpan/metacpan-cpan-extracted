package Music::Audioscrobbler::MPD;
our $VERSION = 0.13;
require 5.006;

# Copyright (c) 2007 Edward J. Allen III
# Some code and inspiration from Audio::MPD Copyright (c) 2005 Tue Abrahamsen, Copyright (c) 2006 Nicholas J. Humfrey, Copyright (c) 2007 Jerome Quelin

#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#


# the GNU Public License.  Both are distributed with Perl.

=pod

=for changes stop

=head1 NAME

Music::Audioscrobbler::MPD - Module providing routines to submit songs to last.fm from MPD.

=for readme stop

=head1 SYNOPSIS

	use Music::Audioscrobbler::MPD
	my $mpds = Music::Audioscrobbler::MPD->new(\%options); 
	$mpds->monitor_mpd();

=for readme continue

=head1 DESCRIPTION

Music::Audioscrobbler::MPD is a scrobbler for MPD. As of version .1, L<Music::Audioscrobbler::Submit> is used to submit information to last.fm. 

All internal code is subject to change.  See L<musicmpdscrobble> for usage info.  

=begin readme

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 CONFIGURATION

There is a sample config file under examples.  A sample init file that I use for 
gentoo linux is there as well.

=head1 USE

Edit the sample config file and copy to /etc/musicmpdscrobble.conf or ~/.musicmpdscrobble.conf

Test your configuration by issue the command

    musicmpdscrobble --logfile=STDERR --monitor

and playing some music.  

If it works, then the command

    musicmpdscrobble --daemonize 

will run musicmpdscrobble as a daemon.  Please see examples for a sample init script.  If you make an init script
for your distribution, please send it to me!

=head1 DEPENDENCIES

This module requires these other modules and libraries:

    Music::Audioscrobbler::Submit
    File::Spec
    Digest::MD5
    Encode
    IO::Socket
    IO::File
    Config::Options

I strongly encourage you to also install my module

    Music::Tag

This will allow you to read info from the file tag (such as the MusicBrainz ID).

The version info in the Makefile is based on what I use.  You can get 
away with older versions in many cases.

=end readme

=head1 MORE HELP

Please see the documentation for L<musicmpdscrobble> which is available from 

    musicmpdscrobble --longhelp

=for readme stop

=cut

use strict;
use warnings;
use Music::Audioscrobbler::Submit;
use File::Spec;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode);
use IO::Socket;
use IO::File;
use Config::Options;
use POSIX qw(WNOHANG);
#use Storable;


sub _default_options {
    {  lastfm_username    => undef,
       lastfm_password    => undef,
       mdb_opts           => {},
       musictag           => 0,
       musictag_overwrite => 0,
       verbose            => 1,
       monitor            => 1,
       daemonize          => 0,
       timeout            => 15,      # Set low to prevent missing a scrobble.  Rather retry submit.
       pidfile            => "/var/run/musicmpdscrobble.pid",
       logfile            => undef,
       default_cache_time => 86400,
       mpd_password       => undef,
       allow_stream       => 0,
       mpd_server         => $ENV{MPD_HOST} || 'localhost',
       mpd_port           => $ENV{MPD_PORT} || 6600,
       music_directory    => "/mnt/media/music/MP3s",
       scrobble_queue     => $ENV{HOME} . "/.musicaudioscrobbler_queue",
       optionfile       => [ "/etc/musicmpdscrobble.conf", $ENV{HOME} . "/.musicmpdscrobble.conf" ],
       runonstart       => [],
       runonsubmit      => [],
       lastfm_client_id => "mam",
       lastfm_client_version => "0.1",
       music_tag_opts        => {
                           quiet     => 1,
                           verbose   => 0,
                           ANSIColor => 0,
                         },
    };
}

=head1 METHODS

=over 4

=item new()

	my $mpds = Music::Audioscrobbler::MPD->new($options);

=cut

sub new {
    my $class   = shift;
    my $options = shift || {};
    my $self    = {};
    bless $self, $class;
    $self->options( $self->_default_options );
	if ($options->{optionfile}) {
		$self->options->options("optionfile", $options->{optionfile});
	}
    $self->options->fromfile_perl( $self->options->{optionfile} );
    $self->options($options);
    $self->{scrobble_ok} = 1;
    $self->_convert_password();

	if ($self->options->{lastfm_client_id} eq "tst") {
		$self->status(0, "WARNING: Using client id 'tst' is NO LONGER approved.  Please use 'mam' or other assigned ID");
	}
    if ($self->options("mpd_server") =~ /^(.*)@(.*)/) {
    	$self->options->{"mpd_server"} = $2;
    	$self->options->{"mpd_password"} = $1;
    }
    return $self;
}

sub _convert_password {
    my $self = shift;
    unless ( $self->options('lastfm_md5password') ) {
        if ( $self->options('lastfm_password') ) {
            $self->options->{lastfm_md5password} =
              Digest::MD5::md5_hex( $self->options->{lastfm_password} );
            delete $self->options->{lastfm_password};
        }
    }
}


=item monitor_mpd()

Starts the main loop. 

=cut

sub monitor_mpd {
    my $self = shift;
    $self->status( 1, "Starting Music::Audioscrobbler::MPD version $VERSION" );
    while (1) {
        if ( $self->is_connected ) {
            $self->update_info();
            sleep 1;
        }
        else {
            $self->connect;
            sleep 4;
        }
        unless ( $self->{scrobble_ok} ) {
            if ( ( time - $self->{lastscrobbled} ) > 600 ) {
                $self->{scrobble_ok}   = $self->mas->process_scrobble_queue();
                $self->{lastscrobbled} = time;
            }
        }
		$self->_reaper();
    }
}

=item options()

Get or set options via hash.  Here is a list of available options:

=over 4

=item optionfile		    

Perl file used to get options from

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

=item mpd_server			

hostname of mpd_server

=item mpd_port

port for mpd_server

=item mpd_password		

mpd password

=item verbose				

Set verbosity level (1 through 4)

=item logfile				

File to output loginfo to

=item scrobblequeue		

Path to file to queue info to

=item music_directory		

Root to MP3 files

=item get_mbid_from_mb

Use the Music::Tag::MusicBrainz plugin to get missing "mbid" value.

=item runonsubmit			

Array of commands to run after submit

=item runonstart			

Array of commands to run on start of play

=item monitor				

True if monitor should be turned on

=item musictag			

True if you want to use Music::Tag to get info from file

=item musictag_overwrite			

True if you want to Music::Tag info to override file info


=item music_tag_opts		

Options for Music::Tag 

=item proxy_server

Specify a procy server in the form http://proxy.server.tld:8080.  Please note that environment is checked for HTTP_PROXY, so you may not need this option.

=item allow_stream

If set to true, will scrobble HTTP streams. 

=back

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

=head1 INTERNAL METHODS (for reference)

=over

=item mpdsock()

returns open socket to mpd program.

=cut

sub mpdsock {
    my $self = shift;
    my $new  = shift;
    if ($new) {
        $self->{mpdsock} = $new;
    }
    unless ( exists $self->{mpdsock} ) {
        $self->{mpdsock} = undef;
    }
    return $self->{mpdsock};
}

=item connect()

Connect to MPD if necessary

=cut

sub connect {
    my $self = shift;
    if ( ( $self->mpdsock ) && ( $self->is_connected ) ) {
        $self->status( 3, "Already connected just fine." );
        return 1;
    }

    $self->mpdsock(
                    IO::Socket::INET->new( PeerAddr => $self->options("mpd_server"),
                                           PeerPort => $self->options("mpd_port"),
                                           Proto    => 'tcp',
                                         )
                  );

    unless ( ( $self->mpdsock ) && ( $self->mpdsock->connected ) ) {
        $self->status( 1, "Could not create socket to mpd: $!" );
        return 0;
    }

    if ( $self->mpdsock->getline() =~ /^OK MPD (.+)$/ ) {
        $self->{mpd_sever_version} = $1;
    }
    else {
        $self->status( 1, "Bad response from mpd ($!)" );
        return 0;
    }
    $self->send_password if $self->options("mpd_password");
    return 1;
}

=item is_connected()

Return true if connected to mpd.

=cut

sub is_connected {
    my $self = shift;
    if ( ( $self->mpdsock ) && ( $self->mpdsock->connected ) ) {
        $self->mpdsock->print("ping\n");
        return ( $self->mpdsock->getline() =~ /^OK/ );
    }
    return undef;
}

=item process_feedback

Process response from mpd.

=cut

sub process_feedback {
    my $self = shift;
    my @output;
    if ( ( $self->mpdsock ) && ( $self->mpdsock->connected ) ) {
        while ( my $line = $self->mpdsock->getline() ) {
            chomp($line);

            # Did we cause an error? Save the data!
            if ( $line =~ /^ACK \[(\d+)\@(\d+)\] {(.*)} (.+)$/ ) {
                $self->{ack_error_id}         = $1;
                $self->{ack_error_command_id} = $2;
                $self->{ack_error_command}    = $3;
                $self->{ack_error}            = $4;
                $self->status( 1, "Error sent to MPD: $line" );
                return undef;
            }
            last if ( $line =~ /^OK/ );
            push( @output, $line );
        }
    }

    # Let's return the output for post-processing
    return @output;
}

=item send_command($command)

send a command to mpd.

=cut

sub send_command {
    my $self = shift;
    if ( $self->is_connected ) {
        $self->mpdsock->print( @_, "\n" );
        return $self->process_feedback;
    }
}

=item send_password($command)

send password to mpd.

=cut

sub send_password {
    my $self = shift;
    $self->send_command( "password ", $self->options("mpd_password"));
}

=item get_info($command)

Send mpd a command and parse the output if output is a column seperated list.

=cut

sub get_info {
    my $self    = shift;
    my $command = shift;
    my $ret     = {};
    foreach ( $self->send_command($command) ) {
        if (/^(.[^:]+):\s(.+)$/) {
            $ret->{$1} = $2;
        }
    }
    return $ret;
}

=item get_status($command)


get_status command. Returns hashref with:

    *  volume: (0-100)
    * repeat: (0 or 1)
    * random: (0 or 1)
    * playlist: (31-bit unsigned integer, the playlist version number)
    * playlistlength: (integer, the length of the playlist)
    * playlistqueue: (integer, the temporary fifo playlist version number)
    * xfade: <int seconds> (crossfade in seconds)
    * state: ("play", "stop", or "pause")
    * song: (current song stopped on or playing, playlist song number)
    * songid: (current song stopped on or playing, playlist songid)
    * time: <int elapsed>:<time total> (of current playing/paused song)
    * bitrate: <int bitrate> (instantaneous bitrate in kbps)
    * audio: <int sampleRate>:<int bits>:<int channels>
    * updating_db: <int job id>
    * error: if there is an error, returns message here 

=cut

sub get_status {
    my $self = shift;
    $self->get_info("status");
}

=item get_current_song_info($command)

get_status command. Returns hashref with:

    file: albums/bob_marley/songs_of_freedom/disc_four/12.bob_marley_-_could_you_be_loved_(12"_mix).flac
    Time: 327
    Album: Songs Of Freedom - Disc Four
    Artist: Bob Marley
    Title: Could You Be Loved (12" Mix)
    Track: 12
    Pos: 11
    Id: 6601

=cut

sub get_current_song_info {
    my $self = shift;
    $self->get_info("currentsong");
}

=item status($level, @message)

Print to log.

=cut

sub status {
    my $self  = shift;
    my $level = shift;
    if ( $level <= $self->options->{verbose} ) {
        my $out = $self->logfileout;
        print $out scalar localtime(), " ", @_, "\n";
    }
}

=item logfileout 

returns filehandle to log.

=cut

sub logfileout {
    my $self = shift;
    my $fh   = shift;
    if ($fh) {
        $self->{logfile} = $fh;
    }
	if ((not $self->options->{logfile}) or ($self->options->{logfile} eq "STDERR" )) {
        return \*STDERR;
	}
	elsif ($self->options->{logfile} eq "STDOUT" ) {
        return \*STDOUT;
	}
    unless ( ( exists $self->{logfile} ) && ( $self->{logfile} ) ) {
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

=item mas()

Reference to underlying Music::Audioscrobbler::Submit object. If passed a Music::Audioscrobbler::Submit object, will
use that one instead.

=cut

sub mas {
	my $self = shift;
    my $new = shift;
    if ($new) {
        $self->{mas} = $new;
    }
	unless ((exists $self->{mas}) && (ref $self->{mas})) {
		$self->{mas} = Music::Audioscrobbler::Submit->new($self->options);
		$self->{mas}->logfileout($self->logfileout);
	}
	return $self->{mas};
}

=item new_info($cinfo)

reset current song info.

=cut

sub new_info {
    my $self  = shift;
    my $cinfo = shift;
    $self->{current_song} = $cinfo->{file};
    if ( $self->{current_song} =~ /^http/i ) {
        if ($self->options("allow_stream")) {
            $self->{current_file} = 0;
        }
        else {
            $self->{current_file} = undef;
        }
    }
    elsif ( -e File::Spec->rel2abs( $self->{current_song}, $self->options->{music_directory} ) ) {
        $self->{current_file} =
          File::Spec->rel2abs( $self->{current_song}, $self->options->{music_directory} );
    }
    else {
        $self->status(1, "File not found: ", File::Spec->rel2abs( $self->{current_song}, $self->options->{music_directory} ));
        $self->{current_file} = 0;
    }
    my $h = { album    => $cinfo->{Album},
                                           artist   => $cinfo->{Artist},
                                           title    => $cinfo->{Title},
                                           secs     => $cinfo->{Time},
                                         };
    if ($self->options->{musictag}) {
        $h->{filename} = $self->{current_file};
    }
    $self->{info} = $self->mas->info_to_hash( $h );

    #Prevent excessive calls to info_to_hash
    delete $self->{info}->{filename};

    $self->{song_duration}     = $cinfo->{Time};
    $self->{current_id}        = $cinfo->{Id};
    $self->{running_time}      = 0;
    $self->{last_running_time} = undef;
    $self->{state}             = "";
    $self->{started_at}        = time;
    $self->status( 1, "New Song: ", $self->{current_id}, " - ", ($self->{current_file} ? $self->{current_file} : "Unknown File: $self->{current_song}")  );
}

=item song_change($cinfo)

Run on song change

=cut

sub song_change {
    my $self  = shift;
    my $cinfo = shift;
    if ( ( defined $self->{current_file} )
         and (    ( $self->{running_time} >= 240 )
               or ( $self->{running_time} >= ( $self->{song_duration} / 2 ) ) )
         and ( ( $self->{song_duration} >= 30 ) or ( $self->{info}->{mbid} ) )
      ) {
        $self->scrobble();
        $self->run_commands( $self->options->{runonsubmit} );
    }
    else {
        $self->status( 4, "Not scrobbling ",
                       $self->{current_file}, " with run time of ",
                       $self->{running_time} );
    }
    my $state = $self->{state};
    $self->new_info($cinfo);
    if ( ( defined $self->{current_file} ) && ( $cinfo->{Time} ) && ( $state eq "play" ) ) {
        $self->status( 4, "Announcing start of play for: ", $self->{current_file} );
        $self->mas->now_playing( $self->{info} );
        $self->run_commands( $self->options->{runonstart} );
    }
    else {
        $self->status( 4, "Not announcing start of play for: ", $self->{current_file} );
    }
    $self->status("4", "Storing debug info");
    #$Storable::forgive_me = 1;
    #store($self, $self->options->{logfile}.".debug");
}

=item update_info()

Run on poll

=cut

sub update_info {
    my $self   = shift;
    my $status = $self->get_status;
    my $cinfo  = $self->get_current_song_info();
    $self->{state} = $status->{state};
    my ( $so_far, $total ) = (0,0);
    if ($status->{'time'}) {
        ( $so_far, $total ) = split( /:/, $status->{'time'} );
    }
    my $time = time;
    if ( $self->{state} eq "play" ) {
        unless ( $cinfo->{Id} eq $self->{current_id} ) {
            $self->song_change($cinfo);
        }
        unless ( defined $self->{last_running_time} ) {
            $self->{last_running_time} = $so_far;
        }
        unless ( defined $self->{last_update_time} ) {
            $self->{last_update_time} = $time;
        }
        my $run_since_update = ( $so_far - $self->{last_running_time} );

        my $time_since_update =
          ( $time - $self->{last_update_time} ) + 5;    # Adding 5 seconds for rounding fudge

        if ( ( $run_since_update > 0 ) && ( $run_since_update <= $time_since_update ) ) {
            $self->{running_time} += $run_since_update;
        }
        elsif (    ( $run_since_update < -240 )
                or ( $run_since_update < ( -1 * ( $self->{song_duration} / 2 ) ) ) ) {
            $self->status(
                3,
                "Long skip back detected ( $run_since_update ).  You like this song.  Scrobbling... "
            );
            $self->song_change($cinfo);
        }
        elsif ($run_since_update) {
            $self->status( 3, "Skip detected, ignoring time change." );
        }
        $self->{last_running_time} = $so_far;
        $self->{last_update_time}  = $time;
    }
    elsif ( ( $self->{state} eq "stop" ) && ( $self->{running_time} ) ) {
        $self->song_change($cinfo);
    }
    if ( $self->options->{monitor} ) {
        $self->monitor();
    }
}


=item monitor()

print current status to STDERR

=cut

sub monitor {
    my $self = shift;
    printf STDERR "%5s ID: %4s  TIME: %5s             \r", $self->{state} ? $self->{state} : "", $self->{current_id} ? $self->{current_id} : "",
      $self->{running_time} ? $self->{running_time} : "";
}


=item scrobble()

Scrobble current song

=cut

sub scrobble {
    my $self = shift;
    if ( defined $self->{current_file} ) {
        $self->status( 2, "Adding ", $self->{current_file}, " to scrobble queue" );
        $self->{scrobble_ok} = $self->mas->submit( [ $self->{info}, $self->{started_at} ] );
        $self->{lastscrobbled} = time;
    }
    else {
        $self->status( 3, "Skipping stream: ", $self->{current_file} );
    }
}


=item run_commands()

Fork and run list of commands.

=cut

sub run_commands {
    my $self     = shift;
    my $commands = shift;
    return unless ( ( ref $commands ) && ( scalar @{$commands} ) );
    my $pid = fork;
    if ($pid) {
		$self->_toreap($pid);
        $self->status( 4, "Forked to run commands\n" );
    }
    elsif ( defined $pid ) {
        if ( $self->options->{logfile} ) {
            my $out = $self->logfileout;
            open STDOUT, ">&", $out;
            select STDOUT;
            $| = 1;
            open STDERR, ">&", $out;
            select STDERR;
            $| = 1;
        }
        foreach my $c ( @{$commands} ) {
            $c =~ s/\%f/$self->{current_file}/e;
            $c =~ s/\%a/$self->{info}->{artist}/e;
            $c =~ s/\%b/$self->{info}->{album}/e;
            $c =~ s/\%t/$self->{info}->{title}/e;
            $c =~ s/\%l/$self->{info}->{secs}/e;
            $c =~ s/\%n/$self->{info}->{track}/e;
            $c =~ s/\%m/$self->{info}->{mbid}/e;
            my $s = system($c);
            delete $self->{fh};

            if ($s) {
                $self->status( 0, "Failed to run command: ${c}: $!" );
            }
            else {
                $self->status( 2, "Command ${c} successful" );
            }
        }
        exit;
    }
    else {
        $self->status( 0, "Failed to fork for commands: $!" );
    }
}

sub _toreap {
	my $self = shift;
	my $pid = shift;
	unless (exists $self->{reapme}) {
		$self->{reapme} = [];
	}
	push @{$self->{reapme}}, $pid;
}

sub _reaper {
	my $self = shift;
	if (exists $self->{reapme}) {
		my @newreap = ();
		foreach (@{$self->{reapme}}) {
			(waitpid $_, WNOHANG) or push @newreap, $_;
		}
		if (@newreap) {
			$self->{reapme} = \@newreap;
		}
		else {
			delete $self->{reapme};
		}
	}
}


=back

=head1 SEE ALSO

L<musicmpdscrobble>, L<Music::Audioscrobbler::Submit>, L<Music::Tag>

=for changes continue

=head1 CHANGES

=over 4

=item Release Name: 0.13

=over 4

=item *

Added option allow_stream, which will allow scrobbling of http streams if set to true (default false).  Feature untested.

=item *

Fixed bug in password submition (thanks joeblow1102)

=item *

Added support for password@host value in MPD_HOST

=item *

Searched, without success, for memory leak. If anyone wants to help, uncomment the Storable lines and start looking into it...

=item *

Added (documented) support for Proxy server

=back

=back

=over 4

=item Release Name: 0.12

=over 4

=item *

Fixed bug that sometimes prevented Music::Tag from working at all.  Added some level 4 debug messages.

=back

=back


=over 4

=item Release Name: 0.11

=over 4

=item *

Added musictag_overwrite option. This is false by default. It is a workaround for problems with Music::Tag and unicode.  Setting this to
true allows Music::Tag info to overwrite info from MPD.  Do not set this to true until Music::Tag returns proper unicode consistantly.

=back

=back

=over 4

=item Release Name: 0.1

=over 4

=item *

Split off all scrobbling code to Music::Audioscrobbler::Submit

=item *

Added an error message if file is not found.

=item *

Added use warnings for better debugging.

=item *

Started using Pod::Readme for README and CHANGES

=back

=begin changes

=item Release Name: 0.09

=over 4

=item *

Added waffelmanna's patch to fix the password submital to MPD.

=back

=item Release Name: 0.08

=over 4

=item *

musicmpdscrobble daemonizes after creating Music::Audioscrobber::MPD object which allows pidfile to be set in options file (thanks K-os82)

=item *

Kwalitee changes such as pod fixes, license notes, etc. 

=item *

Fixed bug which prevented working with a password to mpd.

=item *

Fixed bug causing reaper to block.

=back

=item Release Name: 0.07

=over 4

=item *

Fixed Unicode issues with double encoding (thanks slothck)

=item *

Stoped using URI::Encode which did NOT solve locale issues.

=back

=item Release Name: 0.06

=over 4

=item *

Configured get_mbid_from_mb to only grab if missing.

=item *

Changed to using URI::Encode

=item *

Fixed bug preventing log file from loading from command line.

=back

=item Release Name: 0.05

=over 4

=item *

Fixed bug with log file handles (thanks T0dK0n)

=item *

Fixed bug caused when music_directory not set  (thanks T0dK0n)

=item *

Revised Documentation Slightly

=item *

Fixed bug in kill function for musicmpdscrobble

=item *

Added option get_mbid_from_mb to get missing mbids using Music::Tag::MusicBrainz

=back

=item Release Name: 0.04

=over 4

=item *

Have been assigned Client ID.  If you set this in your configs, please remove.

=back

=item Release Name: 0.03

=over 4

=item *

Name change for module.  Is now Music::Audioscrobbler::MPD.  Uninstall old version to facilitate change!

=item *

Repeating a song isn't a skip anymore (or rather skipping back a scrobblable distance is not a skip)

=item *

Only submits a song <30 seconds long if it has an mbid.

=item *

Very basic test script for sanity.

=back

=item Release Name: 0.02

=over 4

=item *

Fixed bug caused my Music::Tag returning non-integer values for "secs" (thanks tunefish)

=item *

Along same lines, configure to not use Music::Tag secs values, but trust MPD

=back

=item Release Name: 0.01

=over 4

=item *

Initial Release

=item *

Basic routines for scrobbling MPD.  Code from Music::Audioscrobbler merged for now.

=back

=end changes

=back

=for changes stop

=for readme continue

=head1 AUTHOR

Edward Allen, ealleniii _at_ cpan _dot_ org

=head1 COPYRIGHT

Copyright (c) 2007 Edward J. Allen III

Some code and inspiration from L<Audio::MPD> 
Copyright (c) 2005 Tue Abrahamsen, Copyright (c) 2006 Nicholas J. Humfrey, Copyright (c) 2007 Jerome Quelin

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
