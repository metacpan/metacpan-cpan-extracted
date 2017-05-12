#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document');
}

my $EXPECTED = {
    jsonapi => { version => '1.0' },
    "data" => [
        {
           "type"          => "articles",
           "id"            => "1",
           "attributes"    => { "title" => "JSON API paints my bikeshed!" },
           "links"         => { "self" => "http://example.com/articles/1" },
           "relationships" => {
               "author" => {
                   "links" => {
                       "self" => "http://example.com/articles/1/relationships/author",
                       "related" => "http://example.com/articles/1/author"
                   },
                   "data" => { "type" => "people", "id" => "9" }
               },
               "comments" => {
                   "links" => {
                       "self" => "http://example.com/articles/1/relationships/comments",
                       "related" => "http://example.com/articles/1/comments"
                   },
                   "data" => [
                       { "type" => "comments", "id" => "5" },
                       { "type" => "comments", "id" => "12" }
                   ]
               }
           }
        }
    ],
    "included" => [
        {
            "type"       => "people",
            "id"         => "9",
            "attributes" => {
                "first-name" => "Dan",
                "last-name"  => "Gebhardt",
                "twitter"    => "dgeb"
            },
            "links" =>
                { "self" => "http://example.com/people/9" }
            },
        {
            "type"          => "comments",
            "id"            => "5",
            "attributes"    => { "body" => "First!" },
            "relationships" => {
                "author" => {
                    "data"   => { "type" => "people", "id" => "2" }
                }
            },
            "links" =>
                { "self" => "http://example.com/comments/5" }
        },
        {
            "type"          => "comments",
            "id"            => "12",
            "attributes"    => { "body" => "I like XML better" },
            "relationships" => {
                "author" => {
                    "data" => { "type" => "people", "id" => "9" }
                }
            },
            "links" =>
                { "self" => "http://example.com/comments/12" }
        }
    ]
};



my $builder = PONAPI::Document::Builder::Document
    ->new( version => '1.0', is_collection => 1 )
        ->add_resource( type => 'articles', id => 1 )
            ->add_attribute( "title" => "JSON API paints my bikeshed!" )
            ->add_links( "self" => "http://example.com/articles/1" )
            ->add_relationship(
                    author => { type => "people", id => "9"}
                )->add_links(
                    self    => "http://example.com/articles/1/relationships/author",
                    related => "http://example.com/articles/1/author",
                )->parent
            ->add_relationship(
                    comments => [
                        { type => "comments", id => "5" },
                        { type => "comments", id => "12" },
                    ]
                )->add_links(
                    self    => "http://example.com/articles/1/relationships/comments",
                    related => "http://example.com/articles/1/comments",
                )->parent
        ->parent
    ->add_included( type => 'people', id => 9 )
        ->add_attributes(
            "first-name" => "Dan",
            "last-name"  => "Gebhardt",
            "twitter"    => "dgeb"
        )
        ->add_links(self => "http://example.com/people/9" )
    ->parent
    ->add_included( type => 'comments', id => 5 )
        ->add_attribute( "body" => "First!" )
        ->add_links( self => "http://example.com/comments/5" )
        ->add_relationship(
            author => { type => 'people', id => 2 }
        )->parent
    ->parent
    ->add_included( type => 'comments', id => 12 )
        ->add_attribute( "body" => "I like XML better" )
        ->add_links( self => "http://example.com/comments/12" )
        ->add_relationship(
            author => { type => 'people', id => 9 }
        )->parent
    ->parent
;

my $GOT = $builder->build;

is_deeply( $GOT, $EXPECTED, '... got the expected result' );

done_testing;
