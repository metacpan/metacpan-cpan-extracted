#! /usr/bin/perl
#
# Sample rule configuration for Net::Radius::Server
#
# Copyright © 2006, Luis E. Muñoz
#
# This example combines simple and LDAP matches to verify users that
# exist within your LDAP server and proxy only those users to an
# existing RADIUS server
#
# $Id: rules.pl 74 2007-04-21 17:13:14Z lem $
#

use strict;
use warnings;

use Net::Radius::Server::Base qw/:all/;

use Net::Radius::Server::Rule;
use Net::Radius::Server::Set::Proxy;
use Net::Radius::Server::Match::LDAP;
use Net::Radius::Server::Match::Simple;

sub ldap_attr_match
{
    my $obj = shift;
    my $r_d = shift;

    my $req = $r_d->{request};
    unless (defined $req)
    {
	$obj->log(2, "Undefined RADIUS Request");
	return;
    }

    my $user = $req->attr('User-Name');

    $obj->log(2, "User-Name undefined")
	unless defined $user;

    # Sanitize the user name
    $user = lc($user);
    $user =~ s/\@.+$//;
    $user =~ s/[^-_a-z0-9\.]+//g;

    '(sAMAccountName=' . $user . ')';
}

[ Net::Radius::Server::Rule->new
  ({
      match_methods => [ Net::Radius::Server::Match::Simple->mk
			 ({ code => 'Access-Request', log_level => 4 }),
			 Net::Radius::Server::Match::LDAP->mk
			 ({
			     log_level => 4,
			     ldap_uri => [ server1 server2 ],
			     bind_dn => 'YourSpecialUser',
			     bind_opts => [ password => 'YourPassword' ],
			     search_opts => 
				 [
				  base => 'ou=data,dc=...',
				  scope => 'sub',
				  attrs => [ qw/sAMAccountName/ ],
				  _nrs_filter => \&ldap_attr_match,
				  ],
			     }),
			 ],
       set_methods => [
		       Net::Radius::Server::Set::Proxy->mk
		       ({
			   log_level => 4,
			   server => $radius,
			   secret => $yoursecret,
			   port => '1645',
			   result => NRS_SET_RESPOND | NRS_SET_CONTINUE,
			   debug => 0,
		       }),
		       ],
  })];
