package POE::Component::Player::Musicus;

use warnings;
use strict;

use POE;
use POE::Component::Child 1.39;
use Text::Balanced qw(extract_quotelike);
our @ISA = 'POE::Component::Child';

our $VERSION = '1.32';

# POE does this for its stuff and gets higher resolution if you have Time::HiRes and regular resolution if you don't.  time needs to be used within this package, so I did the same here so it could be locally imported
BEGIN {
	eval {
		require Time::HiRes;
		Time::HiRes->import('time');
	}
}

sub new {
	my $class = shift;

	my %params = (
		# Options
		path	=> '/usr/lib/xmms/',
		output	=> 'libOSS.so',
		musicus	=> 'musicus',
		alias	=> 'main',
		delay	=> 0,

		# Events
		error		=> 'error',
		musicuserror	=> 'musicuserror',
		done		=> 'done',
		died		=> 'died',
		quit		=> 'quit',
		version		=> 'version',
		setvol		=> 'setvol',
		getvol		=> 'getvol',
		play		=> 'play',
		stop		=> 'stop',
		pause		=> 'pause',
		unpause		=> 'unpause',
		getpos		=> 'getpos',
		setpos		=> 'setpos',
		getlength	=> 'getlength',
		getinfocurr	=> 'getinfocurr',
		getinfo		=> 'getinfo',
		ready		=> 'ready',
		@_,
	);

	my @events = ();

	# Define the stdout sub here so it doesn't look like a method that can be used by other modules
	my $stdout = sub {
		my ($self, $args) = @_;
		local $_ = $args->{out};

		print STDERR "PoCo::Player::Musicus got input: [$_]\n" if $self->{debug};

		my $unknown = 0;

		if (/^\@ OK getpos (.+?)\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{getpos}, $1);
		} elsif (/^\@ OK quit\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{quit});
		} elsif (/^\@ OK version (.+?)\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{version}, $1);
		} elsif (/^\@ OK setvol\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{setvol});
		} elsif (/^\@ OK getvol (.+?) (.+?)\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{getvol}, $1, $2);
		} elsif (/^\@ OK play "(.+?)"\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{play}, $1);
		} elsif (/^\@ OK stop\s*$/ ) {
			POE::Kernel->post($self->{alias}, $self->{stop});
		} elsif (/^\@ OK pause\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{pause});
		} elsif (/^\@ OK unpause\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{unpause});
		} elsif (/^\@ OK setpos (.+?)\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{setpos}, $1);
		} elsif (/^\@ OK getlength (.+?)\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{getlength}, $1);
		} elsif (/^# Entering interactive mode\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{ready});
		} elsif (my ($command, $songinfo) = /^\@ OK (getinfocurr|getinfo) (.*)/) {
			my ($file, $songinfo) = (extract_quotelike($songinfo))[5,1];
			$file =~ s#\\"#"#g; # Musicus only escapes double quotes
			($songinfo) = (extract_quotelike($songinfo))[5];
			$songinfo =~ s#\\"#"#g; #  Musicus only escapes double quotes
			my ($length, $title) = $songinfo =~ /^(\d+)( .*)$/;
			my %info = (
				file	=> $file,
				length	=> $length,
			);
			
			if(my %tags = $title =~ / \x1e(\w)=([^\x1e]*?)(?= \x1e|\t)/g) {
				%info = (
					%info,
					artist	=> $tags{p},
					title	=> $tags{t},
					album	=> $tags{a},
					track	=> $tags{n},
					year	=> $tags{y},
					date	=> $tags{d},
					genre	=> $tags{g},
					comment	=> $tags{c},
				);
			} else {
				$title =~ s/^ //; # We capture the space because it's part of the record seperator if we do get a title string.  If we don't then there's a space tacked on to the beginning of the title, so it must be removed.

				if($title eq '0 @') { # No song info returned by plugin, this string is hard coded into Musicus for this case
					$title = '';
				}

				# Go ahead and fill out the hash
				%info = (
					%info,
					artist	=> '',
					title	=> $title,
					album	=> '',
					track	=> '',
					year	=> '',
					date	=> '',
					genre	=> '',
					comment	=> '',
				);
			}

			POE::Kernel->post($self->{alias}, $self->{$command}, \%info);
		} elsif (/^\@ ERROR (.*?)\s*"(.*?)"\s*$/) {
			POE::Kernel->post($self->{alias}, $self->{error}, $self, { err => -1, error => $2, syscall => $1 });
		} else {
			$unknown = 1;
			print STDERR "Received unknown input: $_\n" if $self->{debug};
		}
		$self->_queue_response unless $unknown;
	};

	my $self = $class->SUPER::new(
		events		=> { stdout => $stdout, @events },
		debug		=> $params{debug},
	);
	
	%$self = (
		%$self,
		%params,
		outstanding_request	=> 0,
		last_request_time	=> 0,
		queue			=> [],
	); # Add my stuff to the hash that gets passed around

	$self->start;

	return $self;
}

