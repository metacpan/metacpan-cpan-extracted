#
#	mp3 encoding POE component
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

package POE::Component::Enc::Mp3;

# --- external modules --------------------------------------------------------

use warnings;
use strict;
use Carp;

use POE qw(Wheel::Run Filter::Line Driver::SysRW);

# --- module variables --------------------------------------------------------

use vars qw($VERSION);
$VERSION = substr q$Revision: 1.2 $, 10;

# --- module interface --------------------------------------------------------

sub new {
	my $class = shift;
	my $opts = shift;

	my $self = bless({}, $class);

	my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
	%$self = (%$self, %opts);

	$self->{alias}		||= "main";
	$self->{bitrate}	||= 160;
	$self->{priority}	||= 20;
	$self->{status}		||= "status";
	$self->{error}		||= "error";

	return $self;
	}

sub enc {
	my ($self, $fn, $del, @xargs) = @_;

	POE::Session->create(
		inline_states => {
			_start		=> \&_start,
			_stop		=> \&_stop,
			got_output	=> \&got_output,
			got_error	=> \&got_error,
			got_done	=> \&got_done
			},
		args => [$self, $fn, $del, \@xargs]
		);
	}

# --- session handlers --------------------------------------------------------

sub _start {
	my ($heap, $self, $wav, $del, $xargs) = @_[HEAP, ARG0, ARG3];

	$heap->{self} = $self;
	($self->{mp3} = $wav) =~ s/(.*)\.(.*)$/$1.mp3/;
	$heap->{del} = $del;
	$heap->{xargs} = $xargs;

	my @cmd = ("notlame", "-b", $self->{dev}, $wav, $self->{mp3});
	$heap->{child} = POE::Wheel::Run->new(
		Program		=> \@cmd,
		Priority	=> $self->{priority},
		StdioFilter	=> POE::Filter::Line->new(),	# Child speaks in lines
		Conduit		=> "pty",
		StdoutEvent	=> "got_output", 				# Child wrote to STDOUT
		CloseEvent	=> "got_done",
		);
	}

sub _stop {
	kill 9, $_[HEAP]->{child}->PID;
	}

sub got_output {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	local $_ = $_[ARG0];

	$heap->{quality} = $1 if /Encoding as\s+(.*)/;

	return unless m|^\s+(\d+)/(\d+)\s+\(\s*(\d+)%\)|;
	my ($frame, $nof, $p) = ($1, $2, $3);

	$kernel->post($heap->{self}{alias}
		, status => [$frame, $nof, $p]
		);
	}

sub got_done {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $self = $heap->{self};

    $kernel->post($self->{alias},
		$self->{done} => $self->{mp3}, $self->{del}, $self->{xargs}
		);
    delete $heap->{child};
	}

sub got_error {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $self = $heap->{self};
	$kernel->post($self->{alias}, $self->{error});
	}

1; # :)

__END__

=head1 NAME

POE::Component::Enc::Mp3 - mp3 encoder wrapper

=head1 SYNOPSIS

use POE qw(Component::Enc::Mp3);

$mp3 = POE::Component::Enc::Mp3->new($bitrate => 160);
$mp3->enc("/tmp/tst.wav");

POE::Kernel->run();

=head1 DESCRIPTION

This POE component encodes raw audio files into mp3 format.  It is merely a wrapper for the F<notlame> program.

=head1 METHODS

The module provides an object oriented interface as follows: 

=head2 new

Used to initialise the system and create a module instance.  The following parameters are available:

=item alias

Indicates the name of a session to which module callbacks are posted.  Default: C<main>.

=item bitrate

Should be self-evident.  If left unspecified, defaults to 160.

=head2 enc <file-name> [del-orig]

Encodes the given file, naming it with a C<.mp3> extension.  An optional true value for the second parameter indicates that the original file should be deleted.

    e.g. $mp3->enc("/tmp/tst.wav");

=head1 CALLBACKS

Callbacks are made to the session indicated in the C<spawn()> method.  The names of the functions called back may also be set via the aforementioned method.  The following callbacks are issued:

=head2 status

Fired during processing.  ARG0 is the block number being processed whilst ARG1 represents the percentage of completion expressed as a whole number between 0 and 100.

=head2 done

This callback is made upon completion of encoding.

=head2 error

Fired on the event of an error.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

My gratitude to Rocco Caputo and Matt Cashner whose code has helped me put this together.

=head1 DATE

$Date: 2002/09/14 22:36:06 $

=head1 VERSION

$Revision: 1.2 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.
=cut
