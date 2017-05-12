package POE::Component::NomadJukebox;

###########################################################################
### POE::Component::NomadJukebox
### David Davis (xantus@cpan.org)
###
### Copyright (c) 2004 David Davis.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.
###########################################################################

use strict;
use POE;
# import these, the other functions are OO
use POE::Component::NomadJukebox::Device qw(Discover Open ProgressFunc);
use MP3::Tag;
use Carp qw(croak);

our $VERSION = '0.02';

# our device constants
#sub NJB_DEVICE_NJB1 { 0x00 }
#sub NJB_DEVICE_NJB2 { 0x01 }
#sub NJB_DEVICE_NJB3 { 0x02 }
#sub NJB_DEVICE_NJBZEN { 0x03 }
#sub NJB_DEVICE_NJBZEN2 { 0x04 }
#sub NJB_DEVICE_NJBZENNX { 0x05 }
#sub NJB_DEVICE_NJBZENXTRA { 0x06 }
#sub NJB_DEVICE_DELLDJ { 0x07 }

=pod

=head1 NAME

POE::Component::NomadJukebox - Event-based contol of Nomad Jukebox players

=head1 SYNOPSIS

	use POE qw(COmponent::NomadJukebox);
	use Data::Dumper;
	
	POE::Session->create(
		inline_states => {
			_start => sub {
				POE::Component::NomadJukebox->create({ alias => 'njb' });
			},
			njb_started => sub {
				$_[KERNEL]->post(njb => 'discover');
			},
			njb_discover => sub {
				my ($kernel, $heap, $devlist) = @_[KERNEL, HEAP, ARG0];

				unless (ref($devlist)) {
					print "Failed to find Nomad Jukebox, is it on?\n";
					$kernel->post(njb => 'shutdown');
					return;
				}
			
				# open the first device
				# pass the device id to open
				$kernel->post(njb => 'open' => $devlist->[0]->{DEVID});		
			},
			njb_opened => sub {
				my $kernel = $_[KERNEL];
				$kernel->post(njb => 'disk_usage');
				$kernel->post(njb => 'track_list');
			},
			njb_disk_usage => sub {
				my ($kernel, $heap, $info) = @_[KERNEL, HEAP, ARG0];
		
				unless (ref($info) eq 'HASH') {
					print "Failed to get disk usage\n";
					return;
				}
				my $used = $info->{TOTAL} - $info->{FREE};
				print "Total:$info->{TOTAL} bytes Free:$info->{FREE} bytes Used:$used bytes\n";
				$kernel->post(njb => 'shutdown');
			},
			njb_track_list => sub {
				my ($kernel, $heap, $tracks) = @_[KERNEL, HEAP, ARG0];
	
				$kernel->post(njb => 'shutdown');
				
				unless (ref($tracks) eq 'ARRAY') {
					print "Failed to get track list\n";
					return;
				}
				print "There are ".scalar(@$tracks)." tracks\n";
				
				print Data::Dumper->Dump([$tracks]);
			},
			njb_closed => sub {
				print "Nomad Jukebox closed\n";
			},
		},
	);

	$poe_kernel->run();

=head1 DESCRIPTION

POE::Component::NomadJukebox - Event-based contol of Nomad Jukebox players
using the libnjb api located at http://libnjb.sourceforge.net/

This module _requires_ libnjb and you may need to be root, or change your
usb device access permissions.

=head1 METHODS

=head2 create({ alias => 'njb', progress => 'njb_progress' })

Creates a session to handle the Nomad Jukebox device.  You can specify two
options: alias, what to call the session, and progress, what event should
be fired during a file transfer.

=cut

