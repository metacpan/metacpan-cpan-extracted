#!/usr/bin/perl
#
# AUTHOR : Colin Faber <cfaber at fpsn.net>
#
# 
# Copyright (C) 1998/2005 FPSN.NET Development, Inc. all
# rights reserved.
#
# This file may be used and modified under the terms of
# the Perl Artistic License.
# 
# Check for the latest versions of this software at:
#                   http://www.fpsn.net
#
#
# Should you wish to receive commercial support on this
# product please visit http://www.fpsn.net and request
# commercial support for Net::Whois::Proxy
# 
# Net::Whois::Proxy test program / whois
#

use Net::Whois::Proxy;
use Getopt::Simple;
use strict;
use vars qw($self $version);

$self  = (split(/[\\\/]+/, $0))[-1];

$version = '$Id: whois.pl,v 1.4 2005/05/22 01:55:14 cfaber Exp $';

if(!@ARGV){
	print " whois.pl version $version by Colin Faber <cfaber\@fpsn.net>\r\n\tUsage: $self <what ever>\r\n\r\n";
	exit(64);
} else {
	my ($title, $body, $in);

	my $whois = Net::Whois::Proxy->new(debug => 1, stacked_results => 1, clean_stack => 1);

	my $body = $whois->whois( join(' ', @ARGV) );

	if(!$body){
		$body = $whois->errstr;
	}

	print $body . "\r\n";
	exit(0);
}


