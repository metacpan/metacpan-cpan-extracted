# Net::SDEE::Session.pm
#
# $Id: Session.pm,v 1.1 2004/12/23 12:02:30 jminieri Exp $
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::SDEE::Session;

use 5.006001;
use strict;
use warnings;

use MIME::Base64;
use LWP::UserAgent;

my @_uri_parameters = ( 'Scheme', 'Server', 'Port', 'Username', 'Password', 'Path' );
my @_http_header = ( 'UserAgent', 'Authorization' );

our $VERSION = '0.01';

##########################################################################################
#
# AUTOLOAD get/set methods when they're generic
#
use vars '$AUTOLOAD';
sub AUTOLOAD {
        no strict 'refs';
        my ($self, $value) = @_;

        my $method =($AUTOLOAD =~ /.*::([_\w]+)$/)[0];
	return if $method eq 'DESTROY';

        unless(defined($method) and exists($self->{ $method })) {
                $self->error(1);
                $self->errorString("No such parameter $method");
                return undef;
	}

        # set this up for next time
        *{$AUTOLOAD} = sub {
		my ($self, $value) = @_;
                if (defined($value)) {
                        return $self->{ $method } = $value;
                } else {
                        return defined($self->{ $method })?$self->{ $method }:undef;
                }
        };

	goto &$AUTOLOAD;
}
#
##########################################################################################

##########################################################################################
#
sub new {
        my $caller = shift;
        my %attr = @_;

	my $class = (ref($caller) or $caller);

        my $self = bless {
		# connection parameters
		'Scheme',               'https',
		'Server',               '127.0.0.1',
		'Port',                 443,
		'Path',                 '/cgi-bin/sdee-server',
		'UserAgent',            'SDEE Client/1.0',
		'Authorization',        undef,
		'Username',             'username',
		'Password',             'password',
		# subscription parameters
		'Cookie',               undef,
		'sessionId',            undef,
		'state',                'closed', #is this per subscription or session?
		'Type',                 'subscription',
		'error',		undef,
		'errorString',		undef
	}, $class;

	foreach my $attribute ( keys %attr ) {
		$self->$attribute( $attr{ $attribute });
	}

        #if(defined($self->{debug})) { $DEBUG_FLAG = 1; }

	$self->state('closed');
	$self->error(undef);
	$self->errorString(undef);

        return $self;
}

#
##########################################################################################

##########################################################################################
#
sub getURL {
	my $self = shift;

	my $URI = URI->new();
	$URI->scheme( $self->Scheme );
	$URI->host( $self->Server );
	unless($self->Port == 443) { $URI->port( $self->Port ); }
	$URI->path( $self->Path );

	return $URI->as_string;
}

sub getHeader {
	my $self = shift;

	unless(defined($self->Authorization)) {
        	$self->Authorization('Basic ' . 
		MIME::Base64::encode( $self->Username . ':' . $self->Password, ''));
	}

	my %headers = (
		'User-Agent'    => $self->UserAgent,
		'Authorization' => $self->Authorization
	);

	if(defined($self->Cookie)) {
		$headers{ Cookie } = $self->Cookie;
	}

	return \%headers;

}

#
##########################################################################################

1;
__END__
