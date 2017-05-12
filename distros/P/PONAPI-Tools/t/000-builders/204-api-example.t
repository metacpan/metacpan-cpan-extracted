#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use Plack::Request;
use JSON::MaybeXS;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

# http://jsonapi.org/examples/#pagination

my $JSON = JSON::MaybeXS->new->utf8;

# the expected result
my $EXPECTED = $JSON->decode(q[
{
    "jsonapi":{"version":"1.0"},
    "meta":{
        "total-pages":13
    },
    "data":[
        {
            "type":"articles",
            "id":"3",
            "attributes":{
                "title":"JSON API paints my bikeshed!",
                "body":"The shortest article. Ever.",
                "created":"2015-05-22T14:56:29.000Z",
                "updated":"2015-05-22T14:56:28.000Z"
            }
        }
    ],
    "links":{
        "self":"http://example.com/articles?page[number]=3&page[size]=1",
        "first":"http://example.com/articles?page[number]=1&page[size]=1",
        "prev":"http://example.com/articles?page[number]=2&page[size]=1",
        "next":"http://example.com/articles?page[number]=4&page[size]=1",
        "last":"http://example.com/articles?page[number]=13&page[size]=1"
    }
}
]);

# ...

my $doc = PONAPI::Document::Builder::Document->new( version => '1.0', is_collection => 1 )

    -> add_meta ( "total-pages" => 13 )

    -> add_resource( type => 'articles', id => 3 )
       -> add_attributes(
              title   => "JSON API paints my bikeshed!",
              body    => "The shortest article. Ever.",
              created => "2015-05-22T14:56:29.000Z",
              updated => "2015-05-22T14:56:28.000Z",
          )
       -> parent

    -> add_links(
           self  => "http://example.com/articles?page[number]=3&page[size]=1",
           first => "http://example.com/articles?page[number]=1&page[size]=1",
           prev  => "http://example.com/articles?page[number]=2&page[size]=1",
           next  => "http://example.com/articles?page[number]=4&page[size]=1",
           last  => "http://example.com/articles?page[number]=13&page[size]=1",
       )
;

my $GOT = $doc->build;

is_deeply( $GOT, $EXPECTED, '... got the expected result' );

done_testing;