sub create {
	my ($class, $opt) = @_;

	return POE::Session->create(
		 #options =>{ trace=>1 },
		 args => [ $opt ],
		 package_states => [
			eval { __PACKAGE__ } => {
				_start			=> '_start',
				_stop			=> '_stop',
				shutdown		=> 'shutdown',

				track_list		=> 'track_list',
				play_list		=> 'play_list',
				delete_play_list => 'delete_play_list',
				file_list		=> 'file_list',
				discover		=> 'discover',
				open			=> 'open',
				get_track		=> 'get_track',
				close			=> 'close',
				delete_track	=> 'delete_track',
				delete_file		=> 'delete_file',
				send_track		=> 'send_track',
				send_file		=> 'send_file',
				get_file		=> 'get_file',
				play			=> 'play',
				stop			=> 'stop',
				pause			=> 'pause',
				resume			=> 'resume',
				seek_track		=> 'seek_track',
				get_owner		=> 'get_owner',
				set_owner		=> 'set_owner',
				get_tmpdir		=> 'get_tmpdir',
				set_tmpdir		=> 'set_tmpdir',
				disk_usage		=> 'disk_usage',
				_progress		=> '_progress',
				adjust_sound	=> 'adjust_sound',
			}
		],
	)->ID;
}

# keeps poe alive while sending/receiving files
# heres where the magic happends
sub progress {
	#my $heap = $poe_kernel->alias_resolve($alias->{alias})->get_heap();
	#$heap->{progress_postback}->(@_);

	$poe_kernel->yield('_progress' => @_);

	$poe_kernel->loop_do_timeslice();
}

sub _start {
	my ($kernel, $heap, $sender, $opt) = @_[KERNEL, HEAP, SENDER, ARG0];

	croak 'options passed to '.__PACKAGE__.' must be in a hash ref' unless (ref($opt) eq 'HASH');
	
	$heap->{reply} = $sender->ID;

	%{$heap->{opts}} = %{$opt};
	$heap->{alias} = $opt->{alias} || 'njb';
	$heap->{progress} = $opt->{progress_event} || 'njb_progress';
	
	$kernel->alias_set($heap->{alias});
	
	$kernel->post($sender => 'njb_started');
}

sub _stop {
	# anything?
	if ($_[HEAP]->{open}) {
		print STDERR "closing\n";
		$_[KERNEL]->call($_[SESSION] => 'close');
	}
}

sub _progress {
	my ($kernel, $heap, $sofar, $total) = @_[KERNEL, HEAP, ARG0, ARG1];

	return unless ($heap->{progress});

	$kernel->call($heap->{reply} => $heap->{progress} => splice(@_,ARG0));
}

=pod

=head1 EVENTS

All these events can be called with $kernel->call(), and the return values
are usually undef on error, or an id in the case of send_track or send_file.

=head2 discover

Locates all connected, and turned on, Nomad Jukebox devices.
Fires njb_discover event with an array ref of hash refs with info about each
device in the keys to the parent session or undef if it failed to find any
devices. 

=cut

sub discover {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	my @ret = Discover();
	if (scalar(@ret) > 0) {
#		foreach my $v (@ret) {
#			my $t = $v->{TYPE};
#			if ($t & NJB_DEVICE_NJB1) {
#				$v->{NAME} = 'njb_1';
#			} elsif ($t & NJB_DEVICE_NJB2) {
#				$v->{NAME} = 'njb_2';
#			} elsif ($t & NJB_DEVICE_NJB3) {
#				$v->{NAME} = 'njb_3';
#			} elsif ($t & NJB_DEVICE_NJBZEN) {
#				$v->{NAME} = 'njb_zen';
#			} elsif ($t & NJB_DEVICE_NJBZEN2) {
#				$v->{NAME} = 'njb_zen_2';
#			} elsif ($t & NJB_DEVICE_NJBZENNX) {
#				$v->{NAME} = 'njb_zen_nx';
#			} elsif ($t & NJB_DEVICE_NJBZENXTRA) {
#				$v->{NAME} = 'njb_zen_xtra';
#			} elsif ($t & NJB_DEVICE_DELLDJ) {
#				$v->{NAME} = 'dell_dj';
#			} else {
#				$v->{NAME} = 'unknown';
#			}
#		}
		$kernel->post($heap->{reply} => 'njb_discover' => \@ret);
		return \@ret;
	} else {
		$kernel->post($heap->{reply} => 'njb_discover' => undef);
		return undef;
	}
}

