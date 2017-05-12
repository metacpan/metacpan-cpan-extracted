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

# http://jsonapi.org/

my $JSON = JSON::MaybeXS->new->utf8;

# the expected result
my $EXPECTED = $JSON->decode(q[
{
    "jsonapi":{"version":"1.0"},
    "links":{
        "self":"http://example.com/articles",
        "next":"http://example.com/articles?page[offset]=2",
        "last":"http://example.com/articles?page[offset]=10"
    },
    "data":[
        {
            "type":"articles",
            "id":"1",
            "attributes":{
                "title":"JSON API paints my bikeshed!"
            },
            "relationships":{
                "author":{
                    "links":{
                        "self":"http://example.com/articles/1/relationships/author",
                        "related":"http://example.com/articles/1/author"
                    },
                    "data":{
                        "type":"people",
                        "id":"9"
                    },
                    "meta":{
                        "why":"because I can"
                    }
                },
                "comments":{
                    "links":{
                        "self":"http://example.com/articles/1/relationships/comments",
                        "related":"http://example.com/articles/1/comments"
                    },
                    "data":[
                        {
                            "type":"comments",
                            "id":"5"
                        },
                        {
                            "type":"comments",
                            "id":"12"
                        }
                    ]
                }
            },
            "links":{
                "self":"http://example.com/articles/1"
            }
        }
    ],
    "included":[
        {
            "type":"people",
            "id":"9",
            "attributes":{
                "first-name":"Dan",
                "last-name":"Gebhardt",
                "twitter":"dgeb"
            },
            "links":{
                "self":"http://example.com/people/9"
            }
        },
        {
            "type":"comments",
            "id":"5",
            "attributes":{
                "body":"First!"
            },
            "relationships":{
                "author":{
                    "data":{
                        "type":"people",
                        "id":"2"
                    }
                }
            },
            "links":{
                "self":"http://example.com/comments/5"
            }
        },
        {
            "type":"comments",
            "id":"12",
            "attributes":{
                "body":"I like XML better"
            },
            "relationships":{
                "author":{
                    "data":{
                        "type":"people",
                        "id":"9"
                    }
                }
            },
            "links":{
                "self":"http://example.com/comments/12"
            }
        }
    ]
}
]);

# ...

my $doc = PONAPI::Document::Builder::Document->new( version => '1.0', is_collection => 1 )

    -> add_resource( type => 'articles', id => 1 )
       -> add_attribute( title => "JSON API paints my bikeshed!" )

       -> add_relationship ( 'author' => { type => "people", id => 9 } )
           -> add_meta     ( why => "because I can" )
           -> add_links    (
                self    => "http://example.com/articles/1/relationships/author",
                related => "http://example.com/articles/1/author",
              )
           -> parent

       -> add_relationship( 'comments' => [ { type => "comments", id =>  5 },
                                            { type => "comments", id => 12 } ] )
          -> add_links(
               self    => "http://example.com/articles/1/relationships/comments",
               related => "http://example.com/articles/1/comments",
             )
          -> parent

       -> add_link( self => "http://example.com/articles/1" )
       -> parent

    -> add_links(
         self => "http://example.com/articles",
         next => "http://example.com/articles?page[offset]=2",
         last => "http://example.com/articles?page[offset]=10"
       )

    -> add_included        ( type => "people", id => 9 )
       -> add_attributes   ( "first-name" => "Dan", "last-name" => "Gebhardt", "twitter" => "dgeb" )
       -> add_link         ( "self" => "http://example.com/people/9" )
       -> parent

    -> add_included        ( type => "comments", id => 5 )
       -> add_attribute    ( body => "First!" )
       -> add_link         ( self => "http://example.com/comments/5" )
       -> add_relationship ( author => { type => "people", id => 2 } )
          -> parent
       -> parent

    -> add_included        ( type => "comments", id => 12 )
       -> add_attribute    ( body => "I like XML better" )
       -> add_link         ( self => "http://example.com/comments/12" )
       -> add_relationship ( author => { type => "people", id => 9 } )
          ->parent

    -> parent
;

my $GOT = $doc->build;

is_deeply( $GOT, $EXPECTED, '... got the expected result' );

done_testing;
