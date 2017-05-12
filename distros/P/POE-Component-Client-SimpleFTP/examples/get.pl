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
package GetClient;

# a simple client to get a file

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

has file => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

has passive => (
	isa => 'Bool',
	is => 'ro',
	default => 1,
);

has local_addr => (
	isa => 'Str',
	is => 'ro',
	default => '0.0.0.0',
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
		local_addr => $self->local_addr,
		username => $self->username,
		password => $self->password,
		( $self->passive ? ( connection_mode => 'passive' ) : ( connection_mode => 'active' ) ),
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

	# Okay, get the file!
	$self->ftp->yield( 'get', $self->file );

	return;
};

event get_error => sub {
	my( $self, $code, $reply, $path ) = @_;

	die "get error: $code $reply";

	return;
};

event get_connected => sub {
	my( $self, $path ) = @_;

	# do nothing hah

	return;
};

event get_data => sub {
	my( $self, $input ) = @_;

	print "$input\n";

	return;
};

event get => sub {
	my( $self, $code, $reply, $path ) = @_;

	# done with the file, we disconnect
	$self->ftp->yield( 'quit' );

	return;
};

# run the client!
my $ftp = GetClient->new_with_options;
POE::Kernel->run;