=pod

=head2 open => <device_id>

This will open the device specified by the device_id from the discover event.
You MUST do this before sending any other events that operate on the device.
This fires the njb_opened event to the parent on success with the device id as
ARG0 and 1 as ARG1.  On failure to open the device, ARG1 for the njb_open event
will be undef.

=cut

# TODO add the ability to control more than one with a single component
sub open {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	croak 'open event needs device' unless ($_[ARG0]);

	my $ret = Open($_[ARG0]);
	if ($ret) {
		$_[HEAP]->{open} = $_[ARG0];
		# save the obj
		$heap->{njb} = $ret;
		
		# setup the progress postback
		my $sender = $kernel->ID_id_to_session($heap->{reply});
		$heap->{progress_postback} = $sender->postback($heap->{progress});
		ProgressFunc(\&progress);
		
		# notify that its opened
		# XXX I'm leaving ARG2 undocumented
		$kernel->post($heap->{reply} => 'njb_opened' => $_[ARG0] => 1 => $heap->{njb});
		return (1,$heap->{njb});
	}
	$kernel->post($heap->{reply} => 'njb_open' => $_[ARG0] => undef);
	return undef;
}

=pod

=head2 track_list

Requests the track list from the device.  It fires njb_track_list with an
array ref of hash refs.  Each hash ref has info about the track.  ID is
the important key for other events like play, and get_track.  If you pass
a 1 as ARG0 to track_list, extended tags will be turned on, but it will
be much slower. (AND IT BLOCKS LONGER)

=cut

sub track_list {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $tracks = [$heap->{njb}->TrackList($_[ARG0])];

	$kernel->post($heap->{reply} => 'njb_track_list' => $tracks);

	return $tracks;
}

=pod

=head2 play_list

Requests the play list from the device.  It fires njb_play_list with an
array ref of hash refs.  Each hash ref has info about the track.  ID is
the important key for other events like play, and get_track.

Here's an example of a playlist dump, notice that I have a playlist with
no valid tracks.  Make sure you account for these end cases.  The array
in the TRACKS key is a list of track ID's from the track_list.  The STATE
key 0 is new, 1 is unchanged, 2 is change name, 3 change tracks.  I'm not
sure what 2 and 3 mean yet.

	{
		'TRACKS' => [],
		'ID' => 71520,
		'NAME' => 'Audio Tour',
		'STATE' => 1
	},
	{
		'TRACKS' => [
			390228,
			430204,
			517265,
			515625,
			516250,
			514989,
			513963,
			517909,
			516878,
			511915
		],
		'ID' => 727376,
		'NAME' => 'aaa',
		'STATE' => 3
	}

=cut

sub play_list {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $tracks = [$heap->{njb}->PlayList()];

	$kernel->post($heap->{reply} => 'njb_play_list' => $tracks);

	return $tracks;
}

=pod

=head2 file_list

Requests the file list from the device.  It fires njb_file_list with an
array ref of hash refs.  Each hash ref has info about the file.  ID is
the important key for other events like get_file, delete_file.

=cut

sub file_list {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $tracks = [$heap->{njb}->FileList()];

	$kernel->post($heap->{reply} => 'njb_file_list' => $tracks);

	return $tracks;
}

=pod

=head2 get_track => { <track_hashref> } => </path/to/file.mp3>

This event will retrieve the track specified by the track hashref from the 
track_list event and it will save it to the path specified.  The full
directory path should exist, it will not create it for you.  The track hash
ref should have the TAG key (for speed) or the ID key, all others are not
used.

=cut

sub get_track {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->GetTrack(@_[ARG0,ARG1]);

	$kernel->post($heap->{reply} => 'njb_get_track' => (@_[ARG0,ARG1],$ret));
	return $ret;
}

=pod

=head2 close

Releases control of the device.  You probably want to use the shutdown event.
This fires the njb_closed event to the parent.

