package POE::Wheel::Audio::Mad;
require 5.6.0;

use strict;
use warnings;

our $VERSION = '0.3';

## version 0.3 basically means,  I've rewritten this a few times,
## screwed version numbers completely up,  came up with this idea,
## modified it twice,  and just barely documented it.  That means
## there's pod to describe it's usage,  but very little in the
## way of interal comments -- wait for 0.4;  the comment overhaul
## release.

use Carp qw(croak);

use POE;
use POE::Wheel;

use Audio::Mad qw(:all);
use Audio::Mad::Util qw(mad_stream_info mad_parse_xing mad_cbr_seek mad_xing_seek);

use Audio::OSS qw(:funcs :formats :mixer);

## the list of states that we will define in our parent session.
our @STATES = qw(
	decoder_shutdown decoder_close decoder_set decoder_info
	decoder_open decoder_play decoder_pause decoder_stop decoder_seek

	__d_input_open __d_input_read __d_input_close
	__d_output_open __d_output_close
	__d_decoder_reset __d_decoder_cycle
);

##############################################################################

sub new {
	my ($class, %args) = @_;

	croak "$class requires a working POE Kernel" unless (defined($poe_kernel));
	croak "$class requires a message_event paramater" unless (defined($args{message_event}));

	my $self = bless({ 
		message_event => $args{message_event},
		wheel_id      => POE::Wheel::allocate_wheel_id(),
	}, $class);

	$self->{options} = {
		output_close_on_pause  => $args{output_close_on_pause} || 0,
		output_close_on_stop   => $args{output_close_on_stop}  || 1,
		
		decoder_progress_range => $args{decoder_progress_range} || 100,
		decoder_play_on_open   => $args{decoder_play_on_open}   || 0,
	};

	$self->{input} = {
		state    => 'CLOSED',
		
		handle   => undef,
		filename => '',
		stats    => [(0)x13],
		
		buffer   => '',
		info     => {},
	};
	
	$self->{decoder} = {
		state    => 'CLOSED',
		
		stream   => undef,
		frame    => undef,
		synth    => undef,
		resample => undef,
		dither   => undef,

		played   => undef,
		printed  => 0,
		progress => 0,
		frames   => 0,
	};
	
	$self->{output} = {
		state         => 'CLOSED',
		
		handle        => undef,

		device        => $args{output_device}     || '/dev/dsp',
		samplerate    => $args{output_samplerate} || 44100,
		format        => $args{output_format}     || AFMT_S16_LE,
		
		mixer_device  => $args{mixer_device}  || '/dev/mixer',
		mixer_balance => $args{mixer_balance} || 50,
		mixer_volume  => $args{mixer_volume}  || 50,
		mixer_pcm     => $args{mixer_pcm}     || 60
	};
	
	for (@STATES) { 
		croak "$class failed to define state: $_\n" if ($poe_kernel->state( $_ => $self ));
	}
	
	return $self;	
}

sub DESTROY {
	my ($self) = @_;
	
	for (@STATES) { $poe_kernel->state( $_ ) }
	POE::Wheel::free_wheel_id( $self->{wheel_id} );
}

sub decoder_shutdown {
	my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];

	## we ->call() the next few functions to make sure that
	## they finish before we disappear as a session..
	
	$kernel->call($session, '__d_output_close');
	$kernel->call($session, '__d_input_close');
	$kernel->call($session, '__d_decoder_reset');

	## let everyone know that we're dying..
	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_SHUTDOWN_SUCCESS',
		data => ''
	});
	
	$kernel->yield('shutdown');
}

##############################################################################

sub decoder_open {
	my ($self, $kernel, $session, $args) = @_[OBJECT, KERNEL, SESSION, ARG0];
	
	my ($filename, $play) = @{$args}{qw(filename play)};

	## call deeper to accomplish the actual opening
	## and scanning of the stream..
	$kernel->call($session, '__d_input_open', $filename);

	## we couldn't find or open the file,  or we scanned
	## it and didn't get any valid stream information..
	return undef unless (
		$self->{input}->{state} eq 'OPEN'        &&
		$self->{input}->{filename} eq $filename
	);
	
	## reset the decoder..
	$kernel->call($session, '__d_decoder_reset');
	
	## and start playing if that's what we're supposed to do..
	$kernel->yield('decoder_play') if ($play || $self->{options}->{decoder_play_on_open});
}

sub decoder_close { 
	my ($kernel, $session) = @_[KERNEL, SESSION];
	
	## close is rather heavy handed,  it does everything a
	## shudown does without actually disappearing..

	$kernel->call($session, '__d_output_close');
	$kernel->call($session, '__d_input_close');
	$kernel->call($session, '__d_decoder_reset');
}

sub decoder_play {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
	
	## check to see if we have a file to play,  and generate
	## an event if we don't..
	
	unless ($self->{input}->{state} eq 'OPEN') {
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_PLAY_FAILED',
			data => 'no input file open'
		});
		return undef;
	}
	
	## make sure that the output is open,  or at least try really hard to open it..
	
	$kernel->call($session, '__d_output_open') unless ($self->{output}->{state} eq 'OPEN');
	return undef unless ($self->{output}->{state} eq 'OPEN');

	## update our state to indicate that we are playing,  and generate 
	## an event to tell everyone we are playing..	

	$self->{decoder}->{state} = 'PLAYING';
	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_STATUS_DATA',
		data => { state => 'PLAYING' }
	});
	
	## let decoder_cycle spin off on it's chore..
	
	$kernel->yield('__d_decoder_cycle');
}

