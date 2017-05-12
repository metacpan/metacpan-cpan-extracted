#
#	CD ripping POE component
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

package POE::Component::CD::Rip;

# --- external modules --------------------------------------------------------

use warnings;
use strict;
use Carp;

use POE qw(Wheel::Run Filter::Line Driver::SysRW);

# --- module variables --------------------------------------------------------

use vars qw($VERSION);
$VERSION = substr q$Revision: 1.2 $, 10;

my %stat = (
	':-)' => 'Normal operation, low/no jitter',
	':-|' => 'Normal operation, considerable jitter',
	':-/' => 'Read drift',
	':-P' => 'Unreported loss of streaming in atomic read operation',
	'8-|' => 'Finding read problems at same point during reread; hard to correct',
	':-0' => 'SCSI/ATAPI transport error',
	':-(' => 'Scratch detected',
	';-(' => 'Gave up trying to perform a correction',
	'8-X' => 'Aborted (as per -X) due to a scratch/skip',
	':^D' => 'Finished extracting',
	);

# --- module interface --------------------------------------------------------

sub new {
	my $class = shift;
	my $opts = shift;

	my $self = bless({}, $class);

	my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
	%$self = (%$self, %opts);

	$self->{dev} ||= "/dev/cdrom";
	$self->{alias} ||= "main";
	$self->{status} ||= "status";
	$self->{done} ||= "done";

	return $self;
	}

sub rip {
	my $self = shift;
	my ($n, $fn) = @_;

	POE::Session->create(
		inline_states => {
			_start		=> \&_start,
			_stop		=> \&_stop,
			got_output	=> \&got_output,
			got_error	=> \&got_error,
			got_done	=> \&got_done
			},
		args => [$self, $n, $fn]
		);
	}

# --- session handlers --------------------------------------------------------

sub _start {
	my ($heap, $self, $n, $fn) = @_[HEAP, ARG0 .. ARG2];

	$heap->{self} = $self;
	$heap->{n} = $n;
	$heap->{fn} = $fn;

	my @cmd = ("cdparanoia", "-d", $self->{dev}, $n, $fn);
	$heap->{child} = POE::Wheel::Run->new(
		Program		=> \@cmd,
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

	$heap->{from} = $1	if /from sector\s+(\d+)/;
	$heap->{to} = $1	if /to sector\s+(\d+)/;

	if (/PROGRESS/) {
		my $blk = substr($_, 50, 6); $blk =~ s/\.+/$heap->{from}/;
		my $st = substr($_, 65, 3);	# smiley
		my $stmsg = $stat{$st};
		my $p = ($blk - $heap->{from}) / ($heap->{to} - $heap->{from});
		$p = int(100 * $p);
		my $self = $heap->{self};
		$kernel->post($self->{alias}
			, $self->{status} => [$blk, $p, $st, $stmsg]
			);
		}
	}

sub got_done {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $self = $heap->{self};

    $kernel->post($self->{alias}, $self->{done}, $self->{fn}, $self->{n});
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

POE::Component::CD::Rip - POE Component for running cdparanoia, a CD ripper.

=head1 SYNOPSIS

use POE qw(Component::CD::Rip);

$cd = POE::Component::CD::Rip->new(alias => $alias);
$cd->rip(3, "/tmp/03.rip");

$POE::Kernel->run();

=head1 DESCRIPTION

This POE component serves to rip tracks from a CD.  At present it is merely a wrapper for the B<cdparanoia> program which does the bulk of the work.

=head1 METHODS

The module provides an object oriented interface as follows: 

=head2 new

Used to initialise the system and create a module instance.  The following parameters are available:

=item alias

Indicates the name of a session to which module callbacks will be posted.  Default: C<main>.

=item dev

Indicates the device to rip from.  Default: F</dev/cdrom>.

=head2 rip

Used to request that a track be ripped.  The following parameters are required:

=item track-number

Indicates the number of the track to rip, starting with 1.

=item file-name

Provides the name of the file where to store the rip.

    e.g. C<$cdr->rip(3, "/tmp/tst.rip");>

=head1 CALLBACKS

Callbacks are made to the session indicated in the C<spawn()> method.  The names of the functions called back may also be set via the aforementioned method.  The following callbacks are issued:

=head2 status

Fired during processing.  ARG0 is the block number being processed whilst ARG1 represents the percentage of completion expressed as a whole number between 0 and 100.

=head2 done

Fired upon completion of a rip.  The ARG0 parameter contains the name of the file ripped.

=head2 error

Fired on the event of an error.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

My gratitude to Rocco Caputo and Matt Cashner whose code has helped me put this together.

=head1 DATE

$Date: 2002/09/14 22:45:41 $

=head1 VERSION

$Revision: 1.2 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.
=cut
