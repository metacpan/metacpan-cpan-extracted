#! /usr/bin/perl
#
# This is an example of using Net::Radius::Server::DBStore to build
# a cache of Port-Ids to Acct-Session-Ids, which might come handy when
# dealing with aggregators that provide per-device accounting 
# information.
#
# This implements a function that keeps the cache updated inside 
# database. This works autonomously and builds the cache as
# Access-Request / Accounting-Request packets are received.
#
# This file will require some tweaking before using in production, so
# make sure you really understand this _before_ sending it to the 
# front. Also, keep in mind that various (many?) instances of the
# nrsd server will be executing, so whetever mechanism you choose for
# storing the data, must support concurrency.
#
# Copyright © 2009, Luis E. Muñoz - All Rights Reserved
#
# $Id: session-cache.pl 112 2009-10-18 17:51:58Z lem $

use strict;
use warnings;

# We are really using a tied hash for the storage, so you can change
# these modules to suit your needs.

use MLDBM::Sync;
use MLDBM qw(DB_File Storable);

use File::Spec::Functions;
use Net::Radius::Server::Rule;
use Net::Radius::Server::DBStore;
use Net::Radius::Server::Base qw/:all/;
use Net::Radius::Server::Match::Simple;

my @rules          = ();
my $db_file        = catfile($ENV{HOME}, 'radius-session-cache.db');
my $log_level      = 1;
my $delete_on_stop = 1;		# Delete session on Acct stop?

# This function looks into the given hash, retrieving and storing the
# required value in the per-transaction tuple. We will store our data
# in _sessions.

sub cache_session
{
    my ($dbstore, $hobj, $r_hash, $r_data, $req, $key) = @_;

    # Recover stored data and attributes from the request
    my $h = $r_hash->{$key};
    my $t = $req->attr('Acct-Status-Type') || '';
    my $s = $req->attr('Acct-Session-Id');
    $r_data->{_sessions} = $h->{_sessions};

    if ($delete_on_stop
	&& $req->attr('Acct-Status-Type') =~ m/(?i)^Stop$/)
    {
	# Remove this session from the cache
	$dbstore->log(3, "Remove session $s from $key");
	delete $r_data->{_sessions}->{$s};
    } else {
	# Add our session there, possibly updating the timestamp
	$dbstore->log(3, "Add/update session $s to $key");
	$r_data->{_sessions}->{$s} = time;
    }
}

# This rule simply logs the Acct-Session-Id if present in the
# packet. It leaves the crafting of an actual response to other rules
# in the pipeline.

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level     => $log_level,
	# description   => 'Session Cache',

	# This match clause looks for a packet that contains
	# Acct-Session-Id, NAS-IP-Address and NAS-Port-Id

	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ attr => [
				       'Acct-Session-Id' => qr/./,
				       'NAS-Port-Id'     => qr/./,
				       'NAS-IP-Address'  => qr/./,
				       ],
			      description => 'Cacheable Packet',
			      log_level   => $log_level }), 
			   ],
	set_methods   => [

			  # This makes sure that we store the required
			  # info in our cache.

			  Net::Radius::Server::DBStore->mk
			  ({
			      log_level        => $log_level,
			      result           => NRS_SET_CONTINUE,
			      single           => 1,
			      frozen           => 0,
			      description      => 'Session-DBStore',
			      store            => [qw/_sessions/],
			      pre_store_hook   => \&cache_session,
			      key_attrs        => [
						   'NAS-IP-Address', 
						   '|',
						   'NAS-Port-Id',
						   ],
				  param        => 
				  [ 'MLDBM::Sync' => $db_file ],
			  }),
			  ],
    });

return \@rules;