sub decoder_pause {
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	
	## check to see that we are currently playing a file
	## and generate an event if we aren't..
	unless ($self->{decoder}->{state} eq 'PLAYING') {
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_PAUSE_FAILED',
			data => 'not playing file'
		});
		return undef;
	}
	
	## close down the output device if we're told to do so..
	
	$kernel->yield('__d_output_close') if ($self->{options}->{output_close_on_pause});

	## indicate we are paused,  and tell everyone about it..	

	$self->{decoder}->{state} = 'PAUSED';
	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_STATUS_DATA',
		data => { state => 'PAUSED' }
	});
}

sub decoder_stop {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];

	## make sure we can stop and generate something if not..
	
	unless (
	    $self->{decoder}->{state} eq 'PLAYING' ||
	    $self->{decoder}->{state} eq 'PAUSED'
	) {
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_STOP_FAILED',
			data => 'not playing file'
		});
		return undef;
	}

	## save and indicate our current status..

	$self->{decoder}->{state} = 'STOPPED';
	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_STATUS_DATA',
		data => { state => 'STOPPED' }
	});

	## here we seek the input file back to the beginning,  and close
	## the output device if that's what we're supposed to do.	

	$kernel->yield('decoder_seek', { position => 0, range => 1 });
	$kernel->yield('__d_output_close') if ($self->{options}->{output_close_on_stop});
}

sub decoder_seek {
	my ($kernel, $self, $session, $args) = @_[KERNEL, OBJECT, SESSION, ARG0];
	my ($position, $range) = @{$args}{qw(position range)};
	my ($input, $decoder) = @{$self}{qw(input decoder)};

	## check that we have an open file,  and generate something if not..

	unless ($input->{state} eq 'OPEN') {
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_SEEK_FAILED',
			data => 'no input file open'
		});	
		return undef;
	}

	## seeking is kind of tricky..  so we use some support 
	## functions that tell us how to seek.  pos is the
	## file position to seek to,  and frame is the frame
	## that will be played next..
	
	my ($pos, $frame);
	if ($input->{info}->{s_vbr} == 0) {
		## cbr seeking is easy,  see the referenced
		## function (below)..
	   	($pos, $frame) = mad_cbr_seek(
	   		position => $position, 
	   		range    => $range, 
	   		frames   => $input->{info}->{s_frames}, 
	   		size     => $input->{info}->{f_size}
	   	);
	} else {
		## vbr seeking isn't soo easy,  and requires us to use
		## an automatically generated toc from the mad_stream_info
		## routine..
		($pos, $frame) = mad_xing_seek(
			position => $position, 
			range    => $range, 
			frames   => $input->{info}->{s_frames}, 
			toc      => $input->{info}->{xing_toc}
		);
	}
	
	## if it's not a valid place to seek,  just forget it..
	
	return undef unless (defined($pos) && $pos > -1);

	## if we're seeking somewhere other than the beginning,  take
	## a copy of the frame duration,  and multiply it by our
	## destination frame -- this keeps DECODER_FRAME_DATA accurate.
	
	if (defined($frame) && $frame > 0) {
		$decoder->{played} = $input->{info}->{s_frame_duration}->new_copy();
		$decoder->{played}->multiply($frame);
	} else {
	
		## otherwise,  it's the beginning and we can just use a
		## zeroed out timer..
	
		$decoder->{played} = new Audio::Mad::Timer;
	}
	
	## force our 'printed' and 'progress' values out of date
	## so that they are updated and events get generated as
	## soon as we return to playing..
	
	$decoder->{printed}  = -1;
	$decoder->{progress} = -1;
	
	## actually perform the seek..
	
	CORE::seek($input->{handle}, $pos, 0);
	
	## clear our stream buffer,  avoids having to drain the 
	## buffer before we seek,  and helps prevent the audio 
	## from skipping and popping..
	
	$input->{buffer}    = '';

	## tell the decoder to bleed off three frames before
	## synthesizing audio data from the stream..  helps
	## prevent audio skips and pops..

	$decoder->{seeking} = 3;
	
	## reset the stream buffer completely..
	
	$decoder->{stream}  = new Audio::Mad::Stream(MAD_OPTION_IGNORECRC);

	## generate an event to let everyone know that the
	## stream position was just moved..
	
	$kernel->yield($self->{message_event}, {
		id   => 'INPUT_SEEK_SUCCESS',
		data => $pos
	});
	
	## and jump into decoder_cycle unless we would already 
	## do that soon..

	$kernel->yield('__d_decoder_cycle') unless ($decoder->{state} eq 'PLAYING');
}

## ugly,  ugly,  ugly..  but,  it was quick.  this is just an outpost for all 
## those abandoned options seen earlier,  there are lots of problems with
## the sub below,  and they'll be fixed as soon as I come up with a good
## options system,  that allows us to be notified when particular options
## get changed on us..

# set option <option> <value>
# set mixer <volume|pcm|balance> <value>
sub decoder_set {
	my ($self, $kernel, $session, $args) = @_[OBJECT, KERNEL, SESSION, ARG0];
	
	my ($type, $key, $value) = @{$args}{qw(type key value)};
	$type = '' unless (defined($type));
	
	if (lc($type) eq 'option') {
		unless (defined($self->{options}->{$key})) {
			$kernel->yield($self->{message_event}, {
				id   => 'IPC_COMMAND_FAILED',
				data => "OPTION unknown key $key"
			});
			return undef;
		} 
		
		## FIXME: gag,  need better option system..
		if ($key eq 'decoder_progress_range') { $self->{decoder}->{progress} = -1 }

		$self->{options}->{$key} = $value;
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_OPTION_DATA',
			data => { lc($key) => $value }
		});
	}
	elsif (lc($type) eq 'mixer') {
		   if ($key eq 'volume')  { $self->{output}->{mixer_volume}  = $value }
		elsif ($key eq 'pcm')     { $self->{output}->{mixer_pcm}     = $value }
		elsif ($key eq 'balance') { $self->{output}->{mixer_balance} = $value }
		else {
			$kernel->yield($self->{message_event}, {
				id   => 'IPC_COMMAND_FAILED',
				data => "MIXER unknown key $key"
			});
		}

		_mixer_update($self->{output});
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_MIXER_DATA',
			data => { 
				balance => $self->{output}->{mixer_balance},
				volume  => $self->{output}->{mixer_volume},
				pcm     => $self->{output}->{mixer_pcm}
			}
		});
	} else {
		$kernel->yield($self->{message_event}, {
			id   => 'IPC_COMMAND_FAILED',
			data => "SET unknown type $type"
		});
	}
}

