#! /usr/bin/perl
#
# This is an example on a simplistic method to calculate the traffic
# delta for a given session, based on the RADIUS Accounting
# packets. The calculation is performed via a database accessed using
# Net::Radius::Server::DBStore, tied to a persistent backing store.
#
# The traffic reported by the Accouting-Request packets is left in two
# tuples of the RADIUS transaction context, for the enjoyment of later
# rules that may use this information.
#
# Copyright © 2009, Luis E. Muñoz - All Rights Reserved
#
# $Id: traffic-delta.pl 111 2009-10-17 23:21:40Z lem $

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

my @rules         = ();
my $db_file       = catfile($ENV{HOME}, 'radius-traffic-cache.db');
my $log_level     = 1;

# Obtain the actual number of octets in and out of a given session,
# and prepare it for storage in the database.

sub traffic_calc
{
    my ($dbstore, $hobj, $r_hash, $r_data, $req, $key) = @_;

    $r_data->{_traffic} = $r_hash->{$key}->{_traffic} || {};
    
    # Calculate precisely how much traffic have we accounted in this
    # interface
    $r_data->{_traffic}->{_in} = 
	(($req->attr('Acct-Input-Gigawords') || 0) * 2 ** 32) +
	($req->attr('Acct-Input-String') || 0);

    $r_data->{_traffic}->{_out} = 
	(($req->attr('Acct-Output-Gigawords') || 0) * 2 ** 32) + 
	($req->attr('Acct-Output-String') || 0);
    
    $r_data->{_traffic}->{_type} = ($req->attr('Acct-Status-Type') || '');
    $r_data->{_traffic}->{_stamp} = time;

    $dbstore->log(4, "Traffic in=" . $r_data->{_traffic}->{_in} . 
		  ", out=" . $r_data->{_traffic}->{_out});
}

# CAVEAT: This code assumes that Accounting-Request packets will be
# responded to. Otherwise, you may end up counting the same traffic
# over and over, until the accounting is acknowledged.

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level     => $log_level,
	# description   => 'Traffic Delta',

	# This match clause looks for a packet that contains
	# Acct-Session-Id, NAS-IP-Address and basic traffic accounting
	# data that we can work with

	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ code => 'Accounting-Request',
			      attr => [
				       'NAS-IP-Address'     => qr/./,
				       'Acct-Session-Id'    => qr/./,
				       'Acct-Input-String'  => qr/^\d+$/,
				       'Acct-Output-String' => qr/^\d+$/,
				       ],
			      description => 'Acct-Traffic',
			      log_level   => $log_level }), 
			   ],
	set_methods   => [

			  # This makes sure that we store the required
			  # info in our database.

			  Net::Radius::Server::DBStore->mk
			  ({
			      log_level        => $log_level,
			      result           => NRS_SET_CONTINUE,
			      single           => 1,
			      frozen           => 0,
			      description      => 'Traffic-DBStore',
			      store            => [qw/_traffic/],
			      pre_store_hook   => \&traffic_calc,
			      key_attrs        => [
						   'NAS-IP-Address', 
						   '|',
						   'Acct-Session-Id',
						   ],
				  param        => 
				  [ 'MLDBM::Sync' => $db_file ],
			  }),
			  ],
    });

return \@rules;

