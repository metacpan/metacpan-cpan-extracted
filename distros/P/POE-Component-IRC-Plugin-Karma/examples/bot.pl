#!/usr/bin/perl
#
# This file is part of POE-Component-IRC-Plugin-Karma
#
# This software is copyright (c) 2011 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

# A simple bot to showcase karma capabilities
use POE qw( Component::IRC Component::IRC::Plugin::Karma Component::IRC::Plugin::AutoJoin );

# Create a new PoCo-IRC object
my $irc = POE::Component::IRC->spawn(
	nick => 'karmabot',
	ircname => 'karmabot',
	server  => '192.168.0.200',
) or die "Oh noooo! $!";

# Create our own session
POE::Session->create(
	package_states => [
		main => [ qw( _default _start ) ],
	],
);

POE::Kernel->run;

sub _start {
	# Setup our plugins + tell the bot to connect!
	$irc->plugin_add( 'AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => [ '#test' ] ));
	$irc->plugin_add( 'Karma', POE::Component::IRC::Plugin::Karma->new( extrastats => 1 ) );
	$irc->yield( register => 'all' );
	$irc->yield( connect => { } );
	return;
}

# We registered for all events, this will produce some debug info.
sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];
	my @output = ( "$event: " );

	for my $arg (@$args) {
		if ( ref $arg eq 'ARRAY' ) {
			push( @output, '[' . join(', ', @$arg ) . ']' );
		} else {
			push ( @output, "'$arg'" );
		}
	}
	print join ' ', @output, "\n";
	return;
}
