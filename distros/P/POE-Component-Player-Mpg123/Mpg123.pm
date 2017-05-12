#
#	POE wrapper for the mpg123 player
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

package POE::Component::Player::Mpg123;

# --- external modules --------------------------------------------------------

use warnings;
use strict;
use Carp;

use POE;
use POE::Component::Child;

# --- module variables --------------------------------------------------------

use vars qw($VERSION);
$VERSION = substr q$Revision: 1.2 $, 10;

@POE::Component::Player::Mpg123::ISA = ("POE::Component::Child");
my @status = qw/stopped paused resumed ended/;

# --- module interface --------------------------------------------------------

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(
		quit => "QUIT",
		callbacks => { stdout => \&stdout },
		debug => $_->{debug},
		);

	%$self = (%$self, @_);
	$self->{dev} ||= "/dev/dsp";
	$self->{xargs} ||= [];
	$self->{nice} ||= 0;

	#	events the component emits

	$self->{alive} ||= "alive";
	$self->{status} ||= "status";
	$self->{info} ||= "info";
	$self->{stopped} ||= "stopped";
	$self->{paused} ||= "paused";
	$self->{resumed} ||= "resumed";
	$self->{ended} ||= "ended";
	$self->{error} ||= "error";
	# these two are passed through to PoCo::Child if specified
	$self->{callbacks}{done} = $self->{done} if $self->{done};
	$self->{callbacks}{died} = $self->{died} if $self->{died};

	#	fire off the player (only one allowed at a time)

	$self->start();

	return $self;
	}

sub start {
	my $self = shift;
	my ($nice, $debug, @dev, @xargs) = ("") x 2;

	$nice = "--aggressive" unless $self->{nice};
	$debug = "-v" if $self->{debug};
	@dev = ("-a", $self->{dev});
	@xargs = @{ $self->{xargs} };
	
	$self->run("mpg123", "-R", $nice, $debug, @dev, @xargs, "-");
	}

sub play {
	my ($self, $f) = @_;
	$self->write("LOAD $f");
	}

sub stop {
	my ($self) = @_;
	$self->write("STOP");
	}

sub pause {
	my ($self) = @_;
	$self->write("PAUSE");
	}

sub resume {
	my ($self) = @_;
	$self->write("PAUSE");
	}

sub stat {
	my ($self) = @_;
	$self->write("STAT");
	}

sub vol {
	my ($self, $vol) = @_;
	$vol ||= 0;
	return unless $vol =~ /^\d+$/;
    $self->write("VOL $vol");   
	}

sub seek {
	my $self = shift;
	my ($abs, $n, $p) = shift =~ /([+-])(\d+)([%])/;
	
	my ($i, $fl) = @{ $self->{_status} };		# frames played, left
	my $ft = $i + $fl;							# total frames

	my $f = $p ? $n/100 * $ft : $n;				# calculated frames
	$i += $f if $abs eq "+";					# relative, increment
	$i -= $f if $abs eq "-";					# relative, decrement
	$i = $f  if $abs eq "";						# absolute, assign

	$self->write("JUMP $i");
	}

sub xcmd {
	my ($self, $cmd) = @_;
	return unless $cmd;
	$self->write($cmd);
	}

# --- callback handlers -------------------------------------------------------

sub stdout {
	my ($self, $args) = @_;
	local $_ = $args->{out};

	#	this is progress information.  put at the front
	#	since we get an abundance of them

	if (/^\@F (.*?)\s*$/) {
		# frames (played, left); seconds (played, left)
		my @status = split /\s+/, $1;
		$self->{_status_} = \@status;
		POE::Kernel->post($self->{alias}, $self->{status} => @status);
		return;
		}

	#	mpg123 happy

	if (/^\@R (.*?)\s*$/) {
		POE::Kernel->post($self->{alias}, $self->{alive} => $1);
		return;
		}

	#	unhappy

	elsif (/^\@E (.*?)\s*$/) {
		POE::Kernel->post($self->{alias},
			$self->{error} => $self, { err => -1, error => $1 }
			);
		return;
		}

	#	id3 tag

	elsif (/^\@I ID3:(.+?)\s*$/) {
		my @keys = qw/track artist album year comment genre/;
		my @vals = strfix(unpack('A30 A30 A30 A4 A30 A*', $1));

		POE::Kernel->post($self->{alias},
			$self->{info} => { type => 'id3', aa2h(@keys, @vals) }
			);
		return;
	}

	#	no id3 tag

	elsif (/^\@I (.*?)\s*$/) {
		POE::Kernel->post($self->{alias},
			$self->{info} => { type => 'filename', filename => strfix($1) }
			);
		return;
		}

	#	stream info

	if (/^\@S (.*?)\s*$/ ) {
		my @keys = qw/
			mpegtype layer samplerate mode mode_extension
			framesz channels copyrighted crc emphasis bitrate extension
			/;
		POE::Kernel->post($self->{alias}, $self->{info} => {
			type => 'stream',
			aa2h(@keys, split(/\s+/, $1, @keys))
			});
		return;
		}

	#	Play status!
	elsif (/^\@P (\d+)\s*$/) {
		POE::Kernel->post($self->{alias}, $self->{$status[$1]});
		return;
		}
	}

# --- utility functions -------------------------------------------------------

# trim()s and returns a list of strings of special chars and whitespace

sub strfix {
    s/^[\x00-\x1F\s]*//, s/[\x00-\x1F\s]*$// for @_;
	@_;
	}

