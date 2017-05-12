use strict;
use warnings;
use Test::More tests => 25;
use_ok('POE::Filter::HTTP::Parser');

my $filter = POE::Filter::HTTP::Parser->new( type => 'request' );
my $clone = $filter->clone();

my @data = (
"GET / HTTP/1.1\x0D\x0A",
"Host: canker.bingosnet.co.uk:6666\x0D\x0A",
"User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.2; en-GB; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5\x0D\x0A",
"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\x0D\x0A",
"Accept-Language: en-gb,en;q=0.5\x0D\x0A",
"Accept-Encoding: gzip,deflate\x0D\x0A",
"Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\x0D\x0A",
"Keep-Alive: 300\x0D\x0A",
"Connection: keep-alive\x0D\x0A\x0D\x0A",
);

foreach my $test ( $filter, $clone ) {
   isa_ok( $test, 'POE::Filter::HTTP::Parser' );
   isa_ok( $test, 'POE::Filter' );

   my $events = $filter->get( [ join( '', @data, @data, @data )  ] );
   ok( scalar @$events == 3, 'Got three requests' );
   foreach my $req ( @$events ) {
     isa_ok( $req, 'HTTP::Request' );
     is( $req->method, 'GET', 'Request method was okay' );
     is( $req->uri->path, '/', 'The URI was okay' );
   }
}
