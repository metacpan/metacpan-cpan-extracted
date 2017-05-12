#!/usr/bin/perl
#
# This file is part of POE-Component-SmokeBox-Uploads-Rsync
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

#sub POE::Component::SmokeBox::Uploads::Rsync::DEBUG () { 1 }

use POE;
use POE::Component::SmokeBox::Uploads::Rsync;

use Time::Duration qw( duration_exact );

# Create our session to receive events from rsync
POE::Session->create(
	package_states => [
		'main' => [qw(_start upload rsyncdone)],
	],
);

sub _start {
	# Tell the poco to start it's stuff!
	POE::Component::SmokeBox::Uploads::Rsync->spawn(
		'rsync_src'	=> 'mirrors.kernel.org::mirrors/CPAN/',
		'rsyncdone'	=> 'rsyncdone',
	) or die "Unable to spawn the poco-rsync!";

	return;
}

sub rsyncdone {
	my $r = $_[ARG0];

	if ( $r->{'status'} ) {
		print "Successfully completed a rsync run! (duration: " . duration_exact( $r->{'stoptime'} - $r->{'starttime'} ) . " dists: $r->{'dists'})\n";
	} else {
		print "Failed to complete a rsync run: rsync error $r->{'exit'} duration: " . duration_exact( $r->{'stoptime'} - $r->{'starttime'} ) . "\n";
	}

	return;
}

sub upload {
	print $_[ARG0], "\n";
	return;
}

POE::Kernel->run;