=cut

sub close {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	delete $heap->{open};
	return undef unless ($heap->{njb});
	
	$heap->{njb}->Close();
	$kernel->post($heap->{reply} => 'njb_closed');
	
	return 1;
}

=pod

=head2 set_owner => 'owner name'

Allows you to set the owner's name.  Fires njb_set_owner with
the owner info sent in ARG0 and the return value in ARG1.

=cut

sub set_owner {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->SetOwner($_[ARG0]);
	$kernel->post($heap->{reply} => 'njb_set_owner' => $_[ARG0] => $ret);
	return $ret;
}

=pod

=head2 get_owner

Fires njb_owner event back to parent with owner info in ARG0.

=cut

sub get_owner {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $owner = $heap->{njb}->GetOwner();
	$kernel->post($heap->{reply} => 'njb_owner' => $owner);
	return $owner;
}

=pod

=head2 send_track => '/path/to/file.mp3' or send_track => <hashref track info>

This will send a file to the Nomad Jukebox.  You can specify the full path to
the file, and allow the component to extract the mp3 tags (using MP3::Tag), or
you can specify them yourself with a hashref with the following keys:

	FILE => '/path/to/file.mp3',
	CODEC => 'MP3', # MP3, WMA, or WAV
	TITLE => 'Title of song',
	TRACK => '6',
	ARTIST => 'Art Ist',
	ALBUM => 'POEtry',
	GENRE => 'Rock'

It will fire the send_track event to the parent session with the track info in
a hash ref as ARG0 and the trackid as ARG1 on success.  On failure ARG1 will
be undef and ARG2 _might_ have an error string.

=cut

sub send_track {
	my ($kernel, $heap, $track) = @_[KERNEL,HEAP, ARG0];

	return undef unless ($heap->{njb});

	unless (ref($track) eq 'HASH') {
		my $t = {
			FILE => $track,
		};
		unless (-e $track) {
			$kernel->post($heap->{reply} => njb_send_track => $t => undef
				=> 'file not found');
			return undef;
		}
		if ($track =~ m/mp3$/i) {
			$t->{CODEC} = 'MP3';			
			# TODO does the jukebox support anything other than MP3
	    	my $mp3 = MP3::Tag->new($track);
			if ($mp3) {
				($t->{TITLE}, $t->{TRACK}, $t->{ARTIST}, $t->{ALBUM})
					= $mp3->autoinfo();
				if (exists $mp3->{ID3v1}) {
					$t->{GENRE} =  $mp3->{ID3v1}->{genre};
				}
			}
		} elsif ($track =~ m/wma$/i) {
			# TODO WMA info?
			$t->{CODEC} = 'WMA';
		} elsif ($track =~ m/wav$/i) {
			# TODO WAV info?
			$t->{CODEC} = 'WAV';
		} else {
			$kernel->post($heap->{reply} => njb_send_track => $t => undef
				=> 'file type not supported, use send_file event instead');
			return undef;
		}
		$track = $t;
	}

	# TODO check if all needed keys are in refhash

	my $ret = $heap->{njb}->SendTrack($track);
	if (defined $ret) {
		$kernel->post($heap->{reply} => njb_send_track => $track => $ret);
		return $ret;
	} else {
		$kernel->post($heap->{reply} => njb_send_track => $track => undef => $!);
		return undef;
	}
}

=pod

=head2 send_file => { FILE => '/path/to/file.tar.gz', NAME => 'file.tar.gz' }

This will send a file to the Nomad Jukebox.  It will fire event njb_send_file
with the file hash ref as ARG0 and the fileid as ARG1.  On failure, ARG1 will
be undef, and ARG2 _might_ have an error string.

=cut

