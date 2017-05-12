#
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

=head1 NAME

POE::Component::Player::Slideshow - a wrapper for the C<qiv> application

=head1 SYNOPSIS

 use POE qw(Component::Player::Slideshow);

 $mp = POE::Component::Player::Slideshow->new();
 $mp->play("/tmp/pix");

 POE::Kernel->run();

=head1 DESCRIPTION

This component is used to manipulate a slideshow viewer from within a POE application.  At present it works with the C<qiv>, the QuickView viewer.

=cut

package POE::Component::Player::Slideshow;

# --- external modules --------------------------------------------------------

use warnings;
use strict;

use POE;
use POE::Component::Child;
use X11::SendEvent;

# --- module variables --------------------------------------------------------

use vars qw($VERSION $AUTOLOAD $RPM_Requires %keysyms);

$VERSION		= substr q$Revision: 1.4 $, 10;
$RPM_Requires	= "qiv";		# tells RPM to require stuff

@POE::Component::Player::Slideshow::ISA = ("POE::Component::Child");

# --- module interface --------------------------------------------------------

=head1 METHODS

An object oriented interface is provided as follows: 

=head2 new [hash[-ref]]

Used to initialise the system and create a module instance.  The optional hash (or hash reference) may contain any of the following keys:

=item alias

Indicates the name of a session to which events will be posted.  Default: C<main>.

=item disp

Specifies X display to use.  Default: C<localhost:0>.

=item delay

Indicates the delay (in 1/100ths of a second) to display each image.  Default: C<150>.

=item ext

Specifies which file extensions to use.  Default: C<*>.

=item xargs

Allows for passing extra arguments to the underlying application.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my %defs = (
		alias	=> "main",
		disp	=> $ENV{DISPLAY} || "localhost:0",
		delay	=> 150,
		ext		=> "*",		# use all files by default
		xargs	=> [],
		state	=> "init",
		writemap => {
			fullscreen	=> "f",
			fitscreen	=> "mt",
			zoomin		=> "[plus]",
			zoomout		=> "[minus]",
			brighter	=> "B",
			dimmer		=> "b",
			contup		=> "C",
			contdown	=> "c",
			fliphorz	=> "h",
			flipvert	=> "v",
			rotleft		=> "l",
			rotright	=> "k",
			status		=> "i",
			delete		=> "D",
			restore		=> "[Return]",
			random		=> "r",
			next		=> "jf1[Return]",
			prev		=> "jb1[Return]",
			help		=> "[question]",
			}
		);

	my %args = @_;
	$args{$_} ||= $defs{$_} for keys %defs;

	my $self = $class->SUPER::new(
		alias	=> $args{alias},
		debug	=> $args{debug},
		);

	%$self = (%$self, %args);
	return $self;
	}

=head2 play <dir> [options]

This method requires a parameter specifying the directory which contains the images.  Warnings are issued if either the path passed is not a directory, or if the directory cannot be read.

Additionally the following arguments may be passed:

=item random

Specifies that the directory listing should be shuffled before playing.

=item window

Used to suppress display of the slideshow in full screen mode.

=item noscale

Used to suppress automatically scaling of images to fit the screen.

=item delay disp

This arguments may be passed to override the defaults supplied to C<new()>.

=cut

sub play {
	my $self = shift;
	my $d = shift || return;
	my %args = (%$self, @_);

	return warn qq/not a directory: "$d"/ unless -d $d;
	return warn qq/no read permissions on: "$d"/ unless -r $d;

	$self->stop() if $self->playing();

	my @args = ("--no_statusbar", "--slide");
	push @args, "--delay=$args{delay}";
	push @args, "--display=$args{disp}";
	push @args, "--shuffle" if $args{random};
	push @args, "--fullscreen" unless $args{window};
	push @args, ("--maxpect", "--scale_down") unless $args{noscale};
	push @args, @{ $args{xargs} };

	$self->{state} = "playing";
	$self->run("qiv", @args, glob("$d/$args{ext}"));
	}

=head2 quit pause resume

None of these methods take any parameters and will do exactly as thier name implies.  Please note that pause/resume are semaphored i.e. issuing a C<pause> whilst the system is already paused will do exactly diddley :)

=cut

sub quit {
	my ($self) = @_;
	$self->write("q");
	$self->{state} = "stopped";
	}

sub pause {
	my ($self) = @_;
	return unless $self->playing();
	$self->write("s");
	$self->{state} = "paused";
	}

sub resume {
	my ($self) = @_;
	return unless $self->paused();
	$self->write("s");
	$self->{state} = "playing";
	}

=head2 playing paused stopped

Provides a means of testing the player' state.

=cut

sub playing {
	my $self = shift;
	$self->{state} eq "playing";
	}

sub paused {
	my $self = shift;
	$self->{state} eq "paused";
	}

sub stopped {
	my $self = shift;
	$self->{state} eq "stopped";
	}

=head2 xcmd <string>

This method allows for the sending of arbitrary commands to the player and is useful for easily extending the functionality of the wrapper.  For information on available commands please see the underlying viewer's documentation.

=cut

sub xcmd {
	my ($self, $cmd) = @_;
	return unless $cmd;
	$self->write($cmd);
	}

=head2 fullscreen fitscreen random status delete help
=head2 dimmer/brigher contup/contdown zoomin/zoomout
=head2 fliphorz/flipvert rotleft/rotright next/prev

The above enumerated methods perform the functions described.  Those presented in pairs (divided by slashes) act in opposition to each other whilst those presented singly act as toggles.

For greater detail on the meaning of these methods please refer to the underlying viewers documentation.

=cut

sub write {
	my $self = shift;
	local $_ = shift || $_;
	
	my @s;
	for (split /(?=\[)|(?<=\])/) {
		push @s, s/^\[|\]$//g ? [$_] : $_;
		}

	unless ($self->{x}) {
		$self->{x} = X11::SendEvent->new(
			disp => $self->{disp},
			win => ["qiv:"],
			debug => $self->{debug},
			);
		}

	$self->{x}->SendString(@s);
	}

sub AUTOLOAD {
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return if $attr eq 'DESTROY';   

	my $cmd = $self->{writemap}{$attr};
	$self->write($cmd), return if $cmd;

	my $super = "SUPER::$attr";
	$self->$super(@_);
	}

1; # :)

__END__

=head1 EVENTS

At present no events are thrown by this component.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 AVAILABILITY + SUPPORT

For support e-mail the author.  This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 ACKNOWLEDGEMENTS

The test suite in this package includes a number of images that were graciously donated by Marion Lane, a most intriguing artist doing some unbelievable things with acryllic.  Check out her web site at: http://www.marionlane.com - or look out for her on eBay.

Thanks Marion!  ...and keep up the good work!

=head1 DATE

$Date: 2002/12/10 02:07:45 $

=head1 VERSION

$Revision: 1.4 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.

