#!/usr/bin/perl
#
# This file is part of POE-Component-Client-SimpleFTP
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package FEATClient;

# a simple client to list the features a ftpd supports

#sub POE::Component::Client::SimpleFTP::DEBUG () { 1 };

use MooseX::POE::SweetArgs;
use POE::Component::Client::SimpleFTP;

with qw(
	MooseX::Getopt
);

has hostname => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

has port => (
	isa => 'Int',
	is => 'ro',
	default => 21,
);

has usetls => (
	isa => 'Bool',
	is => 'ro',
	default => 0,
);

has username => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

has password => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

# our ftp object
has ftp => (
	traits => ['NoGetopt'],
	isa => 'POE::Component::Client::SimpleFTP',
	is => 'rw',
	weak_ref => 1,
	init_arg => undef,
);

sub START {
	my $self = shift;

	$self->ftp( POE::Component::Client::SimpleFTP->new(
		remote_addr => $self->hostname,
		remote_port => $self->port,
		username => $self->username,
		password => $self->password,
		( $self->usetls ? ( tls_cmd => 1, tls_data => 1 ) : () ),
	) );

	# now we just wait for the connection to succeed/fail
	return;
}

event _child => sub { return };

event connected => sub {
	my $self = shift;

	# do nothing hah

	return;
};

event connect_error => sub {
	my( $self, $code, $reply ) = @_;

	die "CONNECT error: $code $reply";

	return;
};

event login_error => sub {
	my( $self, $code, $reply ) = @_;

	die "LOGIN error: $code $reply";

	return;
};

event authenticated => sub {
	my $self = shift;

	# Okay, get the feature list
	$self->ftp->yield( 'features' );

	return;
};

event features_error => sub {
	my( $self, $code, $reply ) = @_;

	die "FEAT error: $code $reply";

	return;
};

event features => sub {
	my( $self, $code, $reply ) = @_;

	# done with the feature request
	print "$reply\n";
	$self->ftp->yield( 'quit' );

	return;
};

# run the client!
my $ftp = FEATClient->new_with_options;
POE::Kernel->run;