sub start {
	my $self = shift;

	$self->{queue} = []; # Set it here again in case we're restarting
	$self->{outstanding_request} = 0;
	$self->{last_request_time} = 0;
	$self->run($self->{musicus}, '-path', $self->{path}, '-output', $self->{output});
}

sub _start {
	my $self = shift;
	my @args = @_;

	$poe_kernel->state('_queue_check', $self);
	$self->{session} = $poe_kernel->get_active_session;

	$self->SUPER::_start(@args);
}

sub play {
	my ($self, $file) = @_;
	$file =~ s/"/\\"/g; # Escape quotes for Musicus
	$self->_queue_write("play \"$file\"");
}

sub getinfo {
	my ($self, $file) = @_;
	$file =~ s/"/\\"/g; # Escape quotes for Musicus
	$self->_queue_write("getinfo \"$file\"");
}

sub setvol {
	my ($self, $left, $right) = @_;
	$self->_queue_write("setvol $left $right");
}

sub setpos {
	my ($self, $pos) = @_;
	$self->_queue_write("setpos $pos");
}

sub xcmd {
	my ($self, $cmd) = @_;
	return -1 unless $cmd;
	$self->_queue_write($cmd);
}

sub quit {
	my $self = shift;
	$self->_queue_write('quit');
}

sub version {
	my $self = shift;
	$self->_queue_write('version');
}

sub getvol {
	my $self = shift;
	$self->_queue_write('getvol');
}

sub stop {
	my $self = shift;
	$self->_queue_write('stop');
}

sub pause {
	my $self = shift;
	$self->_queue_write('pause');
}

sub unpause {
	my $self = shift;
	$self->_queue_write('unpause');
}

sub getpos {
	my $self = shift;
	$self->_queue_write('getpos');
}

sub getlength {
	my $self = shift;
	$self->_queue_write('getlength');
}

sub getinfocurr {
	my $self = shift;
	$self->_queue_write('getinfocurr');
}

# Musicus only allows one request to be processed at a time.  There is the possibility of multiple requests being sent before a response is generated if they are sent fast enough.  The workaround I use is to create a queue and a flag that shows an outstanding request.  Every time a command is sent, the flag is set to positive and no more commands will be sent until a result is obtained, which sets the flag to 0.

sub _queue_write {
	my ($self, $cmd) = @_;
	print STDERR "Queued command [$cmd]\n" if $self->{debug};
	push @{$self->{queue}}, $cmd;
	$poe_kernel->post($self->{session}, '_queue_check');
}

sub _queue_check {
	my $self = shift;

	if(!$self->{outstanding_request} && @{$self->{queue}}) {
		# The delay parameter is defined in microseconds, but all the POE time stuff takes seconds, so we convert
		my $delay_seconds = $self->{delay} / 1000000;
		if($self->{last_request_time} > 0 && (time - $self->{last_request_time}) < $delay_seconds) {
			print STDERR "Not enough time since last request, need to wait " . (time - $self->{last_request_time}) . " seconds to unqueue\n" if $self->{debug};
			$poe_kernel->alarm('_queue_check', $self->{last_request_time} + $delay_seconds);
		} else {
			print STDERR "Unqueued command [$self->{queue}[0]]\n" if $self->{debug};
			$self->write(shift @{$self->{queue}});
			$self->{outstanding_request} = 1;
			$self->{last_request_time} = time;
		}
	}
}

sub _queue_response {
	my $self = shift;
	$self->{outstanding_request} = 0;
	$poe_kernel->post($self->{session}, '_queue_check');
}

1;

__END__

=head1 NAME

POE::Component::Player::Musicus - a POE wrapper for the B<musicus> audio player

=head1 SYNOPSIS

	use POE qw(Component::Player::Musicus);

	$musicus = POE::Component::Player::Musicus->new();
	$musicus->play("test.mp3");

	POE::Kernel->run();

=head1 DESCRIPTION

This POE component is used to manipulate the B<musicus> player from within a POE application.

=head1 REQUIREMENTS

=over

=item * L<POE>

=item * L<POE::Component::Child> (1.39 or later)

=item * L<Text::Balanced>

=item * B<musicus> (1.11 or later required) - L<http://muth.org/Robert/Musicus/>

=back

=head1 METHODS

An object oriented interface is provided as follows: 

=head2 new %hash

Used to initialise the system and create a module instance.  The optional hash may contain any of the following keys:

=over 

=item alias

Indicates the name of a session to which events will be posted.  Default: I<main>.

=item path

Path to your XMMS plugins.  Default: F</usr/lib/xmms>.

=item output

Output plugin.  Default: F<libOSS.so>.

=item musicus

Location of musicus executable.  Default: F<musicus>.

=item delay

