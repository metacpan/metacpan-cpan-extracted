package t::Util;

use strict;
use warnings;

use Carp;

use Exporter 'import';
our @EXPORT = qw(
   respond_json
   next_pending_not_sync
   next_pending_sync
   send_sync

   matrix_login
   matrix_join_room
);

use HTTP::Response;
use JSON::MaybeXS qw( encode_json );

use constant SYNC_PATH => "/_matrix/client/r0/sync";

sub respond_json
{
   my ( $p, $content ) = @_;

   ref $content or
      croak "respond_json() called with non-reference";

   $p->respond(
      HTTP::Response->new( 200, "OK", [ "Content-Type" => "application/json" ],
         encode_json $content
      )
   );
}

my $sync_p;

sub next_pending_not_sync
{
   my ( $ua ) = @_;

   while(1) {
      my $p = $ua->next_pending or return;
      my $req = $p->request;

      return $p if $req->method ne "GET" or
                   $req->uri->path ne SYNC_PATH;

      die "Received a second /sync request before the first finished" if $sync_p;
      $sync_p = $p;
      $sync_p->response->on_cancel( sub { undef $sync_p } );
   }
}

sub next_pending_sync
{
   my ( $ua ) = @_;

   if( $sync_p ) {
      my $p = $sync_p; undef $sync_p;
      return $p;
   }

   my $p = $ua->next_pending;
   my $req = $p->request;

   return $p if $req->method eq "GET" and
                $req->uri->path eq SYNC_PATH;

   die "Received a different request while waiting for an /sync request";
}

my $next_event_token = 0;

sub send_sync
{
   my ( $ua, %fields ) = @_;

   respond_json( next_pending_sync( $ua ), {
      next_batch => $next_event_token,
      %fields,
   });

   $next_event_token++;
}

sub matrix_login
{
   my ( $matrix, $ua ) = @_;

   my $login_f = $matrix->login(
      user_id => '@my-test-user:localserver.test',
      access_token => "0123456789ABCDEF",
   );

   # respond to initial /sync request
   if( my $p = $ua->next_pending ) {
      respond_json( $p, {
         next_batch => "next_token_here",
         presence   => { events => [] },
         rooms      => {},
      });
   }

   $login_f->get;
}

sub matrix_join_room
{
   my ( $matrix, $ua, @initial_state ) = @_;

   my $join_f = $matrix->join_room( "!room:localserver.test" );

   my $p = next_pending_not_sync( $ua );
   respond_json( $p, { room_id => "!room:localserver.test" } );

   # Server sends new room initial state in the next /sync response
   send_sync( $ua,
      rooms => {
         join => {
            "!room:localserver.test" => {
               timeline => {},
               state => {
                  events => [ @initial_state ],
               },
            },
         },
      },
   );

   return $join_f->get;
}

0x55AA;
