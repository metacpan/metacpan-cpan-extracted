#
#	CD::Detect POE wrapper
#
#	Copryright (c) Erick Calder 2001.
#	All rights reserved.
#

package POE::Component::CD::Detect;

# --- external modules --------------------------------------------------------

use warnings;
use strict;
use Carp;

use Fcntl;
use IO::Socket;

use POE;

# --- module initialisation ---------------------------------------------------

use vars qw($VERSION);
$VERSION = substr q$Revision: 1.1 $, 10;

#	error return codes

my $ERR_DEVOPEN = 1;
my $ERR_DEVREAD = 2;
my $ERR_TRKREAD = 3;
my @ERRMSG = (""
	, "Cannot open CDROM"
	, "Cannot read TOC"
	, "Cannot read track info"
	);

#	endian check

my $BIG_ENDIAN = unpack("h*", pack("s", 1)) =~ /01/;

# --- module interface --------------------------------------------------------

sub new {
	my $class = shift;
	my $opts = shift;

	my $self = bless({}, $class);

	my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
	%$self = (%$self, %opts);

	$self->{alias} ||= "main";
	$self->{delay} ||= 5;

	$self->initdev();

	POE::Session->create(
		inline_states => { _start => \&_start, check => \&check },
		args => [$self]
		);

	return $self;
	}

sub suspend {
	my $self = shift;
	$self->{suspend} = 1;
	}

sub resume {
	my $self = shift;
	$self->{suspend} = 0;
	}

# --- session events ----------------------------------------------------------

sub _start {
	my ($kernel, $heap, $self) = @_[KERNEL, HEAP, ARG0];

	$heap->{self} = $self;
	$kernel->delay("check", $self->{delay});
	}

sub check {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $self = $heap->{self};

	$kernel->delay("check", $self->{delay});	# set up to come back
	return if $self->{suspend};					# no chks when suspended

	my @info = $self->info();
	$kernel->post($self->{alias}, "inserted", @info, $self->{dev})
		unless $self->{err};
	}

# --- TOC functionality -------------------------------------------------------

#
#	Syntax:
#		->info()
#	Synopsis:
#		Checks a given device for the presence of a CD.  When one
#		is found, the table of contents (TOC) and disc id are
#		provided.  If either there is no disc present or it can't
#		be read, a null is returned and the $self->{err} is set.
#	Returns:
#		$disc-id, \@TOC
#

sub info {
	my $self = shift;
	my $err = $self->{err} = 0;

	$err = !sysopen(CD, $self->{dev}, O_RDONLY | O_NONBLOCK);
	if ($err) {
		$self->{err} = $ERR_DEVOPEN;
		return;
		}

	my $tochdr = "";
	$err = !ioctl(CD, $self->{CDROMREADTOCHDR}, $tochdr);
	if ($err) {
		$self->{err} = $ERR_DEVREAD;
		return;
		}

	$tochdr = substr($tochdr, 2, 2) if $self->{OS} =~ /BSD/;
	my ($start, $end) = unpack "CC", $tochdr;
	my $size = $end - $start + 2;
	my $toc	 = " " x ($size * 8);
 
	my $tocentry;
	if($self->{OS} =~ /BSD/) { 
		my ($sz_hi, $sz_lo);
		$sz_hi = $BIG_ENDIAN ? int($size / 256) : $size & 255;
		$sz_lo = $BIG_ENDIAN ? $size & 255 : int($size / 256);
		$tocentry = pack "CCCCP8l", $self->{CDROM_MSF}, 0, $sz_hi, $sz_lo, $toc;
		$err = !ioctl(CD, $self->{CDROMREADTOCENTRY}, $tocentry);
		if ($err) {
			$self->{err} = $ERR_TRKREAD;
			return;
			}
		}

	my ($count, @toc) = 0;
	for my $i ($start .. $end, 0xAA) {
		my ($min, $sec, $frame);
	
		if ($self->{OS} =~ /BSD/) {
			($min, $sec, $frame) = unpack "CCC", substr($toc, $count + 5, 3);
			$count += 8;
			}
		else {
			$tocentry = pack "CCC", $i, 0, $self->{CDROM_MSF};
			$err = !ioctl(CD, $self->{CDROMREADTOCENTRY}, $tocentry);
			if ($err) {
				$self->{err} = $ERR_TRKREAD;
				return;
				}
			($min, $sec, $frame) = unpack "CCCC", substr($tocentry, 4, 4);
			}

		push @toc, {
			min		=> $min,
			sec		=> $sec,
			start	=> int($frame + 75 * (60 * $min + $sec))
			};
		}

	close(CD);

	my $discid = cddb_discid(@toc);
	# note that discid needs to be calculated with initial time values
	for my $i (0 .. @toc - 2) {
		$toc[$i]->{end} = $toc[$i + 1]->{start} - 1;
		my $len = $toc[$i]->{length} = $toc[$i]->{end} - $toc[$i]->{start};
		my $min = $toc[$i]->{min} = int($len / 60 / 75);
		$toc[$i]->{sec} = int($len / 75) - $min * 60;
		}

	return $discid, \@toc;
	}