sub decoder_info {
	my ($self, $kernel, $args) = @_[OBJECT, KERNEL, ARG0];
	my $type = $args->{type};

	## this is a simple routine,  designed to coherce the decoding
	## engine into immediately giving up some information about one
	## of it's subsystems..  pretty simple stuff here.  

	if (lc($type) eq 'decoder') {
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_OPTION_DATA',
			data => $self->{options}
		});
		
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_STATUS_DATA',
			data => { state => $self->{decoder}->{state} }
		});
		
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_FRAME_DATA',
			data => { 
				played   => $self->{decoder}->{printed},
				progress => $self->{decoder}->{progress}
			}
		});
	} elsif (lc($type) eq 'input') {
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_STATUS_DATA',
			data => { state => $self->{input}->{state} }
		});
		
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_INFO_DATA',
			data => $self->{input}->{info}
		}) if ($self->{input}->{state} eq 'OPEN');
	} elsif (lc($type) eq 'dsp') {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_MIXER_DATA',
			data => { 
				balance => $self->{output}->{mixer_balance},
				volume  => $self->{output}->{mixer_volume},
				pcm     => $self->{output}->{mixer_pcm}
			}
		});
		
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_STATUS_DATA',
			data => { state => $self->{output}->{state} }
		});
	} else {
		$kernel->yield($self->{message_event}, {
			id   => 'IPC_COMMAND_FAILED',
			data => "INFO unknown type $type"
		});	
	}
}

##############################################################################

## okay,  here's the gritty subsystem kind of stuff.  this is where all the 
## work actually happens -- and most of the logic is.  stay close,  it's
## dark down here...

sub __d_input_open {
	my ($kernel, $self, $session, $filename) = @_[KERNEL, OBJECT, SESSION, ARG0];

	## alias a hashref because we are lazy..

	my $input = $self->{input};
	
	## attempt to acquire a filehandle for our specified
	## file,  if not,  generate an event and quit..

	my ($handle);
	CORE::open($handle, '<'.$filename) || do {
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_OPEN_FAILED',
			data => "$filename: $!",
		});
		return undef;
	};
	
	## no we try to get some information on the stream,  and
	## tell mad_stream_info to generate a toc so we can seek.
	## if we fail,  tell everyone about it,  and close the
	## stream..
	
	my $info;
	unless (defined($info = mad_stream_info($handle, 1))) {
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_OPEN_FAILED',
			data => "$filename: unable to find mpeg stream"
		});
		CORE::close($handle);
		return undef;
	};
	
	## we close down the old input handle unless it already is..
	
	$kernel->call($session, '__d_input_close') unless ($input->{state} eq 'CLOSED');
	
	## after mad_stream_info runs the file position needs to be
	## moved back to the beginning..
	
	CORE::seek($handle, 0, 0);
	
	## now we can track all the extra little information about our 
	## new stream..
	
	$input->{handle} = $handle;

	$input->{filename} = $filename;
	$input->{stats}    = [stat($input->{handle})];
	$input->{info}     = $info;

	## mark that the input system is open,  and send events to
	## everyone so they know about it too..

	$input->{state}    = 'OPEN';

	$kernel->yield($self->{message_event}, {
		id   => 'INPUT_STATUS_DATA',
		data => { 
			state    => 'OPEN',
			filename => $filename
		}
	});

	## we make a copy of our stream information,  drop out
	## the table of contents (can be very large)..

	my %info = %{$input->{info}};
	delete $info{xing_toc};
	
	## and send it out to interested customers..
	
	$kernel->yield($self->{message_event}, {
		id   => 'INPUT_INFO_DATA',
		data => \%info
	});
}

sub __d_input_read {
	my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];

	## alias a hashref (lazy) and requisition a temp variable..
	
	my ($input, $temp) = ($self->{input}, '');

	## keep track of everything from the end of the last fully
	## available frame to the end of the buffer..

	$temp = substr($input->{buffer}, $self->{decoder}->{stream}->next_frame())
		if ($input->{buffer} ne '');

	## attempt to read from our input handle..
	
	if (sysread($input->{handle}, $input->{buffer}, 256000) == 0) {
	
		## the read returned 0,  so we are at end of
		## file,  generate an event to tell everyone,
		## and take appropriate action..
	
		$kernel->yield($self->{message_event}, {
			id   => 'INPUT_EOF_WARNING',
			data => $input->{filename}
		});
		
		$kernel->yield('__d_input_close');
		$kernel->yield('__d_decoder_reset');
	} else {
	
		## otherwise,  we still have more stream to go.
		## reform the buffer with the end fragment from the
		## old buffer,  and the newly read data..
	
		$input->{buffer} = $temp . $input->{buffer};
		
		## tell the stream object about our new buffer..
		
		$self->{decoder}->{stream}->buffer($input->{buffer});
		
		## and go back to work..
		
		$kernel->yield('__d_decoder_cycle');
	}
}

