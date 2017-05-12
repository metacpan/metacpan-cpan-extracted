#!/usr/bin/env perl

$|=1;

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Reflexive::Client::HTTP;
use HTTP::Request;

my $ua = Reflexive::Client::HTTP->new;

$ua->request( HTTP::Request->new( GET => "http://duckduckgo.com/" ), sub {
	print "DuckDuckGo gave me ".$_->code."\n";
	return HTTP::Request->new( GET => "http://perl.org/" ), sub {
		print "Perl gave me ".$_->code."\n";
		return HTTP::Request->new( GET => "http://metacpan.org/" ), sub {
			print "MetaCPAN gave me ".$_->code."\n";
		};
	};
});

Reflex->run_all();

exit;
