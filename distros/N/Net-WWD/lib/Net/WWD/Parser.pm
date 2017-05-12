package Net::WWD::Parser;

#############################################
# WWD File parser for integration with Apache
# (C) Copyright 2001-2005 John Baleshiski
# All rights reserved.
#############################################

use warnings;
use CGI qw(:standard escapeHTML);
use HTTP::Request;
use LWP::UserAgent;
use HTTP::Headers;
use CGI::Carp "fatalsToBrowser";
use Apache::RequestRec ();
use Apache::RequestIO ();
use Data::Dumper;
use Apache::Const -compile => qw(OK);
use Time::Local;
use Net::WWD::Functions;
use Net::WWD::ParserEngine;

my $DEBUG = 0;

sub handler {
	my $r = shift;
	%params = ();
	$r->content_type('text/html');
	my $req = $ENV{'REQUEST_URI'};
	if($req =~ /\?/) { $req = $'; } else { $req = ""; }
	my @p = split(/&/, $req);
	$params{'t'} = "";
	$params{'o'} = "";
	$params{'p'} = "";
	$params{'v'} = "";
	$params{'a'} = "";
	$params{'tp'} = "";
	$params{'rp'} = "";
	$params{'mp'} = "";
	$params{'ttl'} = "";
	$params{'ac'} = "";
	for(my $i=0; $i<@p; $i++) {
		my ($s, $t) = split(/=/, $p[$i]);
		$params{$s} = $t;
	}

	print Net::WWD::ParserEngine::processWWDFile($ENV{'SCRIPT_FILENAME'}, $ENV{'SERVER_NAME'});
	return Apache::OK;
}

1;
