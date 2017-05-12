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
package PutClient;

# a simple client to put a file

sub POE::Component::Client::SimpleFTP::DEBUG () { 1 };

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

# the file we are currently transferring
has filefh => (
	traits => ['NoGetopt'],
	isa => 'Ref',
	is => 'rw',
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
	$self->ftp->yield( 'put', $self->file );

	return;
};

event put_error => sub {
	my( $self, $code, $reply, $path ) = @_;

	die "put error: $code $reply";

	return;
};

event put_connected => sub {
	my( $self, $path ) = @_;

	# okay, we can send the first block of data!
	if ( open( my $fh, '<', $self->file ) ) {
		$self->filefh( $fh );

		# send the first chunk
		$self->send_chunk;
	} else {
		die "put error: unable to open " . $self->file . ": $!";
	}

	return;
};

event put_flushed => sub {
	my( $self, $path ) = @_;

	# read the next chunk of data from the fh
	$self->send_chunk;

	return;
};

sub send_chunk {
	my $self = shift;

	my $buf;
	my $retval = read( $self->filefh, $buf, 1024 );
	if ( $retval ) {
		$self->ftp->yield( 'put_data', $buf );
	} elsif ( $retval == 0 ) {
		# all done with the file
		if ( close( $self->filefh ) ) {
			$self->ftp->yield( 'put_close' );
		} else {
			die "put error: unable to close: $!";
		}
	} else {
		# error reading file
		die "put error: unable to read: $!";
	}

	return;
}

event put => sub {
	my( $self, $code, $reply, $path ) = @_;

	# done with the file, we disconnect
	print "Successfully uploaded " . $self->file . "\n";
	$self->ftp->yield( 'quit' );

	return;
};

# run the client!
my $ftp = PutClient->new_with_options;
POE::Kernel->run;