sub __d_input_close {
	my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];

	## shortcut a few variables..

	my $input = $self->{input};
	my $filename = $input->{filename};

	## leave unless there's something we could do..
	
	return undef unless ($input->{state} eq 'OPEN');

	## if we have a handle,  try to close it,  and warn users
	## if we can't..
	
	if (defined($input->{handle})) {
		CORE::close($input->{handle}) || $kernel->yield($self->{message_event}, {
			id   => 'INPUT_CLOSE_WARNING',
			data => 'failed to close file handle'
		});
	}
	
	## reset our internal state data..
	
	$input->{handle}   = undef;
	$input->{filename} = '';
	$input->{stats}    = [(0)x13];
	
	$input->{buffer}   = '';
	$input->{info}     = {};
	
	$input->{state}    = 'CLOSED';
	
	## and tell everyone about the new state..
	
	$kernel->yield($self->{message_event}, {
		id   => 'INPUT_CLOSE_SUCCESS',
		data => $filename
	});
	
	$kernel->yield($self->{message_event}, {
		id   => 'INPUT_STATUS_DATA',
		data => { state => 'CLOSED' }
	});
}

sub __d_decoder_reset {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
	my ($input, $output, $decoder) = @{$self}{qw(input output decoder)};

	## first step:  stop the decoder,  and let everyone know
	## that's what just happened..

	$decoder->{state} = 'STOPPED';
	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_STATUS_DATA',
		data => { state => 'STOPPED' }
	});

	## unless we have a file already open,  there's not much
	## more to a reset..
	
	return undef unless ($input->{state} eq 'OPEN');
	
	## otherwise,  we have all kinds of neat stuff to setup..
	## fix: mad_dither_s16_le is an assumption,  and a
	## non-portable one at that..  
	
	$decoder->{stream}   = new Audio::Mad::Stream(MAD_OPTION_IGNORECRC);
	$decoder->{frame}    = new Audio::Mad::Frame;
	$decoder->{synth}    = new Audio::Mad::Synth;
	$decoder->{dither}   = new Audio::Mad::Dither(MAD_DITHER_S16_LE);

	$decoder->{played}   = new Audio::Mad::Timer;
	$decoder->{printed}  = 0;
	$decoder->{progress} = 0;
	$decoder->{seeking}  = 0;
	
	## update everyones idea of our progress on this stream..

	$kernel->yield($self->{message_event}, {
		id   => 'DECODER_FRAME_DATA',
		data => { played => 0, progress => 0 }
	});

	$decoder->{frames}   = 0;
	
	## setup output if available..
	if ($output->{state} eq 'OPEN') {
	
		## reset the dsp device..
	
		dsp_reset($output->{handle});
		
		## turn stereo on or off depending on the 
		## number of channels in our input stream..
		
		if ($input->{info}->{s_mode} == 0) {
			set_stereo($output->{handle}, 0);
		} else {
			set_stereo($output->{handle}, 1);
		}
		
		## here we try to match the stream sampling rate to 
		## the dsp sampling rate..  
		
		if ($output->{samplerate} == $input->{info}->{s_samplerate}) {

			## resampling rates equal,  we need to do nothing..
			$decoder->{resample} = undef;

		} elsif (set_sps($output->{handle}, $input->{info}->{s_samplerate}) != $input->{info}->{s_samplerate}) {

			## couldn't set the soundcard rate,  so we need to
			## create ourselvs a Resample object..
			$decoder->{resample} = new Audio::Mad::Resample($input->{info}->{s_samplerate}, $output->{samplerate});

		} else {

			## succeded updating soundcard rate

			$output->{samplerate}  =
			$decoder->{samplerate} = $input->{info}->{s_samplerate};
			
			$decoder->{resample}   = undef;
		}
	} else {
		## the output device is not yet open,  so the least we can
		## do is to see if our sampling rates our equal,  and if not,
		## just create a resample object and use the default dsp
		## sampling rate..

		$decoder->{resample} = (
			$input->{info}->{s_samplerate} != $output->{samplerate}
			? new Audio::Mad::Resample($input->{info}->{s_samplerate}, $output->{samplerate})
			: undef
		);
	}
}

## here's where all the magic happens..  when I was first writing this
## module I spent a lot of time trying to figure out an efficient
## algorithm for calling this part of the state machine.  My thinking
## was that if I call this state once for each frame in a stream,  and
## this state makes a bunch of function calls (especially through XS 
## into Audio::Mad) that I would end up with HUGE overheads.  I tried
## everything I could to keep calls in here minimal,  including
## processing 3 or 5 frames per cycle,  instead of one.

## truth is,  I was wrong.  premature optimization,  I guess.  Every
## attempt I made at thinning calls to this state down,  I still
## ended up with huge amounts of CPU time being eaten.  So I gave in
## and went for the simplest solution:  just try to do one frame
## per cycle,  and see what happens.  Amazingly enough,  my CPU
## times settled right down,  the playback was smooth,  and I
## was only seeing about a 2%-5% CPU time gain over mpg321.

## my thinking goes along these lines..  my computer can easily
## decode more stream per second than my soundcard can play per
## second..  so the solution was to let blocking slow me down..
## We use a blocking write to the dsp below.  If the DSP is 
## empty,  we'll spin real fast here a few times and quickly
## fill up the buffer -- at that point,  we block for just a
## few milliseconds every frame,  enough to slow us down,  but
## not too much that it destroys interactivity.  CPU times 
## stay in check,  and we still have time left in the same
## process to accomplish other tasks..

