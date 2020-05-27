#!/usr/bin/perl -w

###########################################################################
# $Id: rundeckAPI.pm, v1.0 r1 04/02/2020 13:58:58 CET XH Exp $
#
# Copyright 2020 Xavier Humbert <xavier.humbert@ac-nancy-metz.fr>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program ;  if not, write to the
# Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA
#
###########################################################################

package RundeckAPI;

use strict;
use warnings;
use POSIX qw(setlocale strftime);
use File::Basename;			# get basename()
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;
use REST::Client;
use Scalar::Util qw(reftype);
use JSON;
use Storable qw(dclone);
use Exporter qw(import);

our @EXPORT_OK = qw(get post put delete postFile putFile);

#####
## CONSTANTS
#####
our $TIMEOUT = 10;
our $VERSION = "1.2.4";
#####
## VARIABLES
#####

#####
## CONSTRUCTOR
#####

sub new {
	my($class, %args) = @_;
	my $rc=0;
	my $self = {
		'url'		=> $args{'url'},
		'login'		=> $args{'login'},
		'token'		=> $args{'token'},
		'password'	=> $args{'password'},
		'debug'		=> $args{'debug'} || 0,
		'verbose'	=> $args{'verbose'} || 0,
		'result'	=> undef,
	};
# create and store a cookie jar
	my $cookie_jar = HTTP::Cookies->new(
		autosave		=> 1,
		ignore_discard	=> 1,
	);
	$self->{'cookie_jar'} = $cookie_jar;

# with this cookie, cretae an User-Agent
	my($prog, $dirs, $suffix) = fileparse($0, (".pl"));
	my $ua = LWP::UserAgent->new(
		'agent'			=> $prog . "-" . $VERSION,
		'timeout'		=> $TIMEOUT,
		'cookie_jar'	=> $self->{'cookie_jar'},
		'requests_redirectable' => ['GET', 'HEAD', 'POST', 'PUT', 'DELETE'],
		);
	$ua->show_progress ($args{'debug'});
 	$ua->proxy( ['http', 'https'], $args{'proxy'}) if (defined $args{'proxy'});
	$self->{'ua'} = $ua;

# connect to the client
	my $client = REST::Client->new(
		host		=> $self->{'url'},
		timeout		=> 10,
		useragent	=> $ua,
		follow		=> 1,
	);
	$client->addHeader ("Content-Type", 'application/x-www-form-urlencoded');
	$client->addHeader ("Accept", "application/json");
	$self->{'client'} = $client;

# if we have a token, use it
	if (defined $self->{'token'}) {
		$client->addHeader ("X-Rundeck-Auth-Token", $self->{'token'});
		$client->GET("/api/11/tokens/$self->{'login'}");
# check if token match id, just to be sure
		my $authJSON = $client->responseContent();
		$rc = $client->responseCode ();
		if ($rc-$rc%100 == 200) {
			my $jHash = decode_json ($authJSON);
			if ($jHash->[0]->{'user'} ne $self->{'login'}) {
# should this really happen ?
				$rc = 403;
			}
			else {
				$rc = 200;
			}
		}
	} else {
# post user/passwd
		$client->POST(
			"j_security_check",
			"j_username=$self->{'login'}" . "&" . "j_password=$self->{'password'}",
		);
		$rc = $client->responseCode ();
	}
	my %hash = ();

## Dirty job, but Rundeck doent follow the REST norm, returning 200 even if auth fails
## However, this is safe, since if string not found it will fail at get/put/whatever time
	if (index($client->{'_res'}{'_content'}, 'alert alert-danger') != -1) {
		$rc = 403;
	}
	if ($rc != 200) {
		$self->{'result'}->{'reqstatus' } = 'UNKN';
	} else {
		$self->{'result'}->{'reqstatus'} = 'OK';
	}
	$self->{'result'}->{'httpstatus'} = $rc;

# done, bless object and return it
	bless ($self, $class);
	$self->_logV1 ("Connected to $self->{'url'}");
	$self->_logD($self);
	return $self;
}

#####
## METHODS
#####

