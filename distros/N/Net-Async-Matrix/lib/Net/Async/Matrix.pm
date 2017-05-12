#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2017 -- leonerd@leonerd.org.uk

package Net::Async::Matrix;

use strict;
use warnings;

use base qw( IO::Async::Notifier );
IO::Async::Notifier->VERSION( '0.63' ); # adopt_future

our $VERSION = '0.19';
$VERSION = eval $VERSION;

use Carp;

use Future;
use Future::Utils qw( repeat );
use JSON::MaybeXS qw( encode_json decode_json );

use Data::Dump 'pp';
use File::stat;
use List::Util 1.29 qw( pairmap );
use Scalar::Util qw( blessed );
use Struct::Dumb;
use Time::HiRes qw( time );
use URI;

struct User => [qw( user_id displayname presence last_active )];

use Net::Async::Matrix::Room;

use constant PATH_PREFIX => "/_matrix/client/r0";
use constant LONGPOLL_TIMEOUT => 30;

# This is only needed for the (undocumented) recaptcha bypass feature
use constant HAVE_DIGEST_HMAC_SHA1 => eval { require Digest::HMAC_SHA1; };

=head1 NAME

C<Net::Async::Matrix> - use Matrix with L<IO::Async>

=head1 SYNOPSIS

 use Net::Async::Matrix;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $matrix = Net::Async::Matrix->new(
    server => "my.home.server",
 );

 $loop->add( $matrix );

 $matrix->login(
    user_id  => '@my-user:home.server',
    password => 'SeKr1t',
 )->get;

=head1 DESCRIPTION

F<Matrix> is an new open standard for interoperable Instant Messaging and VoIP,
providing pragmatic HTTP APIs and open source reference implementations for
creating and running your own real-time communication infrastructure.

This module allows an program to interact with a Matrix homeserver as a
connected user client.

L<http://matrix.org/>

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or C<CODE>
references in parameters:

=head2 on_log $message

A request to write a debugging log message. This is provided temporarily for
development and debugging purposes, but will at some point be removed when the
code has reached a certain level of stability.

=head2 on_presence $user, %changes

Invoked on receipt of a user presence change event from the homeserver.
C<%changes> will map user state field names to 2-element ARRAY references,
each containing the old and new values of that field.

=head2 on_room_new $room

Invoked when a new room first becomes known about.

Passed an instance of L<Net::Async::Matrix::Room>.

=head2 on_room_del $room

Invoked when the user has now left a room.

=head2 on_invite $event

Invoked on receipt of a room invite. The C<$event> will contain the plain
Matrix event as received; with at least the keys C<inviter> and C<room_id>.

=head2 on_unknown_event $event

Invoked on receipt of any sort of event from the event stream, that is not
recognised by any of the other code. This can be used to handle new kinds of
incoming events.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>. In
addition, C<CODE> references for event handlers using the event names listed
above can also be given.

=head2 server => STRING

Hostname and port number to contact the homeserver at. Given in the form

 $hostname:$port

This string will be interpolated directly into HTTP request URLs.

=head2 SSL => BOOL

Whether to use SSL/TLS to communicate with the homeserver. Defaults false.

=head2 SSL_* => ...

Any other parameters whose names begin C<SSL_> will be stored for passing to
the HTTP user agent. See L<IO::Socket::SSL> for more detail.

=head2 path_prefix => STRING

Optional. Gives the path prefix to find the Matrix client API at. Normally
this should not need modification.

=head2 on_room_member, on_room_message => CODE

Optional. Sets default event handlers on new room objects.

=head2 enable_events => BOOL

Optional. Normally enabled, but if set to a defined-but-false value (i.e. 0 or
empty string) the event stream will be disabled. This will cause none of the
incoming event handlers to be invoked, because the server will not be polled
for events.

This may be useful in simple send-only cases where the client has no interest
in receiveing any events, and wishes to reduce the load on the homeserver.

=head2 longpoll_timeout => NUM

Optional. Timeout in seconds for the C</events> longpoll operation. Defaults
to 30 seconds if not supplied.

=head2 first_sync_limit => NUM