## I have written a curses based GUI on top of this module,  and
## it runs smoothly and without unexpected delays.  Even holding
## down a key to scroll the song list,  I do not get skips or
## pops in my playback -- but the CPU utilization gets as high
## as 70%.  So,  the method may not be perfect,  but it's enough
## to make this a capable in-process mpeg decoder.

sub __d_decoder_cycle {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
	
	## shortcut..  lazy..  stuff..
	my $decoder = $self->{decoder};
	
	## start of our frame decoding bonanza..
	FRAME: {
		
		## we only engage in this loop for two reasons,  one:  we wish
		## to play sound from the stream,  or two:  we wish to seek to
		## a specific point in the stream..
		return undef unless ($decoder->{state} eq 'PLAYING' || $decoder->{seeking});
	
		## call mad_frame_decode(stream)..
		if ($decoder->{frame}->decode($decoder->{stream}) == -1) {
		
			## immediately goto next frame if we got an
			## error that was recoverable..
			
			redo FRAME if ($decoder->{stream}->err_ok());
			
			## shortcut the errorcode..
			
			my $error = $decoder->{stream}->error();

			## if we got an error because the buffer has
			## run try (BUFLEN) or the buffer hasn't been
			## set yet (BUFPTR)...			

			if ($error == MAD_ERROR_BUFLEN || $error == MAD_ERROR_BUFPTR) {
			
				## then call the input subsystem to
				## read some data from our stream..
			
				$kernel->yield('__d_input_read');
				
				## input_read will yield back to us to
				## resume playing if necessary..
				
				return undef;
			} else {
				
				## otherwise,  we had a strange fatal error,
				## do our best to say something about it..
			
				$kernel->yield($self->{message_event}, {
					id   => 'DECODER_FRAME_ERROR',
					data => "unkown error: $error"
				});
				
				## try to continue processing on the frame,
				## fix:  eventually we should keep an error
				## counter and error out after x consecutive
				## errors..
				
				redo FRAME;
			}
		}
		
		## keep track of some data,  increment the frame
		## count,  and our timer.
		
		$decoder->{frames}++;
		$decoder->{played}->add($decoder->{frame}->duration());

		## data is defined in case we have any new DECODER_FRAME_DATA
		## we need to report,  plus snatch the current time in miliseconds.

		my ($data, $ms) = ({}, $decoder->{played}->count(MAD_UNITS_MILLISECONDS));
		
		## if we haven't printed an update in the last half a second,  or if
		## we haven't printed anything at all yet..
		
		if ($ms - 500 > $decoder->{printed} || $decoder->{printed} == -1) {
		
			## then make a mark in our temporary data packet
			## about the current playtime in seconds.  as well 
			## as track the fact that we printed something
			## on this millisecond..
		
			$data->{played}     =
			int(($decoder->{printed} = $ms) / 1000);
		}
		
		## if we've played at least one second of the file -and-
		## the current progress number is greater than the old
		## one,  or we haven't printed progress yet..
		
		if (
		    $self->{input}->{info}->{s_seconds} && 
		    int(
		        (
		            $self->{options}->{decoder_progress_range} / 
		            ($self->{input}->{info}->{s_seconds} * 1000)
		        ) 
		        * $ms
		    ) 
		    > $decoder->{progress} || $decoder->{progress} == -1
		) {
		
			## then set the progress in both the data packet
			## and our internal state..
			
			## to get the progress number (releative to the
			## decoder_progress_range option):  divide the
			## progress_range by the number of milliseconds 
			## in the file,  then multiply the result by the
			## number of milliseconds currently played.
		
			$data->{progress}    = 
			$decoder->{progress} = int(
			    (
			        $self->{options}->{decoder_progress_range} / 
			        ($self->{input}->{info}->{s_seconds} * 1000)
			    ) * $ms
			);
		}
		
		## if any updated data was stashed in our temporary container,
		## make sure we generate an event and send that data out..
		
		$kernel->yield($self->{message_event}, {
			id   => 'DECODER_FRAME_DATA',
			data => $data
		}) if (scalar(keys(%{$data})) > 0);
		
		## equivalant to:  mad_synth_frame(frame);
		
		$decoder->{synth}->synth($decoder->{frame});
		
		## then we gather up the pcm audio for this
		## frame..  this requires us to run the samples
		## through Audio::Mad::Dither..  and potentially
		## Audio::Mad::Resample -- that's all automatically
		## handled right here..

		my $pcm = $decoder->{dither}->dither(
			defined($decoder->{resample}) 
			? $decoder->{resample}->resample($decoder->{synth}->samples())
			: $decoder->{synth}->samples()
		);
		
		## immediately do another frame if we currently in the
		## process of seeking.  once the seek counter hits
		## zero,  we will resume normal mode of operation..
		
		redo FRAME if ($decoder->{seeking} && $decoder->{seeking}--);

		## we did it!  write that pcm data out to the
		## dsp..

		syswrite($self->{output}->{handle}, $pcm);
	}
	
	## make sure we get called again..
	
	$kernel->yield('__d_decoder_cycle');
}