sub get (){		# endpoint
	my $self = shift;
	my $endpoint = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->GET($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$responsehash->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
	# handle special case where test is "ping", response is "pong" in plain text, not a json
		if ($endpoint =~ /ping/) {
			$responsehash->{'reqstatus'} = $responseContent =~ /pong/ ? 'OK' : 'CRIT';
			return dclone ($responsehash);
		}
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);
}

sub post(){		# endpoint, json
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->POST($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);
}

sub put(){		# endpoint, json
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->PUT($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);
}

sub delete () {		# endpoint
	my $self = shift;
	my $endpoint = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->DELETE($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$responsehash->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);
}

sub postFile() {		# endpoint, mimetype, data
	my $self = shift;
	my $endpoint = shift;
	my $mimetype = shift;
	my $data = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", $mimetype);
	$self->{'client'}->POST($endpoint, $data);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);

}

sub putFile() {		# endpoint, mimetype, data
	my $self = shift;
	my $endpoint = shift;
	my $mimetype = shift;
	my $data = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", $mimetype);
	$self->{'client'}->PUT($endpoint, $data);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseContent);
	}
	return dclone ($responsehash);

}


sub _handleResponse () {
	my $self = shift;
	my $rc = shift;
	my $responseContent = shift;

	my $responseJSON = ();
	my $responsehash = ();

	$self->_logV2($responseContent);
	$responseJSON = decode_json($responseContent) if $responseContent ne '';
	my $reftype = reftype($responseJSON);
	if (not defined $reftype) {
		$self->_bomb("Can't decode undef type");
	} elsif ($reftype eq 'ARRAY') {

		$responsehash->{'arraycount'} = $#$responseJSON+1;
		for (my $i = 0; $i <= $#$responseJSON; $i++) {
			$responsehash->{$i} = $responseJSON->[$i];
		}
	} elsif ($reftype eq 'SCALAR') {
		$self->_bomb("Can't decode scalar type");
	} elsif ($reftype eq 'HASH') {
		$responsehash = dclone ($responseJSON);
	}
	$responsehash->{'reqstatus'} = 'OK';
	$responsehash->{'httpstatus'} = $rc;
	return $responsehash;
}

sub _logV1() {
	my $self = shift;
	my $msg = shift;

	if ($self->{'verbose'} >= 1) {
		if (defined $msg) {
			print "$msg\n";
		} else {
			print "unknown $!";
		}
	}
}
sub _logV2() {
	my $self = shift;
	my $obj = shift;

	if ($self->{'verbose'} >= 2) {
		if (defined $obj) {
			print Dumper ($obj);
		} else {
			print "unknown objetc $!";
		}
	}
}

sub _logD() {
	my $self = shift;
	my $object = shift;

	print Dumper ($object) if $self->{'debug'};
}

sub _bomb() {
	my $self = shift;
	my $msg = shift;

	$msg .= "\nReport this to xavier.humbert\@ac-nancy-metz.fr";
	die $msg;
}
1;

=pod

=head1 NAME

RundeckAPI - simplifies authenticate, connect, queries to a Rundeck instance via REST API

=head1 SYNOPSIS
	use RundeckAPI;

	# create an object of type RundeckAPI :
	my $api = RundeckAPI->new(
		'url'		=> "https://my.rundeck.instance:4440",
		'login'		=> "admin",
		'password'	=> "passwd",
	# OR token, takes precedence
		'token'		=> <token as generated with GUI, as an admin>
		'debug'		=> 1,
 		'proxy'		=> "http://proxy.mycompany.com/",
	);
	my $hashRef = $api->get("/api/27/system/info");
	my $json = '{some: value}';
	$hashRef = $api->put(/api/27/endpoint_for_put, $json);

=head1 METHODS

=over 12

=item C<new>

Returns an object authenticated and connected to a Rundeck Instance

=item C<get>

Sends a GET query. Request one argument, the enpoint to the API. Returns a hash reference

=item C<post>

Sends a POST query. Request two arguments, the enpoint to the API an the data in json format. Returns a hash reference

=item C<put>

Sends a PUT query. Similar to post

=item C<delete>

Sends a DELETE query. Similar to get

=back

=head1 SEE ALSO

See documentation for Rundeck's API https://docs.rundeck.com/docs/api/rundeck-api.html and returned data

=head1 AUTHOR
	Xavier Humbert <xavier.humbert-at-ac-nancy-metz-dot-fr>

=cut
