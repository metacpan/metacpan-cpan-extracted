#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET

use lib ".";
use t::Util;

use IO::Async::Loop;
use Net::Async::Matrix;
use Future;

my $matrix = Net::Async::Matrix->new(
   ua => my $ua = Test::Async::HTTP->new,
   server => "localserver.test",

   make_delay => sub { Future->new },
);

IO::Async::Loop->new->add( $matrix ); # for ->loop->new_future
matrix_login( $matrix, $ua );

# ->upload
{
   my $f = $matrix->upload(
      content      => "Here is the content",
      content_type => "text/plain",
   );

   ok( my $p = next_pending_not_sync( $ua ), '->upload sends an HTTP request' );

   is( $p->request->method, "POST", '$req->method' );
   my $uri = $p->request->uri;
   is( $uri->authority, "localserver.test", '$req->uri->authority' );
   is( $uri->path,      "/_matrix/media/v1/upload", '$req->uri->path' );

   is( $p->request->content_type, "text/plain", '$req->content_type' );
   is( $p->request->content, "Here is the content" , '$req->content' );

   respond_json( $p, { content_uri => "mxc://localserver.test/abcd1234" } );

   ok( $f->is_ready, '$f now ready after /upload response' );
   is( $f->get, "mxc://localserver.test/abcd1234", '$f->get returns content URI' );
}

# ->convert_mxc_url
{
   is( $matrix->convert_mxc_url( "mxc://localserver.test/abcd1234" ) . "",
       "http://localserver.test/_matrix/media/v1/download/localserver.test/abcd1234",
       '$matrix->convert_mxc_url'
   );
}

done_testing;