sub __d_output_open {
	my ($self, $kernel, $session, $cycle) = @_[OBJECT, KERNEL, SESSION, ARG0];
	my $output = $self->{output};

	## skip it if we are already open..
		
	return undef if ($output->{state} eq 'OPEN');
	
	my ($handle, $mixer);
	
	## try to open up the dsp device itself..
	
	CORE::open($handle, ">$output->{device}") || do {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_OPEN_FAILED',
			data => "failed to open $output->{device}: $!"
		});
		return undef;
	};
	
	## try to get a mixer device..  I think we can a bit more
	## gracefully if this dosen't work..
	
	CORE::open($mixer, "+<$output->{mixer_device}") || do {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_OPEN_FAILED',
			data => "failed to open $output->{mixer_device}: $!"
		});
	};
	
	## do the things necessary to setup a modern dsp
	## device..  generate events if anything dosen't
	## work as expected..
	
	dsp_reset($handle) || do {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_OPEN_FAILED',
			data => "failed to reset $output->{device}: $!"
		});
		return undef;
	};
	
	## fix:  we're still making x86 linux centric decisions here..  
	## this needs to be better configured.  perhaps just adding
	## in an output_? option to PCAM would do..
	
	set_fmt($handle, AFMT_S16_LE) || do {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_OPEN_FAILED',
			data => "failed to set format on $output->{device}: $!"
		});
		return undef;
	};
	
	## set the sample rate or whine about it..
	
	set_sps($handle, $output->{samplerate}) == $output->{samplerate} || do {
		$kernel->yield($self->{message_event}, {
			id   => 'DSP_OPEN_FAILED',
			data => "failed to set samplerate on $output->{device}: failed"
		});
		return undef;
	};
	
	## figure out if we want stereo or not..

	if ($self->{input}->{state} eq 'OPEN' && $self->{input}->{info}->{s_mode} == 0) {
		set_stereo($handle, 0);
	} else {
		set_stereo($handle, 1);
	}

	## update some internal information..
	
	$output->{handle} = $handle;	
	$output->{state}  = 'OPEN';

	$output->{mixer}         = $mixer;
	$output->{mixer_volume}  = mixer_read($mixer, SOUND_MIXER_VOLUME) & 0x000000ff;
	_mixer_update($output);
	
	## sing to the world about what we have done..
	
	$kernel->yield($self->{message_event}, {
		id   => 'DSP_OPEN_SUCCESS',
		data => $output->{device}
	});
	
	$kernel->yield($self->{message_event}, {
		id   => 'DSP_STATUS_DATA',
		data => { state => 'OPEN' }
	});
	
	$kernel->yield($self->{message_event}, {
		id   => 'DSP_MIXER_DATA',
		data => { 
			balance => $output->{mixer_balance},
			volume  => $output->{mixer_volume},
			pcm     => $output->{mixer_pcm}
		}
	});
}

sub __d_output_close {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
	my $output = $self->{output};

	## exit out if we have no reason to be here..
	
	return undef unless ($output->{state} eq 'OPEN');
	
	## attempt to close our dsp device,  or issue a 
	## warning telling people.  (shouldn't /dev/mixer)
	## be closed too?
	
	CORE::close($output->{handle}) || $kernel->yield($self->{message_event}, {
		id   => 'DSP_CLOSE_WARNING',
		data => "failed to close $output->{device}"
	});
	
	## update state..

	$output->{handle} = undef;
	$output->{state}  = 'CLOSED';
	
	## tell everyone..
	
	$kernel->yield($self->{message_event}, {
		id   => 'DSP_CLOSE_SUCCESS',
		data => $output->{device},
	});
	
	$kernel->yield($self->{message_event}, {
		id   => 'DSP_STATUS_DATA',
		data => { state => 'CLOSED' }
	});
}

##############################################################################

## cheap,  cheap utility method to prevent code duplication.. 
## and handle a little maths for us.

sub _mixer_update {
	my ($o) = @_;

	## exit out unless we have reason to work..
	return undef unless ($o->{state} eq 'OPEN');

	## there is no balance,  only left and right
	## volumes..  
	my ($vl, $vr) = ($o->{mixer_volume})x2;
	my ($pl, $pr) = ($o->{mixer_pcm})x2;
	
	## a little algorithm to smoothly scale the volumes
	## off as we adjust the balance.  the ear percives
	## volume changes logarithmically,  so that's why
	## we do this here..  not that I understand that,
	## I just read a perldoc and a webpage about the Nth
	## log of a number..  let me know if this is stupid,
	## but it works for me..
	my $b = 50 - $o->{mixer_balance};
	   if ($b < 0) { $vl = int($vl * (log(50 + $b + 1)/log(50))) }
	elsif ($b > 0) { $vr = int($vr * (log(50 - $b + 1)/log(50))) }	   
	
	## actually pump out our new volumes to the
	## mixer device..
	mixer_write($o->{mixer}, SOUND_MIXER_PCM,    $vl, $vr);
	mixer_write($o->{mixer}, SOUND_MIXER_VOLUME, $pl, $pr);	
}
	
##############################################################################
1;
__END__

=head1 NAME

POE::Wheel::Audio::Mad - POE Wheel implementing in-session non-blocking mpeg stream playing

=head1 SYNOPSIS

  use POE;
  use POE::Wheel::Audio::Mad;

  POE::Session->create(
  	inline_states => {
  		_start  => \&am_start,
  		message => \&am_message
  	}
  );
  
  sub am_start {
  	my ($kernel, $heap) = @_[KERNEL, HEAP];
  	
	## you may also specify decoder options,  listed below..
  	$heap->{wheel} = new POE::Wheel::Audio::Mad ( message_event => 'message' );
  	
  	$kernel->yield( 'decoder_open', { 
  		filename => '/path/to/some/stream.mp3', 
  		play     => 1 
  	});
  }
  
  sub am_message {
  	my ($kernel, $message) = @_[KERNEL, ARG0];
  	
  	if ($message->{id} eq 'INPUT_EOF_WARNING') {

  		print "finished..\n";

  		undef $heap->{wheel};
  		
  	} elsif ($message->{id} eq 'DECODER_FRAME_DATA') {

  		if (defined($message->{data}->{played})) {

	  		print "\rplayed: $message->{data}->{played}";

	  	}
  	}
  }
  
  $poe_kernel->run();
  exit();
  	