Optional. Number of events per room to fetch on the first C</sync> request on
startup. Defaults to the server's builtin value if not defined, which is
likely to be 10.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $self->SUPER::_init( $params );

   $params->{ua} ||= do {
      require Net::Async::HTTP;
      Net::Async::HTTP->VERSION( '0.36' ); # SSL params
      my $ua = Net::Async::HTTP->new(
         fail_on_error => 1,
         max_connections_per_host => 3, # allow 2 longpolls + 1 actual command
         user_agent => __PACKAGE__,
         pipeline => 0,
      );
      $self->add_child( $ua );
      $ua
   };

   # Injectable for unit tests, other event systems, etc..
   # For now undocumented while I try to work out the wider design issues
   $self->{make_delay} = delete $params->{make_delay} || $self->_capture_weakself( sub {
      my ( $self, $secs ) = @_;
      $self->loop->delay_future( after => $secs );
   } );

   $self->{msgid_next} = 0;

   $self->{users_by_id} = {};
   $self->{rooms_by_id} = {};

   $self->{path_prefix} = PATH_PREFIX;

   $self->{longpoll_timeout} = LONGPOLL_TIMEOUT;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( server path_prefix ua SSL enable_events longpoll_timeout
                first_sync_limit
                on_log on_unknown_event on_presence on_room_new on_room_del on_invite
                on_room_member on_room_message )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   my $ua = $self->{ua};
   foreach ( grep { m/^SSL_/ } keys %params ) {
      $ua->configure( $_ => delete $params{$_} );
   }

   $self->SUPER::configure( %params );
}

sub log
{
   my $self = shift;
   my ( $message ) = @_;

   $self->{on_log}->( $message ) if $self->{on_log};
}

sub _maybe_encode
{
   my $v = shift;
   return $v if !ref $v or blessed $v;
   return $v if ref $v ne "HASH";
   return encode_json( $v );
}

sub _uri_for_path
{
   my $self = shift;
   my ( $path, %params ) = @_;

   $path = "/$path" unless $path =~ m{^/};

   my $uri = URI->new;
   $uri->scheme( $self->{SSL} ? "https" : "http" );
   $uri->authority( $self->{server} );
   $uri->path( $self->{path_prefix} . $path );

   $params{access_token} = $self->{access_token} if defined $self->{access_token};

   # Some parameter values can be JSON-encoded objects
   $uri->query_form( pairmap { $a => _maybe_encode $b } %params );

   return $uri;
}

sub _do_GET_json
{
   my $self = shift;
   my ( $path, %params ) = @_;

   $self->{ua}->GET( $self->_uri_for_path( $path, %params ) )->then( sub {
      my ( $response ) = @_;

      $response->content_type eq "application/json" or
         return Future->fail( "Expected application/json response", matrix => );

      Future->done( decode_json( $response->content ), $response );
   });
}

sub _do_send_json
{
   my $self = shift;
   my ( $method, $path, $content ) = @_;

   my $req = HTTP::Request->new( $method, $self->_uri_for_path( $path ) );
   $req->content( encode_json( $content ) );
   $req->header( Content_length => length $req->content ); # ugh

   $req->header( Content_type => "application/json" );

   my $f = $self->{ua}->do_request(
      request => $req,
   )->then( sub {
      my ( $response ) = @_;

      $response->content_type eq "application/json" or
         return Future->fail( "Expected application/json response", matrix => );

      my $content = $response->content;
      if( length $content and $content ne q("") ) {
         eval {
            $content = decode_json( $content );
            1;
         } or
            return Future->fail( "Unable to parse JSON response $content" );
         return Future->done( $content, $response );
      }
      else {
         # server yields empty strings sometimes... :/
         return Future->done( undef, $response );
      }
   });

   return $self->adopt_future( $f );
}

sub _do_PUT_json  { shift->_do_send_json( PUT  => @_ ) }
sub _do_POST_json { shift->_do_send_json( POST => @_ ) }

sub _do_DELETE
{
   my $self = shift;
   my ( $path, %params ) = @_;

   $self->{ua}->do_request(
      method => "DELETE",
      uri    => $self->_uri_for_path( $path, %params ),
   );
}

