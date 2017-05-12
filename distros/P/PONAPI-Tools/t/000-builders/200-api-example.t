#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document')
}

use JSON::MaybeXS;

my $JSON = JSON::MaybeXS->new->utf8;

my $EXPECTED = $JSON->decode(q[
{
    "jsonapi":{"version":"1.0"},
    "data":{
        "type":"articles",
        "id":"1",
        "attributes":{
            "title":"Rails is Omakase",
            "body":"WHAT?!?!?!"
        },
        "relationships":{
            "author":{
                "links":{
                    "self":"/articles/1/relationships/author",
                    "related":"/articles/1/author"
                },
                "data":{
                    "type":"people",
                    "id":"9"
                }
            },
            "comments":{
                    "links":{
                        "self":"/articles/1/relationships/comments",
                        "related":"/articles/1/comments"
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
        }
    },
    "included":[
        {
            "type":"people",
            "id":"9",
            "attributes":{
                "name":"DHH"
            },
            "links":{
                "self":"/people/9"
            }
        }
    ]
}
]);

my $GOT = PONAPI::Document::Builder::Document
    ->new( version => '1.0' )
        ->add_resource( id => 1, type => 'articles' )
            ->add_attributes(
                title => 'Rails is Omakase',
                body  => 'WHAT?!?!?!'
            )
            ->add_relationship( 'author' => { id => 9, type => 'people' } )
                ->add_links(
                    self    => '/articles/1/relationships/author',
                    related => '/articles/1/author'
                )
            ->parent
            ->add_relationship( 'comments' => [
                    { id => 5, type => 'comments' },
                    { id => 12, type => 'comments' },
                ])
                ->add_links(
                    self    => '/articles/1/relationships/comments',
                    related => '/articles/1/comments'
                )
            ->parent
        ->parent
        ->add_included( id => 9, type => 'people' )
            ->add_attributes( name => 'DHH' )
            ->add_link( self => '/people/9' )
        ->parent
    ->build
;

is_deeply( $GOT, $EXPECTED, '... got the expected result' );

## ----------------------------------------------------------------------------

done_testing;
