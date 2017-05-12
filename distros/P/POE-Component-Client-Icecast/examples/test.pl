#!/usr/bin/perl
use strict;

use lib '../lib';
BEGIN { $ENV{ICECAST_DEBUG}; $ENV{ICECAST_TRACE} };
use POE qw(Component::Client::Icecast);
use Data::Dumper;

POE::Component::Client::Icecast->new(
	Stream    => 'http://station20.ru:8000/station-128',
	
	# Path          => '/station-128',
	# Host          => 'station20.ru',
	# 
	# RemoteAddress => '87.242.82.108',
	# RemotePort    => 8000,
	# BindPort      => 8103, # for only one permanent client
	# BindAddress   => '87.242.82.108',
	
	Reconnect => 10,
	
	GetTags   => sub {
		warn Dumper $_[ARG0];
	},
);

POE::Kernel->run;
