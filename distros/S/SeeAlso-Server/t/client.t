#!perl -Tw

use strict;
use Test::More qw(no_plan);;

require_ok("SeeAlso::Client");
require_ok("URI");

my $c = SeeAlso::Client->new("http://example.com");
isa_ok( $c, "SeeAlso::Client", "new");

eval { $c = SeeAlso::Client->new("no-url"); };
ok( $@, "new with invalid URL");

$c = SeeAlso::Client->new( ShortName => "example", BaseURL => "http://example.com" );
is( $c->description("BaseURL"), "http://example.com/", "baseURL as description" );
is( $c->description("ShortName"), "example", "additional description" );

$c = SeeAlso::Client->new( BaseURL => URI->new("http://example.com") );
is( $c->description("BaseURL"), "http://example.com/", "baseURL as URI in description" );

$c = SeeAlso::Client->new("http://example.com?foo=bar");
is( $c->baseURL, "http://example.com?foo=bar", "baseURL" );
my $url = $c->queryURL('+%');
ok( $url =~ /id=%2B%25/ && $url =~ /format=seealso/, "queryURL" );

my $uri = URI->new( $c->queryURL('+%') );
my %q = $uri->query_form();
is( (scalar keys %q), 3, "queryURL" );
is( $q{id}, '+%', "queryURL" );

# don't croak
is( SeeAlso::Client::seealso_request("no-url", 123), undef, "seealso_request does not croak");

# TODO: more tests:
# - callback parameter
# - use at SeeAlso::Source
# - query a server