sub send_file {
	my ($kernel, $heap, $file) = @_[KERNEL,HEAP, ARG0];

	return undef unless ($heap->{njb});

	unless (ref($file) eq 'HASH') {
		$kernel->post($heap->{reply} => njb_send_file => $file => undef
			=> 'ARG0 to send_track must be a hash ref');
		return undef;
	}

	# TODO check if all needed keys are in refhash

	unless (-e $file->{FILE}) {
		$kernel->post($heap->{reply} => njb_send_file => $file => undef
			=> 'file not found');
		return undef;
	}

	my $ret = $heap->{njb}->SendFile($file);
	if (defined $ret) {
		$kernel->post($heap->{reply} => njb_send_file => $file => $ret);
		return $ret;
	} else {
		$kernel->post($heap->{reply} => njb_send_file => $file => undef => $!);
		return undef;
	}
}

=pod

=head2 get_file => { ID => <ID> } => </path/to/file.tar.gz>

This event will retrieve the file specified by the ID in the hash ref  
and it will save it to the path specified.  The full directory path should
exist, it will not create it for you.  I used a hash ref so I could expand
the file selection at a later time, (ie. by NAME). It fires njb_get_file 
with the hash ref as ARG0 the file path as ARG1 and the return value as ARG2.

=cut

sub get_file {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->GetFile(@_[ARG0,ARG1]);

	$kernel->post($heap->{reply} => 'njb_get_file' => (@_[ARG0,ARG1],$ret));
	return $ret;
}

=pod

=head2 play => <ID>

Starts a track specified by <ID> you can get this id by looking at the ID key
of a track in the track list.  See the track_list event.  Fires njb_play event
back to parent session.  ARG0 is the <ID> and ARG1 is the return value.

=cut

sub play {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->PlayTrack($_[ARG0]);
	
	$kernel->post($heap->{reply} => 'njb_play' => $_[ARG0] => $ret);

	return $ret;
}

=pod

=head2 stop

Stops playback, and it fires njb_stop event back to parent session.  The
return value is in ARG0.

=cut

sub stop {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->StopPlay();
	
	$kernel->post($heap->{reply} => 'njb_stop' => $ret);

	return $ret;
}

=pod

=head2 pause

Pauses playback, and it fires njb_pause event back to parent session. The
return value is in ARG0.

=cut

sub pause {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->PausePlay();
	
	$kernel->post($heap->{reply} => 'njb_pause' => $ret);

	return $ret;
}

=pod

=head2 resume

Resumes playback, and it fires njb_resume event back to parent session. The
return value is in ARG0.

=cut

sub resume {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->ResumePlay();
	
	$kernel->post($heap->{reply} => 'njb_resume' => $ret);

	return $ret;
}

=pod

=head2 seek_track => <position>

Seeks playing track to <position>. It fires njb_seek_track event
back to parent session.

=cut

sub seek_track {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->SeekTrack($_[ARG0]);
	
	$kernel->post($heap->{reply} => 'njb_seek_track' => $_[ARG0] => $ret);

	return $ret;
}

=pod

=head2 set_tmpdir => '/tmp/path'

Allows you to set the temp directory.  Fires njb_set_tmpdir with
the temp dir in ARG0 and the return value in ARG1.

=cut

sub set_tmpdir {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->SetTmpDir($_[ARG0]);
	$kernel->post($heap->{reply} => 'njb_set_tmpdir' => $_[ARG0] => $ret);
	return $ret;
}

=pod

=head2 get_tmpdir

Fires njb_tmpdir event back to parent with temp dir in ARG0.

=cut

sub get_tmpdir {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $dir = $heap->{njb}->GetTmpDir();
	$kernel->post($heap->{reply} => 'njb_tmpdir' => $dir);
	return $dir;
}

=pod

=head2 shutdown

Releases control of the Nomad Jukebox with close() and ends the session.  This
DOES NOT shutdown the actual device, just the component.

=cut

sub shutdown {
	my ($kernel, $heap) = @_[KERNEL,HEAP];
	
	if ($heap->{njb}) {
		$heap->{njb}->Close();
		delete $heap->{njb};
	}
	
	$kernel->alias_remove($heap->{alias});
}

=pod

=head2 delete_play_list => <plid>

