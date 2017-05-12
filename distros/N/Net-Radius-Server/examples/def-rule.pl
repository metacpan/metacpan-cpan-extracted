#! /usr/bin/perl
#
# Sample rule configuration for Net::Radius::Server, including
# packet dumping on flat files.
#
# Copyright © 2006-2009, Luis E. Muñoz
#
# This file defines a single rule that simply matches common
# requests with positive acknowledgements, for simple testing.
#
# $Id: def-rule.pl 108 2009-10-17 02:48:38Z lem $
#
# DO NOT USE THIS EXAMPLE IN PRODUCTION - NO CREDENTIAL CHECKS ARE DONE
# Also, the request/response dumping will consume vey significant amounts
# of disk space.

use strict;
use warnings;

use BerkeleyDB;
use File::Spec::Functions;
use Net::Radius::Server::Rule;
use Net::Radius::Server::Dump;
use Net::Radius::Server::DBStore;
use Net::Radius::Server::Base qw/:all/;
use Net::Radius::Server::Set::Simple;
use Net::Radius::Server::Match::Simple;

my @rules = ();
my $dump_location = catdir($ENV{HOME}, 'packet-dumps');
my $db_file       = catdir($ENV{HOME}, 'radius-accounting.db');

# Note that in this example file, log_level is used in many places to
# show where it could be used. Normally, you would not need it unless
# troubleshooting specific issues. Also, you can ask for different
# logging levels at different places...

my $log_level = 1;

# This is an example about how to include per-child initialization
# code. You may want to do this to setup database connections. This
# code could also be stowed away within a specific class for your
# environment.

{
    no warnings 'redefine';
    sub Net::Radius::Server::NS::child_init_hook
    {
	my $self = shift;
	$self->log(0, "*** child_init_hook() called!\n");
    }
};

# The following two rules show how to use ::Simple packet matching
# code to restrict actions to specific types of packets. Rules can be
# arranged in a single list, and the packet matching code makes sure
# the appropiate set methods are invoked only when required.

# Simple rule: Match Access-Request, return Access-Accept. No verification.
push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	# See if the packet is an Access-Request...
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ code        => 'Access-Request', 
			      description => 'Access-Packet',
			      log_level   => $log_level }), 
			   ],
	set_methods => [
			# Prepare an Access-Accept as response, which will
			# grant access to whatever was requested by the
			# NAS.
			Net::Radius::Server::Set::Simple->mk
			({
			    log_level => $log_level,
			    auto      => 1,
			    code      => 'Access-Accept',
			    result    => NRS_SET_CONTINUE,
			}),

			# With the following lines uncommented, a new
			# BerkeleyDB hash database will be created at
			# $db_file. The contents of Accounting-Request
			# packets will be stored there for later
			# analysis.
			Net::Radius::Server::DBStore->mk
			({
			    log_level   => 4,
			    sync        => 1,
			    description => 'Access-DBStore',
			    param       => [
					    'BerkeleyDB::Hash',
					    -Filename => $db_file,
					    -Flags    => DB_CREATE ],
			    result      => NRS_SET_CONTINUE,
			}),

			# If the following lines are uncommented, log the
			# request and the response just before signing and
			# sending it
		        Net::Radius::Server::Dump->mk
			({
			    basepath  => $dump_location,
			    basename  => 'access-',
			    result    => NRS_SET_CONTINUE | NRS_SET_RESPOND,
			    log_level => $log_level,
			}),
			],
    });

# Match Accounting-Requests with an Accounting-Response
push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	# See if the packet is an Accounting-Request...
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ code        => 'Accounting-Request', 
			       description => 'Acct-Packet',
			       log_level   => $log_level }), 
			   ],
	set_methods => [
			# Return an Accounting-Response, noting that
			# we received the packet from the NAS
			Net::Radius::Server::Set::Simple->mk
			({
			    log_level => $log_level,
			    auto      => 1,
			    code      => 'Accounting-Response',
			    result    => NRS_SET_CONTINUE,
			}),
			# If the following lines are uncommented, log the
			# request and the response just before signing and
			# sending it
		        Net::Radius::Server::Dump->mk
			({
			    basepath  => $dump_location,
			    basename  => 'acct-',
			    result    => NRS_SET_CONTINUE | NRS_SET_RESPOND,
			    log_level => $log_level,
			}),
			],
    });

# Match a Disconnect-Request with a Disconnect Response. Note that
# this flow is backwards, as normally the -Request is sent _from_ the
# server and the - Response is sent from the NAS.

# This shows how to use ::Simple to match packets with specific
# attributes in them, which is useful to implement special cases.

# If the request includes Service-Type => Authorize-Only, we are
# required to return an Disconnect-NAK first, and then start a new
# authorization. We will only respond the NAK...

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ code        => 'Disconnect-Request', 
			      description => 'Disconnect-Request',
			      log_level   => $log_level,
			      attr        => 
				  [
				   'Service-Type' => 'Authorize-Only',
				   ],
			      }), 
			   ],
        set_methods => [
			Net::Radius::Server::Set::Simple->mk
			({
			    log_level => $log_level,
			    auto      => 1,
			    code      => 'Disconnect-NAK',
			    result    => NRS_SET_RESPOND,
			}),
			],
    });

# ... Otherwise, we will simply return a Disconnect-ACK. Note that
# this rule must come after the prior one.

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ({ code        => 'Disconnect-Request', 
			      description => 'Disconnect-Request',
			      log_level   => $log_level }), 
			   ],
        set_methods => [ Net::Radius::Server::Set::Simple->mk
			 ({
			     log_level => $log_level,
			     auto      => 1,
			     code      => 'Disconnect-ACK',
			     result    => NRS_SET_CONTINUE | NRS_SET_RESPOND,
			 }),
			 ],
    });

# Match a CoA-Request with a CoA Response. Note that
# this flow is backwards, as normally the -Request is sent _from_ the
# server and the - Response is sent from the NAS.

# This shows how to use ::Simple to match packets with specific
# attributes in them, which is useful to implement special cases.

# If the request includes Service-Type => Authorize-Only, we are
# required to return an CoA-NAK first, and then start a new
# authorization. We will only respond the NAK...

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ( { code        => 'CoA-Request', 
			       description => 'CoA-Request',
			       log_level   => $log_level,
			       attr        => 
				   [
				    'Service-Type' => 'Authorize-Only',
				    ],
			   }), 
			   ],
	set_methods => [
			Net::Radius::Server::Set::Simple->mk
			({
			    log_level => $log_level,
			    auto      => 1,
			    code      => 'CoA-NAK',
			    result    => NRS_SET_RESPOND,
			}),
			],
    });

# ... Otherwise, we will simply return a CoA-ACK. Note that
# this rule must come after the prior one.

push @rules, Net::Radius::Server::Rule->new
    ({
	log_level => $log_level,
	match_methods => [ Net::Radius::Server::Match::Simple->mk
			   ( { code        => 'CoA-Request', 
			       description => 'CoA-Request',
			       log_level   => $log_level,
			   }), 
			   ],
	set_methods => [
			Net::Radius::Server::Set::Simple->mk
			({
			    log_level => $log_level,
			    auto      => 1,
			    code      => 'CoA-ACK',
			    result    => NRS_SET_CONTINUE | NRS_SET_RESPOND,
			}),
			],
    });

# Return the rule set

\@rules;
