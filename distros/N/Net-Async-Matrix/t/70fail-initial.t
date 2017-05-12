#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Async::HTTP 0.02; # ->GET

use lib ".";
use t::Util;

use IO::Async::Loop;
use Net::Async::Matrix;

my $ua = Test::Async::HTTP->new;

my $matrix = Net::Async::Matrix->new(
   ua => $ua,
   server => "localserver.test",

   on_error => sub {},
);

IO::Async::Loop->new->add( $matrix );

# Fail the first one
{
   my $login_f = $matrix->login(
      user_id => '@my-test-user:localserver.test',
      access_token => "0123456789ABCDEF",
   );

   my $start_f = $matrix->start;

   my $p = $ua->next_pending;
   $p->fail( "Server doesn't want to", http => undef, $p->request );

   ok( $login_f->is_ready, '->login is ready' );

   # Start is ready but failed
   ok( $start_f->is_ready, '->start is ready' );
   ok( $start_f->failure, '->start failed' );
}

# Second should still be attempted
{
   my $start_f = $matrix->start;

   ok( !$start_f->is_ready, 'Second ->start is not yet ready' );

   my $p = $ua->next_pending;
   ok( $p, 'Second request is made' );

   is( $p->request->uri->path, "/_matrix/client/r0/sync", 'Second request URI' );

   respond_json( $p, {
      next_batch => "next_token_here",
      presence   => {},
      rooms      => {},
   });

   ok( $start_f->is_ready, 'Second ->start is now ready' );
   ok( !$start_f->failure, 'Second ->start did not die' ) or
      diag( "Failure was: ". $start_f->failure );
}

done_testing;