Allows you to delete a playlist.  Fires njb_delete_play_list with
the playlist id in ARG0 and the return value in ARG1.

=cut

sub delete_play_list {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->DeletePlayList($_[ARG0]);
	$kernel->post($heap->{reply} => 'njb_delete_play_list' => $_[ARG0] => $ret);
	return $ret;
}

=pod

=head2 delete_track => <trackid>

Allows you to delete a track.  Fires njb_delete_track with
the playlist id in ARG0 and the return value in ARG1.

=cut

sub delete_track {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->DeleteTrack($_[ARG0]);
	$kernel->post($heap->{reply} => 'njb_delete_track' => $_[ARG0] => $ret);
	return $ret;
}

=pod

=head2 delete_file => <fileid>

Allows you to delete a file.  Fires njb_delete_file with
ehe file id in ARG0 and the return value in ARG1.

=cut

sub delete_file {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $ret = $heap->{njb}->DeleteFile($_[ARG0]);
	$kernel->post($heap->{reply} => 'njb_delete_file' => $_[ARG0] => $ret);
	return $ret;
}

=pod

=head2 disk_usage

Requests the disk usage from the device.  It fires njb_disk_usage with a
hash ref, with keys TOTAL, and FREE, both in bytes.  ARG0 will be undef instead
of a hash ref on error.  This event can also be called, it returns total, 
and free in an array context, and undef on error.

=cut

sub disk_usage {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $info = $heap->{njb}->DiskUsage();

	if (ref($info) eq 'HASH') {
		$kernel->post($heap->{reply} => 'njb_disk_usage' => $info);
		return ($info->{TOTAL},$info->{FREE});
	}
	$kernel->post($heap->{reply} => 'njb_disk_usage' => undef);
	return undef;
}

=pod

=head2 adjust_sound => <type> => <value>

Changes various aspects of sound from the device.  It fires njb_adjust_sound
with the return value. The types: volume, bass, treble, muting, midrange,
midfreq, eax, eaxamt, headphone, rear, and eqstatus.
**NOTE: only volume is supported by libnjb, so don't expect any of the others
to work until somone updates libnjb with this ability.

=cut

sub adjust_sound {
	my ($kernel, $heap) = @_[KERNEL,HEAP];

	return undef unless ($heap->{njb});

	my $type;
	my %types = (
		volume		=> 0x01,
		bass		=> 0x02,
		treble		=> 0x03,
		muting		=> 0x04,
		midrange	=> 0x05,
		midfreq		=> 0x06,
		eax			=> 0x07,
		eaxamt		=> 0x08,
		headphone	=> 0x09,
		rear		=> 0x0A,
		eqstatus	=> 0x0D,
	);
	if (exists($types{lc($_[ARG0])})) {
		$type = $types{lc($_[ARG0])};
	} else {
		$kernel->post($heap->{reply} => 'njb_adjust_sound' => undef);
		return undef;
	}

	my $ret = $heap->{njb}->AdjustSound($type,$_[ARG1]);

	if ($ret) {
		$kernel->post($heap->{reply} => 'njb_adjust_sound' => $ret);
		return $ret;
	}
	$kernel->post($heap->{reply} => 'njb_adjust_sound' => undef);
	return undef;
}
1;
__END__

=head1 UNSOLICTED EVENTS

During file transfers, the njb_progress event (or other event specified to 
create()) will be fired throughout the transfer with ARG1 being the total
bytes, and ARG0 being the amount of bytes transferred.

=head1 EXAMPLES

See the examples directory for working code to get you started.
I'll add more example scripts at a later time.

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>

=head1 THANKS

Anthony Taylor for PerlNJB, I based the driver on his unfinished api.

=head1 BUGS

Probably.  Send the author an email about the error.

During file transfers, the poe engine may slow down a bit.  I will
probably fix this by changing transfers to fork beforehand.

=head1 TODO

There are some more api functions I need to cover.

=head1 SEE ALSO

perl(1), L<MP3::Tag>

=cut
