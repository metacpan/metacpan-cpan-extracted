use strict;
use warnings;
use Test::More tests => 25;
use_ok('POE::Filter::HTTP::Parser');

my $filter = POE::Filter::HTTP::Parser->new( type => 'response' );
my $clone = $filter->clone();

my @data = (
"HTTP/1.1 200 OK\x0D\x0A",
"Connection: close\x0D\x0A",
"Date: Wed, 21 Jan 2009 11:24:23 GMT\x0D\x0A",
"Server: Apache\x0D\x0A",
"Content-Length: 204\x0D\x0A",
"Content-Type: text/html; charset=UTF-8\x0D\x0A",
"Content-Type: text/html; charset=iso-8859-1\x0D\x0A",
"Client-Date: Wed, 21 Jan 2009 11:24:23 GMT\x0D\x0A",
"Client-Peer: 62.234.135.115:80\x0D\x0A",
"Client-Response-Num: 1\x0D\x0A",
"\x0D\x0A",
"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n",
"<html>\n",
"    <head>\n",
"        <title>GumbyNet - ORG - UK</title>\n",
"    </head>\n",
"    <body>\n",
"<center><img src=\"images/binnetbut.jpg\"></center>\n",
"    </body>\n",
"</html>\n",
);

foreach my $test ( $filter, $clone ) {
   isa_ok( $test, 'POE::Filter::HTTP::Parser' );
   isa_ok( $test, 'POE::Filter' );

   my $events = $filter->get( [ join( '', @data, @data, @data )  ] );
   ok( scalar @$events == 3, 'Got three responses' );
   foreach my $resp ( @$events ) {
     isa_ok( $resp, 'HTTP::Response' );
     is( $resp->code, '200', 'Response code okay' );
     like( $resp->content, qr/binnetbut.jpg/, 'Content was okay' );
   }
}