Some plugins can get confused if you send multiple getpos and setpos commands in quick succession (libmpg123 is the only one I've found so far) and musicus will lock up.  This option will ensure a minumum delay of any number of microseconds between commands.  It defaults to no delay.  This uses POE's timed event interface, which means you will have higher precision in your delays if you have L<Time::HiRes> installed, but it will work without it.  In my personal experience, 100000 has been a safe number for a delay, but this is likely to change from machine to machine.

=item <event-name>

Any event fired by this module can be mapped to a name of choice.  This is useful for differentiating this component's events from some other component's e.g. C<< done => "musicus_done" >> will cause the component to fire a I<musicus_done> event at the main session, instead of the usual I<done>.  For a comprehensive listing of events fired, please refer to the L</EVENTS> section below.

=back

=head2 start

This method starts the player.  While it should not be necessary to ever call this method directly since the C<new()> method calls it automatically, this method allows for restarting the player.

=head2 play <path>

This method requires a single parameter specifying the full path name of an audio file to play.

=head2 quit stop pause unpause

None of these methods take any parameters and will do exactly as their name implies.

=head2 getpos

Tells Musicus to send back the current position.  Will cause a L</getpos> event to fire.

=head2 getinfocurr

Tells Musicus to send back the current song information.  Will cause a L</getinfocurr> event to fire.

=head2 getinfo <file>

Tells Musicus to send back information about the file specified.  Will cause a L</getinfo> event to fire.

=head2 getlength

Tells Musicus to send back the length of the current file.  Will cause a L</getlength> event to fire.

=head2 getvol

Tells Musicus to send back the current volume.  Will cause a L</getvol> event to fire.

=head2 version

Tells Musicus to send back its version string.  Will cause a L</version> event to fire.

=head2 setvol <integer> <integer>

Causes Musicus to set the left and right channel volume to the numbers specified.  Will cause a L</setvol> event to fire.

=head2 setpos <integer>

Causes Musicus to jump to the specified location in the file.

=head2 xcmd <string>

This method allows for the sending of arbitrary commands to the player in the unlikely case that this component doesn't support something you want to do.

=head1 EVENTS

Events are fired at the session as configured in the L<new|/"new %hash"> method by I<alias>.  The names of the event handlers may be changed from their defaults by using they name of the event listed below as they key and the name of the event you want it to be called as the value in the L<new|/"new %hash">.

=head2 ready

Fired when the player has successfully started.  You do not need to wait for this event to start sending commands.

=head2 done / died

Fired upon termination or abnormal ending of the player.  This event is inherited from L<POE::Component::Child>, see those docs for more details.

=head2 error

Fired upon encountering an error.  This includes not only errors generated during execution of the player but also generated by the player itself in an interactive basis i.e. any C<@ ERROR> lines generated on stderr by the process.  For parameter reference please see L<POE::Component::Child> documentation, with the following caveat: for C<@ ERROR> type errors, I<err> is set to -1, I<syscall> is set to the command type that failed, and I<error> contains the player error string.

=head2 stop pause unpause

These events are fired whenever any of the named actions occur.

=head2 quit

This event is fired when the player has received the quit command and is about to exit.

=head2 version

Fired after the L</version> method is called, first argument is the Musicus version string.

=head2 setvol

Fired after a successful L</setvol> call.

=head2 play

Fired after a song has been loaded, first argument is the input plugin that will be used to play it.  Note that Musicus doesn't check to make sure it can actually play the file before returning this, it would probably be best to call L</getpos> after you get this event to make sure that the song really started playing.

=head2 getpos

Fired after a successful L</getpos> call, first argument is the position in the file.  XMMS plugins are expected to return either the position if the song is still playing, -1 if it has stopped, or -2 if there was an output failure such as not being able to open the output device.

=head2 getinfocurr

Fired after a successful L</getinfocurr> call, first argument is a hashref with the following keys: I<file>, I<length>, I<artist>, I<title>, I<album>, I<track>, I<year>, I<date>, I<genre>, and I<comment>.  The I<file> value is the same as the argument that was supplied to L</play>.

=head2 getinfo

Fired after a successful L</getinfo> call.  The format is the same as L</getinfocurr>.  The I<file> value is the same as the argument supplied to the L</getinfo> method.

=head2 setpos

Fired after a successful L</setpos>, first argument is the position playback has been set to.

=head2 getlength

Fired after a successful L</getlength>, first argument is the length of the audio file. 

=head1 AUTHOR

Curtis "Mr_Person" Hawthorne <mrperson@cpan.org>

=head1 BUGS

=over

=item * If the XMMS MAD plugin is used, Musicus may mysteriously die on the L</getinfocurr> command.  I have no idea why this happens and help would be appreciated.

=back

=head1 ACKNOWLEDGEMENTS

This component was based on L<POE::Component::Player::Mpg123> by Erick Calder, which is distributed under the MIT License.

Development would not have been possible without the generous help of Robert Muth, creator of Musicus (L<http://www.muth.org/Robert/>).

Some ideas for the getinfo/getinfocurr processing were taken from a patch submitted by Mike Schilli (L<http://www.perlmeister.com>).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004-2006 Curtis "Mr_Person" Hawthorne. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see L<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.