=head1 DESCRIPTION

  POE::Wheel::Audio::Mad is an attempt to bring a naitive perl mpeg
  decoder into a perl session.  This module was written to work as
  a POE Wheel due to it's nature -- it simply playes mpeg streams --
  you have to do the job of controlling the player and handling 
  updates.  This really isn't your traditional wheel.
  
=head1 OPTIONS

  These options may be specified as part of the call to the 
  new() constructor,  and affect decoder behaviour.  

=over

=item message_event

  *REQUIRED*  Specifies which event in your session will be 
  receiving event messages from the decoder.  See section
  MESSAGES below for more information on what this will
  mean.

=item output_close_on_pause

  If defined to a true value,  this will cause the decoder to
  physically close the output device when stream decoding is
  in the paused state.  This frees up the device for use by
  other applications.  Default:  false.
	
=item output_close_on_stop

  If defined to a true value,  this will cause the decoder to 
  physically close the output device when stream decoding is 
  in the stopped state.  Default: true.
  
=item output_device

  Specifies the complete path to the dsp device to open for
  playing decoded audio.  Default: '/dev/dsp'
  
=item output_samplerate

  Specifies the sampling rate to open the dsp device at.  If a
  stream is not at this sampling rate Audio::Mad::Resample will
  be used to up/down-sample the stream to match.  Any standard
  sampling rate can be used.
  
=item mixer_device

  Specifies the complete path to the mixer device to open for
  manipulating sound levels.  Default: '/dev/mixer'
  
=item mixer_balance

  Specifies the balance to set the mixer to once opened.  Any
  value between 0 (full left) and 100 (full right) may be
  used.  Default: 50 (center)
  
=item mixer_volume

  Specifies the master volume to set the mixer to once opened.
  Any value between 0 (mute) and 100 (full volume) may be
  used.  Default: 50

=item mixer_pcm

  Specifies the pcm volume to set the mixer to once opened.
  Any value between 0 (mute) and 100 (full volume) may be
  used.  Default: 60

=item decoder_progress_range

  Specifies the denominator to use when returning the stream
  progress index.  The duration in seconds is divided by this
  number to determine playing unit size,  as each "unit" is
  passed a progress message is generated indicating how many
  units have been played.

=item decoder_play_on_open

  If defined to a true value,  this will cause the decoder to
  immediatly begin playing a stream once an 'open' command
  has been issued for it.
  
=back

=head1 STATES

  POE::Wheel::Audio::Mad brings with it a large amount of
  states that get defined in your session.  Most of these
  states are used for controlling the decoder behaviour
  or for querying information,  and they are listed below.
  All of these states take a single hashref as their
  argument,  the keys and expected values (if any) are 
  listed as well.

=over

=item decoder_shutdown

  When called,  this state will halt all current decoding activities,
  clean up it's internal state, release resources,  and send a 
  message indicating the shutdown was successful.
  
=item decoder_open

  Opens a stream,  scans it for validity and information,  then prepares
  the decoder to begin playing.  Possible keys are:
  
=over

=item stream
  
  string containing the full pathname to the stream to be opened.
  required.
  
=item play

  boolean indicating wether the decoder should begin playing the
  stream as soon as it's opened.  default:  [decoder_play_on_open]

=back
  
=item decoder_play

  Starts or resumes playing of the currently opened stream.
  
=item decoder_pause

  Pauses playing on the current stream.  Decoding is halted,  the
  input file remains open,  and the current file position is
  preserved.
  
=item decoder_stop

  Stops playing on the current stream.  Decoding is halted,  the
  input file remains open,  but the current file position is 
  set to the beginning of the stream.
  
=item decoder_seek

  Seeks to a new position in the stream,  and resumes playing
  at the new position.  The keys used are:
  
=over

=item position

  integer specifying the relative position to seek to.
  required.
  
=item range

  integer indiciating the denominator to use when determining
  relative file offsets.  default:  the current value of the
  decoder option 'decoder_progress_range', see OPTIONS.

=back
  
  For example:
  
  to seek 25% past the beginning (if the stream is 500 seconds 
  long,  this would start playing at 125 seconds):
  
  $kernel->yield('decoder_seek', { position => 25, range => 100 });
  
  to seek to a specific second,  use the desired second as
  the position,  and the number of seconds in the stream
  as the range:
  
  $kernel->yield('decoder_seek', { position => 125, range => 500 });
  
=item decoder_set

  Updates decoder options (above) and manipulates mixer values.
  The following keys are all required to be present: 

=over

=item type

  string indicating which subsystem you wish to manipulate.
  currently this is either 'option' for changing decoder
  options,  or 'pcm' for manipulating the mixer.
  
=item key

  string indicating the key,  or the name of the option
  that you wish to set.  If you are changing decoder
  options,  this is just the name of the option as listed
  above.  If you are manipulating the mixer,  possible
  values are:  'volume', 'pcm', or 'balance'.

=item value

  value you wish to be assigned to the specified 
  subsystem and key.
  
=back
  
  For example:
  
  to alter a decoder option,  such as deactivating decoder_play_on_open:
  
  $kernel->yield('decoder_set', { type => 'option', key => 'decoder_play_on_open', value => 0 });
  
  to change the mixer volume,  such as setting the pcm volume to 75:
  
  $kernel->yield('decoder_set', { type => 'mixer', key => 'pcm', value => 75 });
  
=item decoder_info

  Causes the decoder to output information about one of it's subsystems.
  You must specify a single key:
  
=over

=item type

  The name of a subsystem you would like to coherce into reporting
  state information.  You may select one of:  'decoder',  'input',
  or 'dsp'.  See section MESSAGES for help in parsing state
  information.
  