sub cddb_discid {
	my @toc = @_;
	my $total = $#toc;
	my ($i, $t, $n); $i = $t = $n = 0;
  
	for (my $i = 0; $i < $total; $i++) {
		$n = $n + cddb_sum(($toc[$i]->{min} * 60) + $toc[$i]->{sec});
		}

	$t	= (($toc[$total]->{min} * 60) + $toc[$total]->{sec})
		- (($toc[0]->{min} * 60) + $toc[0]->{sec})
		;

	return (($n % 0xff) << 24 | $t << 8 | $total);
	}                                       

sub cddb_sum {
	my $n = shift;
	my $ret = 0;

	while ($n > 0) {
		$ret += ($n % 10);
		$n = int $n / 10;
		}

	return $ret;
	}                       

# --- utility functions -------------------------------------------------------

#
#	select appropriate default device
#

sub initdev {
	my $self = shift;

	$self->{dev} = "/dev/cdrom";

	# cdrom IOCTL magic (from c headers)
	# linux x86 is default

	# /usr/include/linux/cdrom.h
	$self->{CDROMREADTOCHDR} = 0x5305;
	$self->{CDROMREADTOCENTRY} = 0x5306;
	$self->{CDROM_MSF} = 0x02;

	# setup for linux, solaris x86, solaris spark
	# you freebsd needs looking into

	my $os; chomp($os = `uname -s`);
	my $machine; chomp($machine = `uname -m`);
	$self->{OS} = $os;
	$self->{ARCH} = $machine;

	if ($os eq "SunOS") {
  		# /usr/include/sys/cdio.h

		$self->{CDROMREADTOCHDR} = 0x49b;	# 1179
		$self->{CDROMREADTOCENTRY} = 0x49c;	# 1180

		if (-e "/vol/dev/aliases/cdrom0") {
			$self->{dev} = "/vol/dev/aliases/cdrom0";
			}
		elsif ($machine =~ /^sun/) {
			$self->{dev} = "/dev/rdsk/c0t6d0s0";	# on sparc and old suns
			}
		else {
			$self->{dev} = "/dev/rdsk/c1t0d0p0";	# on intel 
			}

	# works for netbsd, infos for other bsds welcome

	} elsif ($os =~ /BSD/i) {
		# /usr/include/sys/cdio.h

		$self->{CDROMREADTOCHDR} = 0x40046304;
		$self->{CDROMREADTOCENTRY} = 0xc0086305;

		$self->{CDDEV} = "/dev/cd0a";

		$self->{CDDEV} = "/dev/cd0c" if $os eq "OpenBSD";
		}
	}

1; # :)

__END__

=head1 NAME

POE::Component::CD::Detect - Detects CD insertions and provides TOC

=head1 SYNOPSIS

use POE qw(Component::CD::Detect);
POE::Component::CD::Detect->new();
POE::Kernel->run();

=head1 DESCRIPTION

This POE component detects the insertion of a CD into a given drive and issues a callback to the caller with the disc's table of contents.

=head1 METHODS

The module provides an object oriented interface as follows: 

=head2 new

Used to initialise the system and create a module instance.  The following parameters are available:

=item alias

Indicates the name of a session to which module callbacks are posted.  Default: C<main>.

=item delay

Indicates how often the drive is checked for the presence of a disc.

=item dev

Specifies the device to use.  If not provided, the module will make various assumptions about the device's name, depending on the operating system and platform.
=cut

=head1 CALLBACKS

Callbacks are made to the session indicated in the C<new()> method.  The names of the functions called back may also be set via the aforementioned method.

=head2 inserted

Fired whenever a disc is detected in the drive.  The following parameters are passed to this event: ARG0 = the disc id, ARG1 = an array-reference to the TOC (table of contents).

=head2 error

Fired on the event of an error.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

My gratitude to Rocco Caputo and Matt Cashner whose suggestions have allowed me to put this together.

=head1 DATE

$Date: 2002/09/14 22:42:20 $

=head1 VERSION

$Revision: 1.1 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.
=cut

__nihil_est__;
