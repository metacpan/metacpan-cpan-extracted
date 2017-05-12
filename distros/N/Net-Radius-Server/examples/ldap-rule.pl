#! /usr/bin/perl
#
# Sample rule configuration for Net::Radius::Server
#
# Copyright © 2006, Luis E. Muñoz
#
# This file defines a single rule that uses an LDAP bind()
# to authenticate users against an LDAP directory.
#
# $Id: ldap-rule.pl 74 2007-04-21 17:13:14Z lem $
#

use strict;
use warnings;

use Net::Radius::Server::Base qw/:all/;

use Net::Radius::Server::Rule;
use Net::Radius::Server::Set::Simple;
use Net::Radius::Server::Match::LDAP;
use Net::Radius::Server::Match::Simple;

# Clean up the username passed in the RADIUS account
sub ldap_dn_find
{
    my $obj = shift;
    my $r_d = shift;

    my $req = $r_d->{request};
    unless (defined $req)
    {
	warn $obj->description . ": Undefined RADIUS Request\n";
	return;
    }

    my $user = $req->attr('User-Name');

    warn $obj->description . ": User-Name undefined\n"
	unless defined $user;

    $user = lc($user);
    $user =~ s/[^\@-_a-z0-9\.]+//g;
    return $user;
}

my $match_acc_req = Net::Radius::Server::Match::Simple->mk
    ({ code => 'Access-Request', description => 'Is Access-Req?' });

my @rules = ();

push @rules, Net::Radius::Server::Rule->new
    ({
	match_methods =>
	    [ 
	      $match_acc_req,
	      Net::Radius::Server::Match::LDAP->mk
	      ({
 		  ldap_uri => [ qw/ldap/ ],
		  bind_dn => \&ldap_dn_find,
		  authenticate_from => 'User-Password',
		  description => 'ldap-auth?',
	      }),
	      ],
	set_methods =>
	    [ Net::Radius::Server::Set::Simple->mk
	      ({
		  code => 'Access-Accept',
		  auto => 1,
		  result => NRS_SET_RESPOND | NRS_SET_CONTINUE,
		  attr =>
		      [
		       [ 
			 'Reply-Message' => 'Authenticated against LDAP' 
			 ]
		       ],
		     }),
	     ],
    });

\@rules;