=back

=back

=head1 MESSAGES

  This wheel will send messages back to your session via the state
  you specified in the option 'message_event'.  This state will 
  be passed decoder messages,  one at a time,  in hashref format.
  
  This hashref always has only two keys:  id,  and data.  'id' is
  the identifier for the message.  Every message id used by the
  decoder is listed below.  data is the payload corresponding to
  this type of event.  It could possibly be of any type or value,
  or possibly blank,  but it will always be defined.
  
=over

=item DECODER_SHUTDOWN_SUCCESS

  Emitted when a shutdown has been specifically asked for,  usually
  by yielding to 'decoder_shutdown'.  After all files have been
  closed,  the output device shutdown,  and resources freed this
  state will be emitted to let users know the wheel is ready to
  be destroyed.

=item DECODER_PLAY_FAILED

  Emitted when the decoder is asked to play,  but no input file is
  open.  

=item DECODER_PAUSE_FAILED

  Emitted when the decoder is asked to pause,  but the decoder is
  not currently playing.

=item DECODER_STOP_FAILED

  Emitted when the decoder is asked to stop,  but the decoder is
  not currently playing,  or currently has an input file open.

=item DECODER_STATUS_DATA

  Emitted when the decoder changes state.  The data packet is
  a hashref containing information about the new state.  
  
=over

=item state

  Currently the only key defined in the data packet,  it a 
  textual description of the current decoder state. Possible 
  values are:  'CLOSED', 'STOPPED', 'PLAYING', 'PAUSED'.
  
=back

=item DECODER_FRAME_DATA

  Emitted periodically while the decoder is processing a stream.
  The data packet is a hashref which could contain one of the
  following keys:
  
=over

=item played

  an integer indicating the number of seconds that have been 
  played in the stream.  this gets printed every 500ms for
  better accuracy,  as such,  the value may not change each
  time it is printed.
  
=item progress

  an integer indicating relative position within the stream.
  the option 'decoder_progress_range' is used as a denominator
  and applied to the length (in bytes) of the stream.
  
=back

=item DECODER_FRAME_ERROR

  Emitted when the decoder crosses an unrecoverable error 
  while processing frames in the stream.  the data packet
  contains a string with a short message about the error.

=item INPUT_OPEN_FAILED

  Emitted when the decoder has been asked to open a file,
  but couldn't find the file or locate a valid mepg stream
  within the file.  the data packet contains a string with
  a short message about the error.

=item INPUT_CLOSE_SUCCESS

  Emitted when the decoder has successfully shutdown an 
  input stream,  and is ready to open a new input 
  stream.  the data packet contains a string with the
  name of the file that was closed.

=item INPUT_STATUS_DATA

  Emitted when the decoders input subsystem has changed 
  state.  The data packet is a hashref,  and could contain
  any of the following keys:
  
=over

=item state

  a string containing a description of the input systems new
  state.  possible values are:  'OPEN' or 'CLOSED'.
  
=item filename

  a string containing the name of the file the input system
  has just changed state on.  If state was 'OPEN',  this file
  was just opened,  if 'CLOSED',  this file was just closed.

=back

=item INPUT_INFO_DATA

  Emitted when new information about an input stream has just
  become available.  Usually immediately after the stream has 
  been opened.  the data packet is a hasref,  and could contain
  any of the following:
  
=over

=item s_frames

  The number of frames calculated to be in this stream.

=item s_vbr

  Boolean indicating wether the stream is variable or
  constant bitrate.  false=CBR, true=VBR.

=item s_size

  The number of bytes calculated to be in the stream.

=item s_duration

  The duration of the stream in HH:MM:SS.DDD format.

=item s_bitrate

  The calculated bitrate of this stream,  as an integer.

=item s_avgrate

  The mean bitrate of this stream,  as an integer.
  
=item s_samplerate

  The sampling rate of this stream.
  
=item s_mode

  The stereo mode of this stream.

=item s_layer

  The layer of this stream.

=item s_flags

  The frame flags for this stream.

=item s_frame_duration

  The duration of each individual frame in this stream.

=item xing_frames

  The number of frames in this stream,  according to the Xing header.

=item xing_bytes

  The number of bytes in this stream,  according to the Xing header.

=back
  
=item INPUT_EOF_WARNING

  Emitted when the decoder has come across an end-of-file contidition
  on the input stream file.  the data packet is a string,  and contains
  the name of the input stream file.

=item INPUT_CLOSE_WARNING

  Emitted when the decoder has failed to call a close(2) on the input
  stream filehandle.  

=item DSP_OPEN_SUCCESS

  Emitted when the decoder has acquired the output device.  the data
  packet is a string containing the path name of the device that has
  been opened.

=item DSP_OPEN_FAILED

  Emitted when the decoder has failed to acquire an output device.  It
  either failed to open the device,  or set it's paramaters.  the data
  packet is a string describing the error.

=item DSP_STATUS_DATA

  Emitted when the output device has changed state.  the data packet
  is a hashref containing information about the new state.
  
=over

=item state

  Currently the only defined key in the data packet,  it contains a 
  textual description of the output subsystems state.  Possible
  values are:  'CLOSED', 'OPEN'.
  
=back

=back

=head1 SEE ALSO

perl(1)

POE::Component::Audio::Mad::Dispatch(3)
POE::Component::Audio::Mad::Handle(3)

Audio::Mad(3)
Audio::OSS(3)

=head1 AUTHOR

Mark McConnell, E<lt>mischke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark McConnell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself with the exception that you
must also feel bad if you don't email me with your opinions of
this module.

=cut
