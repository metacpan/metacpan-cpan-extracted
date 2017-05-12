#!/usr/bin/perl -w

use lib "../lib";

use SOAP::Transport::HTTP;
use PICA::SOAPServer;
use PICA::SQLiteStore;

my $dbfile = "/home/voj/svn/picapm/trunk/picawiki/picawiki2.db";
my $store = eval { PICA::SQLiteStore->new($dbfile); } || $@;

# use PICA::Store; proxy
#$store = eval { PICA::Store->new( SOAP => "http://example.com", dbsid => "123", userkey=>"a" ); } || $@;

my $server = PICA::SOAPServer->new( $store );

SOAP::Transport::HTTP::CGI   
  -> serializer( SOAP::Serializer->new->envprefix('soap') )
  -> dispatch_with( { 'http://www.gbv.de/schema/webcat-1.0' => $server } )
  -> handle;


