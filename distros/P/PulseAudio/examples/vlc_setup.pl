#!/usr/bin/perl
use strict;
use warnings;
use PulseAudio;


=head1 NAME

vlc_setup.pl - A VLC configuration script

=head2 SYNOPSIS

=over 4

=item DEST=ONBOARD vlc ./foo.wav

=item DEST=MIX1516 vlc http://www.youtube.com/watch?v=bUbF94x2NZo

=back

=head1 DESCRIPTION

This is a real script used in production. This takes the ENV argument DEST=<constant> where the constant resolves to a hard-coded dev.bus_path. This permits me to script-launch VLC with pulse-configured.

=cut

##
## Configure where stuff is at
##
use constant {
	USB_BUS       => 'pci-0000:00:14.0-usb-0'
	, USB_SUB_BUS => '1.0'
};

## Valid as values to env variable DEST
use constant {
	ONBOARD    => 'pci-0000:00:1b.0'
	, MIX1516  => USB_BUS . ':3.3.1:' . USB_SUB_BUS
	, MIX1314  => USB_BUS . ':3.3.2:' . USB_SUB_BUS
	, TRACKIN  => 'pci-0000:00:14.0-usb-0:3.1:1.0'
};

## Valid as values to env variable DEST
use constant {
	SKYPE  => MIX1314
	, AOUT => MIX1516
};


##
## Laucher and interface with PulseAudio.pm
##

my $pa = PulseAudio->new;
my $dest = $ENV{DEST};

die 'PLEASE PROVIDE A DESTINATION DEST=' unless $ENV{DEST};

{
 	my $sink   = $pa->get_sink_by([qw/properties device.bus_path/],  __PACKAGE__->$dest );

	if ( $dest ne 'ONBOARD' ) {
		my $source = $pa->get_source_by(
			[qw/properties device.bus_path/] => __PACKAGE__->$dest
			, [qw/properties device.profile.name/] => 'analog-stereo'
		);
		$pa->exec({
			sink      => $sink
			, source  => $source
			, prog    => '/usr/bin/vlc'
			, args    => \@ARGV
		});
	}

	$sink->exec({
		prog   => '/usr/bin/vlc'
		, args => \@ARGV
	});

}
