#! /usr/bin/perl
#
# Sample rule configuration for Net::Radius::Server
#
# Copyright © 2006, Luis E. Muñoz
#
# This file defines a single rule that uses PAM to authenticate
# remote users
#
# $Id: pam-rule.pl 74 2007-04-21 17:13:14Z lem $
#

use strict;
use warnings;

use Net::Radius::Server::Base qw/:all/;

use Net::Radius::Server::PAM;
use Net::Radius::Server::Rule;
use Net::Radius::Server::Match::Simple;

my $match_acc_req = Net::Radius::Server::Match::Simple->mk
    ({ code => 'Access-Request', description => 'Is Access-Req?' });

my @rules = ();

push @rules, Net::Radius::Server::Rule->new
    ({
	match_methods =>
	    [ 
	      $match_acc_req,
	      Net::Radius::Server::PAM->fmatch
	      ({
		  description => 'pam-auth?',
		  service => 'login',
	      }),
	      ],
	set_methods =>
	    [ Net::Radius::Server::PAM->fset
	      ({
		  description => 'pam-auth',
		  code => 'Access-Accept',
		  auto => 1,
		  attr => [['Reply-Message' => 'Authenticated with PAM']]
		  result => NRS_SET_RESPOND | NRS_SET_CONTINUE,
	      }),
	     ],
    });

\@rules;