#	array-array to hash.  converts two lists of equal length into
#	a single hash wherein the keys are the contents of the first
#	list and the values the contents of the second

sub aa2h {
	my %ret;
	for (my $i = 0; $i < @_ / 2; $i++) {
		$ret{$_[$i]} = $_[$i + @_ / 2];
		}
	%ret;
	}

1; # :)

__END__

=head1 NAME

POE::Component::Player::Mpg123 - a wrapper for the C<mpg123> player

=head1 SYNOPSIS

	use POE qw(Component::Player::Mpg123);

	$mp = POE::Component::Player::Mpg123->new();
	$mp->play("/tmp/test.mp3");

	POE::Kernel->run();

=head1 DESCRIPTION

This component is used to manipulate the C<mpg123> player from within a POE application.  The less common but open-source C<mpg321> has also been tested.

=head1 METHODS

An object oriented interface is provided as follows: 

=head2 new [hash[-ref]]

Used to initialise the system and create a module instance.  The optional hash (or hash reference) may contain any of the following keys:

=item alias

Indicates the name of a session to which events will be posted.  Default: C<main>.

=item dev

Specifies device to play to.  Default: F</dev/dsp>.

=item xargs

Allows for passing extra arguments to the underlying application.

=item <event-name>

Any event fired by this module can be mapped to a name of choice.  This is useful for differentiating this component's events from some other component's e.g. I<done => "mpg123_done"> will cause the component to fire an C<mpg123_done> event at the main session, instead of the usual C<done>.  For a comprehensive listing of events fired, please refer to the C<EVENTS> section below.

=head2 start

This method starts the player.  While it should not be necessary to ever call this method directly since the I<new()> method calls it automatically, this method allows for restarting the player in such instances as when it dies.

=head2 play <path>

This method requires a single parameter specifying the full path name of an mp3 file to play.

=head2 stop pause resume

None of these methods take any parameters and will do exactly as thier name implies.  Please note that pause/resume are semaphored i.e. issuing a C<pause> whilst the system is already paused will do exactly diddley :)

=head2 vol <integer>

This method requires a valid integer between 0 and 100 to indicate the volume level.  Please note that volume support is not available on all versions of the C<mpg123> player.  Consult your version's documentation to verify whether this will work.

=head2 seek <to>

This method fast-forwards or rewinds or jumps the metaphoric playhead to a specified location.  The I<to> argument passed should adhere to the regex I<[+-]\d+[%]>.  If the number provided is preceeded by a C<+> or a C<-> then the number is treated as a relative offset where positive indicates forwards and negative backwards.  If no sign is passed, the number is treated as an absolute offset.  Additionally, if the number is followed by a percent sign, it is treated as a percentage and should be between 0 and 100, else it is treated as a frame number.

Please note that passing out-of-bounds values will not generate an error but will be silently adjusted as necessary.

=head2 stat

This method has been kept from sungo's original package... though I don't know what it's supposed to do.  In my version of C<mpg123> it generates an error C<@E Unknown command 'STAT'>.

=head2 xcmd <string>

This method allows for the sending of arbitrary commands to the player e.g. C<equalize> such that as the underlying player offers new features, these can be utilised without having to modify the component.

=head2 quit

This method causes the mp3 player to shut down.

=head1 EVENTS

Events are fired at the session indicated in the I<new()> method as C<alias>.  The names of the event handlers may be specified by setting the required values, using the keys listed below, via the aforementioned method.

=head2 alive

This event is fired by the player's notification that it's ready for business.  The only argument passed to the event (ARG0) contains the version string of the player.  Please note that the this component's caller need not wait for this notification to issue commands and is free to ignore the event.

=head2 status

Fired during processing.  Four paramters are passed to this event: 1) the number of frames that have been played, 2) the number that remain, 3) the number of seconds that have been played, and 4) the number of seconds left to play.

=head2 info

This event is fired to provide three types of information.  The only argument passed (ARG0) contains a hash reference containing the key C<type> which may be one of the following:

=item id3

If the track being played contains id v3 information, it is provided with this type.  Other keys in the hashref then include the following: I<artist, album, track, year, comment, genre>.

=item filename

When there is no id3 information available this type is issued in which case the single other key in the hash is I<filename> which contains the full path name of the file.

=item stream

This event type contains stream information.  The following keys are available in the hash: I<mpegtype, layer, samplerate, mode, mode_extension, framesz, channels, copyrighted, crc, emphasis, bitrate, extension>.

=head2 done / died

Fired upon termination or abnormal ending of the player.

=head2 error

Fired upon encountering an error.  This includes not only errors generated during execution of the player but also generated by the player itself in an interactive basis i.e. any @E lines generated on stderr by the process.  For parameter reference please see PoCo::Child documentation, with the following caveat: for @E-type errors, I<err> is set to -1 and I<error> contains the player error string.

=head2 stopped paused resumed ended

These events are fired whenever any of the named actions occur.  The C<ended> events signifies that a track has finished playing.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 ACKNOWLEDGEMENTS

This component is a complete rewrite of the older PoCo::MPG123 written by Matt Cashner a.k.a. "sungo" <eek+poe@eekeek.org> and Rocco Caputo a.k.a. "dngor" <troc@netrus.net>.  The inspiration was to reimplement that fuctionality in a more standardised manner by using the PoCo::Child.  My gratitude to both for helping make this possible.

=head1 AVAILABILITY

This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 DATE

$Date: 2002/09/29 02:15:57 $

=head1 VERSION

$Revision: 1.2 $

=head1 TODO

Can't think of anything yet but feel free to suggest something :)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.