sub _do_POST_file
{
   my $self = shift;
   my ( $path, %params ) = @_;

   my $uri = $self->_uri_for_path( "" );
   $uri->path( "/_matrix" . $path );

   my $req = HTTP::Request->new( "POST" , $uri );
   $req->header( Content_type => $params{content_type} );

   my $body;

   if( defined $params{content} ) {
      $req->content( $params{content} );
      $req->header( Content_length => length $req->content );
   }
   elsif( defined $params{file} or defined $params{fh} ) {
      my $fh = $params{fh};
      $fh or open $fh, "<", $params{file} or
         return Future->fail( "Cannot read $params{file} - $!", open => );

      $body = sub {
         $fh->read( my $buffer, 65536 ) or return undef;
         return $buffer;
      };

      $req->header( Content_length => $params{content_length} // ( stat $fh )->size );
   }

   my $f = $self->{ua}->do_request(
      request => $req,
      request_body => $body,
   )->then( sub {
      my ( $response ) = @_;
      $response->content_type eq "application/json" or
         return Future->fail( "Expected application/json response", matrix => );

      my $content = $response->content;
      my $uri;
      if( length $content and $content ne q("") ) {
         eval {
            $content = decode_json( $content );
            1;
         } or  
            return Future->fail( "Unable to parse JSON response " );
         return Future->done( $content, $response );
      }
      else {
         return Future->done( undef, $response );
      }
   });

   return $self->adopt_future( $f );
}

=head2 login

   $matrix->login( %params )->get

Performs the necessary steps required to authenticate with the configured
Home Server, actually obtain an access token and starting the event stream
(unless disabled by the C<enable_events> option being false). The returned
C<Future> will eventually yield the C<$matrix> object itself, so it can be
easily chained.

There are various methods of logging in supported by Matrix; the following
sets of arguments determine which is used:

=over 4

=item user_id, password

Log in via the C<m.login.password> method.

=item user_id, access_token

Directly sets the C<user_id> and C<access_token> fields, bypassing the usual
login semantics. This presumes you already have an existing access token to
re-use, obtained by some other mechanism. This exists largely for testing
purposes.

=back

=cut

sub login
{
   my $self = shift;
   my %params = @_;

   if( defined $params{user_id} and defined $params{access_token} ) {
      $self->{$_} = $params{$_} for qw( user_id access_token );
      $self->configure( notifier_name => "uid=$params{user_id}" );
      return ( ( $self->{enable_events} // 1 ) ? $self->start : Future->done )->then( sub {
         Future->done( $self )
      });
   }

   # Otherwise; try to obtain the login flow information
   $self->_do_GET_json( "/login" )->then( sub {
      my ( $response ) = @_;
      my $flows = $response->{flows};

      my @supported;
      foreach my $flow ( @$flows ) {
         next unless my ( $type ) = $flow->{type} =~ m/^m\.login\.(.*)$/;
         push @supported, $type;

         next unless my $code = $self->can( "_login_with_$type" );
         next unless my $f = $code->( $self, %params );

         return $f;
      }

      Future->fail( "Unsure how to log in (server supports @supported)", matrix => );
   });
}

sub _login_with_password
{
   my $self = shift;
   my %params = @_;

   return unless defined $params{user_id} and defined $params{password};

   $self->_do_POST_json( "/login",
      { type => "m.login.password", user => $params{user_id}, password => $params{password} }
   )->then( sub {
      my ( $resp ) = @_;
      return $self->login( %$resp, %params ) if defined $resp->{access_token};
      return Future->fail( "Expected server to respond with 'access_token'", matrix => );
   });
}

=head2 register

   $matrix->register( %params )->get

Performs the necessary steps required to create a new account on the
configured Home Server.

=cut

sub register
{
   my $self = shift;
   my %params = @_;

   $self->_do_GET_json( "/register" )->then( sub {
      my ( $response ) = @_;
      my $flows = $response->{flows};

      my @supported;
      # Try to find a flow for which we can support all the stages
      FLOW: foreach my $flow ( @$flows ) {
         # Might or might not find a 'stages' key
         my @stages = $flow->{stages} ? @{ $flow->{stages} } : ( $flow->{type} );

         push @supported, join ",", @stages;

         my @flowcode;
         foreach my $stage ( @stages ) {
            next FLOW unless my ( $type ) = $stage =~ m/^m\.login\.(.*)$/;
            $type =~ s/\./_/g;

            next FLOW unless my $method = $self->can( "_register_with_$type" );
            next FLOW unless my $code = $method->( $self, %params );

            push @flowcode, $code;
         }

         # If we've got this far then we know we can implement all the stages
         my $start = Future->new;
         my $tail = $start;
         $tail = $tail->then( $_ ) for @flowcode;

         $start->done();
         return $tail->then( sub {
            my ( $resp ) = @_;
            return $self->login( %$resp ) if defined $resp->{access_token};
            return Future->fail( "Expected server to respond with 'access_token'", matrix => );
         });
      }

      Future->fail( "Unsure how to register (server supports @supported)", matrix => );
   });
}

sub _register_with_password
{
   my $self = shift;
   my %params = @_;

   return unless defined( my $password = $params{password} );

   return sub {
      my ( $resp ) = @_;

      $self->_do_POST_json( "/register", {
         type    => "m.login.password",
         session => $resp->{session},

         user     => $params{user_id},
         password => $password,
      } );
   }
}

sub _register_with_recaptcha
{
   my $self = shift;
   my %params = @_;

   return unless defined( my $secret = $params{captcha_bypass_secret} ) and
      defined $params{user_id};

   warn "Cannot use captcha_bypass_secret to bypass m.register.recaptcha without Digest::HMAC_SHA1\n" and return
      if !HAVE_DIGEST_HMAC_SHA1;

   my $digest = Digest::HMAC_SHA1::hmac_sha1_hex( $params{user_id}, $secret );

   return sub {
      my ( $resp ) = @_;

      $self->_do_POST_json( "/register", {
         type    => "m.login.recaptcha",
         session => $resp->{session},

         user                => $params{user_id},
         captcha_bypass_hmac => $digest,
      } );
   };
}

=head2 sync

   $matrix->sync( %params )->get

Performs a single C</sync> request on the server, returning the raw results
directly.

Takes the following named parameters

=over 4

=item since => STRING

Optional. Sync token from the previous request.

=back

=cut

sub sync
{
   my $self = shift;
   my ( %params ) = @_;

   $self->_do_GET_json( "/sync", %params );
}

sub await_synced
{
   my $self = shift;
   return $self->{synced_future} //= $self->loop->new_future;
}

=head2 start

   $f = $matrix->start

Performs the initial sync on the server, and starts the event stream to
begin receiving events.

While this method does return a C<Future> it is not required that the caller
keep track of this; the object itself will store it. It will complete when the
initial sync has fininshed, and the event stream has started.

If the initial sync has already been requested, this method simply returns the
future it returned the last time, ensuring that you can await the client
starting up simply by calling it; it will not start a second time.

=cut

sub start
{
   my $self = shift;

   defined $self->{access_token} or croak "Cannot ->start without an access token";

   return $self->{start_f} ||= do {
      undef $self->{synced_future};

      foreach my $room ( values %{ $self->{rooms_by_id} } ) {
         $room->_reset_for_sync;
      }

      my %first_sync_args;

      $first_sync_args{filter}{room}{timeline}{limit} = $self->{first_sync_limit} 
         if defined $self->{first_sync_limit};

      $self->sync( %first_sync_args )->then( sub {
         my ( $sync ) = @_;

         $self->_incoming_sync( $sync );

         $self->start_longpoll( since => $sync->{next_batch} );

         return $self->await_synced->done;
      })->on_fail( sub { undef $self->{start_f} });
   };
}

=head2 stop

   $matrix->stop

Stops the event stream. After calling this you will need to use C<start> again
to continue receiving events.

=cut

sub stop
{
   my $self = shift;

   ( delete $self->{start_f} )->cancel if $self->{start_f};
   $self->stop_longpoll;
}

## Longpoll events

sub start_longpoll
{
   my $self = shift;
   my %args = @_;

   $self->stop_longpoll;
   $self->{longpoll_last_token} = $args{since};

   my $f = $self->{longpoll_f} = repeat {
      my $last_token = $self->{longpoll_last_token};

      Future->wait_any(
         $self->{make_delay}->( $self->{longpoll_timeout} + 5 )
            ->else_fail( "Longpoll timed out" ),

         $self->sync(
            since   => $last_token,
            timeout => $self->{longpoll_timeout} * 1000, # msec
         )->then( sub {
            my ( $sync ) = @_;

            $self->_incoming_sync( $sync );

            $self->{longpoll_last_token} = $sync->{next_batch};

            Future->done();
         }),
      )->else( sub {
         my ( $failure ) = @_;
         warn "Longpoll failed - $failure\n";

         $self->{make_delay}->( 3 )
      });
   } while => sub { !shift->failure };

   # Don't ->adopt_future this one as it makes it hard to grab to cancel it
   # again, but apply the same on_fail => invoke_error logic
   $f->on_fail( $self->_capture_weakself( sub {
      my $self = shift;
      $self->invoke_error( @_ );
   }));
}

sub stop_longpoll
{
   my $self = shift;

   ( delete $self->{longpoll_f} )->cancel if $self->{longpoll_f};
}

sub _get_or_make_user
{
   my $self = shift;
   my ( $user_id ) = @_;

   return $self->{users_by_id}{$user_id} ||= User( $user_id, undef, undef, undef );
}

sub _make_room
{
   my $self = shift;
   my ( $room_id ) = @_;

   $self->{rooms_by_id}{$room_id} and
      croak "Already have a room with ID '$room_id'";

   my @args;
   foreach (qw( message member )) {
      push @args, "on_$_" => $self->{"on_room_$_"} if $self->{"on_room_$_"};
   }

   my $room = $self->{rooms_by_id}{$room_id} = $self->make_room(
      matrix  => $self,
      room_id => $room_id,
      @args,
   );
   $self->add_child( $room );

   $self->maybe_invoke_event( on_room_new => $room );

   return $room;
}

sub make_room
{
   my $self = shift;
   return Net::Async::Matrix::Room->new( @_ );
}

sub _get_or_make_room
{
   my $self = shift;
   my ( $room_id ) = @_;

   return $self->{rooms_by_id}{$room_id} //
      $self->_make_room( $room_id );
}

=head2 myself

   $user = $matrix->myself

Returns the user object representing the connected user.

=cut

sub myself
{
   my $self = shift;
   return $self->_get_or_make_user( $self->{user_id} );
}

=head2 user

   $user = $matrix->user( $user_id )

Returns the user object representing a user of the given ID, if defined, or
C<undef>.

=cut

sub user
{
   my $self = shift;
   my ( $user_id ) = @_;
   return $self->{users_by_id}{$user_id};
}

sub _incoming_sync
{
   my $self = shift;
   my ( $sync ) = @_;

   foreach my $category (qw( invite join leave )) {
      my $rooms = $sync->{rooms}{$category} or next;
      foreach my $room_id ( keys %$rooms ) {
         my $roomsync = $rooms->{$room_id};

         my $room = $self->_get_or_make_room( $room_id );

         $room->${\"_incoming_sync_$category"}( $roomsync );
      }
   }

   foreach my $event ( @{ $sync->{presence}{events} } ) {
      $self->_handle_event_m_presence( $event );
   }

   # TODO: account_data
}

sub _on_self_leave
{
   my $self = shift;
   my ( $room ) = @_;

   $self->maybe_invoke_event( on_room_del => $room );

   delete $self->{rooms_by_id}{$room->room_id};
}

=head2 get_displayname

=head2 set_displayname

   $name = $matrix->get_displayname->get

   $matrix->set_displayname( $name )->get

Accessor and mutator for the user account's "display name" profile field.

=cut

sub get_displayname
{
   my $self = shift;
   my ( $user_id ) = @_;

   $user_id //= $self->{user_id};

   $self->_do_GET_json( "/profile/$user_id/displayname" )->then( sub {
      my ( $content ) = @_;

      Future->done( $content->{displayname} );
   });
}

sub set_displayname
{
   my $self = shift;
   my ( $name ) = @_;

   $self->_do_PUT_json( "/profile/$self->{user_id}/displayname",
      { displayname => $name }
   );
}

=head2 get_presence

=head2 set_presence

   ( $presence, $msg ) = $matrix->get_presence->get

   $matrix->set_presence( $presence, $msg )->get

Accessor and mutator for the user's current presence state and optional status
message string.

=cut

sub get_presence
{
   my $self = shift;

   $self->_do_GET_json( "/presence/$self->{user_id}/status" )->then( sub {
      my ( $status ) = @_;
      Future->done( $status->{presence}, $status->{status_msg} );
   });
}

sub set_presence
{
   my $self = shift;
   my ( $presence, $msg ) = @_;

   my $status = {
      presence => $presence,
   };
   $status->{status_msg} = $msg if defined $msg;

   $self->_do_PUT_json( "/presence/$self->{user_id}/status", $status )
}

sub get_presence_list
{
   my $self = shift;

   $self->_do_GET_json( "/presence_list/$self->{user_id}" )->then( sub {
      my ( $events ) = @_;

      my @users;
      foreach my $event ( @$events ) {
         my $user = $self->_get_or_make_user( $event->{user_id} );
         foreach (qw( presence displayname )) {
            $user->$_ = $event->{$_} if defined $event->{$_};
         }

         push @users, $user;
      }

      Future->done( @users );
   });
}

sub invite_presence
{
   my $self = shift;
   my ( $remote ) = @_;

   $self->_do_POST_json( "/presence_list/$self->{user_id}",
      { invite => [ $remote ] }
   );
}

sub drop_presence
{
   my $self = shift;
   my ( $remote ) = @_;

   $self->_do_POST_json( "/presence_list/$self->{user_id}",
      { drop => [ $remote ] }
   );
}

=head2 create_room

   ( $room, $room_alias ) = $matrix->create_room( $alias_localpart )->get

Requests the creation of a new room and associates a new alias with the given
localpart on the server. The returned C<Future> will return an instance of
L<Net::Async::Matrix::Room> and a string containing the full alias that was
created.

=cut

sub create_room
{
   my $self = shift;
   my ( $room_alias ) = @_;

   my $body = {};
   $body->{room_alias_name} = $room_alias if defined $room_alias;
   # TODO: visibility?

   $self->_do_POST_json( "/createRoom", $body )->then( sub {
      my ( $content ) = @_;

      my $room = $self->_get_or_make_room( $content->{room_id} );
      $room->initial_sync
         ->then_done( $room, $content->{room_alias} );
   });
}

=head2 join_room

   $room = $matrix->join_room( $room_alias_or_id )->get

Requests to join an existing room with the given alias name or plain room ID.
If this room is already known by the C<$matrix> object, this method simply
returns it.

=cut

sub join_room
{
   my $self = shift;
   my ( $room_alias ) = @_;

   $self->_do_POST_json( "/join/$room_alias", {} )->then( sub {
      my ( $content ) = @_;
      my $room_id = $content->{room_id};

      if( my $room = $self->{rooms_by_id}{$room_id} ) {
         return Future->done( $room );
      }
      else {
         my $room = $self->_make_room( $room_id );
         return $room->await_synced->then_done( $room );
      }
   });
}

sub room_list
{
   my $self = shift;

   $self->_do_GET_json( "/users/$self->{user_id}/rooms/list" )
      ->then( sub {
         my ( $response ) = @_;
         Future->done( pp($response) );
      });
}

=head2 add_alias

=head2 delete_alias

   $matrix->add_alias( $alias, $room_id )->get

   $matrix->delete_alias( $alias )->get

Performs a directory server request to create the given room alias name, to
point at the room ID, or to remove it again.

Note that this is likely only to be supported for alias names scoped within
the homeserver the client is connected to, and that additionally some form of
permissions system may be in effect on the server to limit access to the
directory server.

=cut

sub add_alias
{
   my $self = shift;
   my ( $alias, $room_id ) = @_;

   $self->_do_PUT_json( "/directory/room/$alias",
      { room_id => $room_id },
   )->then_done();
}

sub delete_alias
{
   my $self = shift;
   my ( $alias ) = @_;

   $self->_do_DELETE( "/directory/room/$alias" )
      ->then_done();
}

=head2 upload

   $content_uri = $matrix->upload( %params )->get

Performs a post to the server's media content repository, to upload a new
piece of content, returning the content URI that points to it.

The content can be specified in any of three ways, with the following three
mutually-exclusive arguments:

=over 4

=item content => STRING

Gives the content directly as an immediate scalar value.

=item file => STRING

Gives the path to a readable file on the filesystem containing the content.

=item fh => IO

Gives an opened IO handle the content can be read from.

=back

The following additional arguments are also recognised:

=over 4

=item content_type => STRING

Gives the MIME type of the content data.

=item content_length => INT

Optional. If the content is being delivered from an opened filehandle (via the
C<fh> argument), this gives the total length in bytes. This is required in
cases such as reading from pipes, when the length of the content isn't
immediately available such as by C<stat()>ing the filehandle.

=back

=cut

sub upload
{
   my $self = shift;
   my %params = @_;

   defined $params{content_type} or
      croak "Require 'content_type'";

   defined $params{content} or defined $params{file} or defined $params{fh} or
      croak "Require 'content', 'file' or 'fh'";

   # This one takes ~full URL paths
   $self->_do_POST_file( "/media/v1/upload", %params )->then( sub {
      my ( $content, $response ) = @_;
      Future->done( $content->{content_uri} );
   });
}

=head2 convert_mxc_url

   $url = $matrix->convert_mxc_url( $mxc )

Given a plain string or L<URI> instance containing a Matrix media URL (in the
C<mxc:> scheme), returns an C<http:> or C<https:> URL in the form of an L<URI>
instance pointing at the media repository on the user's local homeserver where
it can be downloaded from.

=cut

sub convert_mxc_url
{
   my $self = shift;
   my ( $mxc ) = @_;

   ( blessed $mxc and $mxc->isa( "URI" ) ) or
      $mxc = URI->new( $mxc );

   $mxc->scheme eq "mxc" or
      croak "Require an mxc:// scheme";

   my $uri = URI->new;
   $uri->scheme( $self->{SSL} ? "https" : "http" );
   $uri->authority( $self->{server} );
   $uri->path( "/_matrix/media/v1/download/" . $mxc->authority . $mxc->path );

   return $uri;
}

## Incoming events

sub _handle_event_m_presence
{
   my $self = shift;
   my ( $event ) = @_;
   my $content = $event->{content};

   my $user = $self->_get_or_make_user( $event->{sender} );

   my %changes;
   foreach (qw( presence displayname )) {
      next unless defined $content->{$_};
      next if defined $user->$_ and $content->{$_} eq $user->$_;

      $changes{$_} = [ $user->$_, $content->{$_} ];
      $user->$_ = $content->{$_};
   }

   if( defined $content->{last_active_ago} ) {
      my $new_last_active = time() - ( $content->{last_active_ago} / 1000 );

      $changes{last_active} = [ $user->last_active, $new_last_active ];
      $user->last_active = $new_last_active;
   }

   $self->maybe_invoke_event(
      on_presence => $user, %changes
   );

   foreach my $room ( values %{ $self->{rooms_by_id} } ) {
      $room->_handle_event_m_presence( $user, %changes );
   }
}

=head1 USER STRUCTURES

Parameters documented as C<$user> receive a user struct, which supports the
following methods:

=head2 $user_id = $user->user_id

User ID of the user.

=head2 $displayname = $user->displayname

Profile displayname of the user.

=head2 $presence = $user->presence

Presence state. One of C<offline>, C<unavailable> or C<online>.

=head2 $last_active = $user->last_active

Epoch time that the user was last active.

=cut

=head1 SUBCLASSING METHODS

The following methods are not normally required by users of this class, but
are provided for the convenience of subclasses to override.

=head2 $room = $matrix->make_room( %params )

Returns a new instance of L<Net::Async::Matrix::Room>.

=cut

=head1 SEE ALSO

=over 4

=item *

L<http://matrix.org/> - matrix.org home page

=item *

L<https://github.com/matrix-org> - matrix.org on github

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
