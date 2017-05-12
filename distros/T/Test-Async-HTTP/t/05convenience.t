#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Async::HTTP;

use HTTP::Response;

my $http = Test::Async::HTTP->new;

# ->GET wrapper
{
   my $f = $http->GET( "http://my.server/also" );

   ok( my $p = $http->next_pending, '->next_pending after ->GET' );

   is( $p->request->uri, "http://my.server/also", '$p->request->uri' );

   $p->respond( HTTP::Response->new( 200, "OK", [], "Hello, again" ) );

   ok( $f->is_ready, '$f is now ready' );
   is( $f->get->content, "Hello, again", '$f->get->content is the response' );
}

# ->PUT wrapper
{
   my $f = $http->PUT( "http://my.server/new", "some content" );

   ok( my $p = $http->next_pending, '->next_pending after ->PUT' );

   is( $p->request->uri, "http://my.server/new", '$p->request->uri' );
   is( $p->request->content, "some content",     '$p->request->content' );

   $p->respond( HTTP::Response->new( 201, "Created", [], "" ) );

   is( $f->get->code, 201, '$f->get->code' );
}

done_testing;
