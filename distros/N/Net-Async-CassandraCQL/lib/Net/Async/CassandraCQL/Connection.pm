#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Net::Async::CassandraCQL::Connection;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use base qw( IO::Async::Stream );
IO::Async::Stream->VERSION( '0.59' );

use Carp;

use Future 0.13;

use constant HAVE_SNAPPY => eval { require Compress::Snappy };
use constant HAVE_LZ4    => eval { require Compress::LZ4 };

# Max streams 127, because of streamid packed in the native protocol as C.
# Version 3 of the protocol changes that, and this can be raised
use constant MAX_STREAMS => 127;

use Protocol::CassandraCQL qw(
   :opcodes :results :consistencies FLAG_COMPRESS
   build_frame parse_frame
);
use Protocol::CassandraCQL::Frame;
use Protocol::CassandraCQL::Frames 0.10 qw( :all );

use Net::Async::CassandraCQL::Query;

# Ensure that IO::Async definitely uses this for Iv6 connections as we need
# the ->peerhost method
require IO::Socket::IP;

=head1 NAME

C<Net::Async::CassandraCQL::Connection> - connect to a single Cassandra database node

=head1 DESCRIPTION

TODO

=cut

=head1 EVENTS

=head2 on_event $name, @args

A registered event occurred. C<@args> will depend on the event name. Each
is also available as its own event, with the name in lowercase. If the event
is not one of the types recognised below, C<@args> will contain the actual
L<Protocol::CassandraCQL::Frame> object.

=head2 on_topology_change $type, $node

The cluster topology has changed. C<$node> is a packed socket address.

=head2 on_status_change $status, $node

The node's status has changed. C<$node> is a packed socket address.

=head2 on_schema_change $type, $keyspace, $table

A keyspace or table schema has changed.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item username => STRING

=item password => STRING

Optional. Authentication details to use for C<PasswordAuthenticator>.

=item cql_version => INT

Optional. Version of the CQL wire protocol to negotiate during connection.
Defaults to 1.

=back

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{streams} = []; # map [1 .. 127] to Future
   $self->{pending} = []; # queue of [$opcode, $frame, $f]
   $self->{cql_version} = 1;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( username password cql_version
                on_event on_topology_change on_status_change on_schema_change )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

=cut

=head2 $id = $conn->nodeid

Returns the connection's node ID (the string form of its IP address), which is
used as its ID in the C<system.peers> table.

=cut

sub nodeid
{
   my $self = shift;
   $self->{nodeid};
}

sub _version
{
   my $self = shift;
   return $self->{cql_version};
}

# function
sub _decode_result
{
   my ( $version, $response ) = @_;

   my ( $type, $result ) = parse_result_frame( $version, $response );

   if( $type == RESULT_VOID ) {
      return Future->new->done();
   }
   else {
      if   ( $type == RESULT_ROWS          ) { $type = "rows"          }
      elsif( $type == RESULT_SET_KEYSPACE  ) { $type = "keyspace"      }
      elsif( $type == RESULT_SCHEMA_CHANGE ) { $type = "schema_change" }
      return Future->new->done( $type => $result );
   }
}

=head2 $conn->connect( %args ) ==> $conn

Connects to the Cassandra node an send the C<OPCODE_STARTUP> message. The
returned Future will yield the connection itself on success.

Takes the following named arguments:

=over 8

=item host => STRING

=item service => STRING

=back

=cut

sub connect
{
   my $self = shift;
   my %args = @_;

   $args{socktype} ||= "stream";

   return ( $self->{connect_f} ||=
      $self->SUPER::connect( %args )->on_fail( sub { undef $self->{connect_f} } ) )
      ->then( sub {
         $self->{nodeid} = $self->read_handle->peerhost;
         $self->startup
      })->then( sub { Future->new->done( $self ) });
}

sub _has_pending
{
   my $self = shift;
   defined and return 1 for @{ $self->{streams} };
   return 0;
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   my ( $version, $flags, $streamid, $opcode, $body ) = parse_frame( $$buffref ) or return 0;

   $version & 0x80 or
      $self->fail_all_and_close( "Expected response to have RESPONSE bit set" ), return;
   $version &= 0x7f;

   # Test version <= for now in case of "unsupported protocol version" error messages, and
   # test it exactly later
   $version <= $self->_version or
      $self->fail_all_and_close( sprintf "Unexpected message version %#02x\n", $version ), return;

   if( $flags & FLAG_COMPRESS and my $decompress = $self->{decompress} ) {
      $flags &= ~FLAG_COMPRESS;
      $body = $decompress->( $body );
   }

   $flags == 0 or
      $self->fail_all_and_close( sprintf "Unexpected message flags %#02x\n", $flags ), return;

   my $frame = Protocol::CassandraCQL::Frame->new( $body );

   if( my $f = $self->{streams}[$streamid] ) {

      if ($opcode == OPCODE_AUTHENTICATE){
        # Authenticates *do* get to run their futures ahead of anything in Pending,
        undef $self->{streams}[$streamid];
        }

      if( $opcode == OPCODE_ERROR ) {
         my ( $err, $message ) = parse_error_frame( $version, $frame );
         $f->fail( "OPCODE_ERROR: $message\n", $err, $frame );
      }
      else {
         $version == $self->_version or
            $self->fail_all_and_close( sprintf "Unexpected message version %#02x\n", $version ), return;

         $f->done( $opcode, $frame, $version );
      }

      # Undefined after running $f->done, so that $f doesn't get to jump the queue ahead of pending requests
      # NB: Moving this above $f->done would mean protecting pending against assuming this streamid is still free
      unless ($opcode == OPCODE_AUTHENTICATE){
        undef $self->{streams}[$streamid];
        }

      # streamid may have been re-populated by a new send_message to AUTHENTICATE
      if( !$self->{streams}[$streamid] and my $next = shift @{ $self->{pending} } ) {
         my ( $opcode, $frame, $f ) = @$next;
         $self->_send( $opcode, $streamid, $frame, $f );
      }
      elsif( my $close_f = $self->{cassandra_close_future} and !$self->_has_pending ) {
         $close_f->done( $self );
      }
   }
   elsif( $streamid == 0 and $opcode == OPCODE_ERROR ) {
      my ( $err, $message ) = parse_error_frame( $version, $frame );
      $self->fail_all_and_close( "OPCODE_ERROR: $message\n", $err, $frame );
   }
   elsif( $streamid == 0xff and $opcode == OPCODE_EVENT ) {
      $self->_event( $frame );
   }
   else {
      print STDERR "Received a message opcode=$opcode for unknown stream $streamid\n";
   }

   return 1;
}

sub _event
{
   my $self = shift;
   my ( $frame ) = @_;

   my ( $name, @args ) = parse_event_frame( $self->_version, $frame );

   $self->maybe_invoke_event( "on_".lc($name), @args )
      or $self->maybe_invoke_event( on_event => $name, @args );
}

sub on_closed
{
   my $self = shift;
   $self->fail_all( "Connection closed" );
}

sub fail_all
{
   my $self = shift;
   my ( $failure ) = @_;

   foreach ( @{ $self->{streams} } ) {
      $_->fail( $failure ) if $_;
   }
   @{ $self->{streams} } = ();

   foreach ( @{ $self->{pending} } ) {
      $_->[2]->fail( $failure );
   }
   @{ $self->{pending} } = ();
}

sub fail_all_and_close
{
   my $self = shift;
   my ( $failure ) = @_;

   $self->fail_all( $failure );

   $self->close;

   return Future->new->fail( $failure );
}

=head2 $conn->send_message( $opcode, $frame ) ==> ( $reply_opcode, $reply_frame, $reply_version )

Sends a message with the given opcode and L<Protocol::CassandraCQL::Frame> for
the message body. The returned Future will yield the response opcode, frame
and version number (with the RESPONSE bit masked off).

This is a low-level method; applications should instead use one of the wrapper
methods below.

=cut

sub send_message
{
   my $self = shift;
   my ( $opcode, $frame ) = @_;

   croak "Cannot ->send_message when in close-pending state" if $self->{cassandra_close_future};

   my $f = $self->loop->new_future;

   my $streams = $self->{streams} ||= [];
   my $id;
   foreach ( 1 .. $#$streams ) {
      $id = $_ and last if !defined $streams->[$_];
   }

   if( !defined $id ) {
      if( $#$streams == MAX_STREAMS ) {
         push @{ $self->{pending} }, [ $opcode, $frame, $f ];
         return $f;
      }
      $id = @$streams;
      $id = 1 if !$id; # can't use 0
   }

   $self->_send( $opcode, $id, $frame, $f );

   return $f;
}

sub _send
{
   my $self = shift;
   my ( $opcode, $id, $frame, $f ) = @_;

   my $flags = 0;
   my $body = $frame->bytes;

   if( my $compress = $self->{compress} ) {
      my $body_compressed = $compress->( $body );
      if( length $body_compressed < length $body ) {
         $flags |= FLAG_COMPRESS;
         $body = $body_compressed;
      }
   }

   $self->write( build_frame( $self->_version, $flags, $id, $opcode, $body ) );

   $self->{streams}[$id] = $f;
}

=head2 $conn->startup ==> ()

Sends the initial connection setup message. On success, the returned Future
yields nothing.

Normally this is not required as the C<connect> method performs it implicitly.

=cut

sub startup
{
   my $self = shift;

   # CQLv1 doesn't support LZ4
   my $compression;
   if( HAVE_LZ4 and $self->_version > 1 ) {
      # Cassandra prepends 32bit BE integer of original size
      $compression = [ lz4 =>
         sub { my ( $data ) = @_; pack "N a*", length $data, Compress::LZ4::lz4_compress( $data ) },
         sub { my ( $bodylen, $lz4data ) = unpack "N a*", $_[0]; Compress::LZ4::lz4_decompress( $lz4data, $bodylen ) },
      ];
   }
   elsif( HAVE_SNAPPY ) {
      $compression = [ snappy =>
         \&Compress::Snappy::compress,
         \&Compress::Snappy::decompress,
      ];
   }
   # else undef

   my $f = $self->send_message( OPCODE_STARTUP, build_startup_frame( $self->_version,
      options => {
         CQL_VERSION => "3.0.5",
         ( $compression ? ( COMPRESSION => $compression->[0] ) : () ),
      } )
   )->then( sub {
      my ( $op, $response, $version ) = @_;

      if( $op == OPCODE_READY ) {
         return Future->new->done;
      }
      elsif( $op == OPCODE_AUTHENTICATE ) {
         return $self->_authenticate( parse_authenticate_frame( $version, $response ) );
      }
      else {
         return $self->fail_all_and_close( "Expected OPCODE_READY or OPCODE_AUTHENTICATE" );
      }
   });

   $self->{compress}   = $compression->[1];
   $self->{decompress} = $compression->[2];

   return $f;
}

sub _authenticate
{
   my $self = shift;
   my ( $authenticator ) = @_;

   if( $authenticator eq "org.apache.cassandra.auth.PasswordAuthenticator" ) {
      foreach (qw( username password )) {
         defined $self->{$_} or croak "Cannot authenticate by password without $_";
      }

      $self->send_message( OPCODE_CREDENTIALS, build_credentials_frame( $self->_version,
         credentials => {
            username => $self->{username},
            password => $self->{password},
         } )
      )->then( sub {
         my ( $op, $response, $version ) = @_;
         $op == OPCODE_READY or return $self->fail_all_and_close( "Expected OPCODE_READY" );

         return Future->new->done;
      });
   }
   else {
      return $self->fail_all_and_close( "Unrecognised authenticator $authenticator" );
   }
}

=head2 $conn->options ==> $options

Requests the list of supported options from the server node. On success, the
returned Future yields a HASH reference mapping option names to ARRAY
references containing valid values.

=cut

sub options
{
   my $self = shift;

   $self->send_message( OPCODE_OPTIONS,
      Protocol::CassandraCQL::Frame->new
   )->then( sub {
      my ( $op, $response, $version ) = @_;
      $op == OPCODE_SUPPORTED or return Future->new->fail( "Expected OPCODE_SUPPORTED" );

      my ( $opts ) = parse_supported_frame( $version, $response );
      return Future->new->done( $opts );
   });
}

=head2 $conn->query( $cql, $consistency, %other_args ) ==> ( $type, $result )

Performs a CQL query. On success, the values returned from the Future will
depend on the type of query.

For C<USE> queries, the type is C<keyspace> and C<$result> is a string giving
the name of the new keyspace.

For C<CREATE>, C<ALTER> and C<DROP> queries, the type is C<schema_change> and
C<$result> is a 3-element ARRAY reference containing the type of change, the
keyspace and the table name.

For C<SELECT> queries, the type is C<rows> and C<$result> is an instance of
L<Protocol::CassandraCQL::Result> containing the returned row data.

For other queries, such as C<INSERT>, C<UPDATE> and C<DELETE>, the future
returns nothing.

Any other arguments will be passed on to the underlying C<build_query_frame>
function of L<Protocol::CassandraCQL::Frames>.

=cut

sub query
{
   my $self = shift;
   my ( $cql, $consistency, %other_args ) = @_;

   $self->send_message( OPCODE_QUERY, build_query_frame( $self->_version,
         cql         => $cql,
         consistency => $consistency,
         %other_args,
      )
   )->then( sub {
      my ( $op, $response, $version ) = @_;
      $op == OPCODE_RESULT or return Future->new->fail( "Expected OPCODE_RESULT" );
      return _decode_result( $version, $response );
   });
}

=head2 $conn->prepare( $cql ) ==> $query

Prepares a CQL query for later execution. On success, the returned Future
yields an instance of L<Net::Async::CassandraCQL::Query>.

=cut

sub prepare
{
   my $self = shift;
   my ( $cql, $cassandra ) = @_;

   $self->send_message( OPCODE_PREPARE, build_prepare_frame( $self->_version,
         cql => $cql,
      )
   )->then( sub {
      my ( $op, $response, $version ) = @_;
      $op == OPCODE_RESULT or return Future->new->fail( "Expected OPCODE_RESULT" );

      my ( $type, $result ) = parse_result_frame( $version, $response );
      $type == RESULT_PREPARED or return Future->new->fail( "Expected RESULT_PREPARED" );

      my ( $id, $params_meta, $result_meta ) = @$result;

      my $query = Net::Async::CassandraCQL::Query->new(
         cassandra   => $cassandra,
         cql         => $cql,
         id          => $id,
         params_meta => $params_meta,
         result_meta => $result_meta, # v2+ only
      );
      return Future->new->done( $query );
   });
}

=head2 $conn->execute( $id, $data, $consistency, %other_args ) ==> ( $type, $result )

Executes a previously-prepared statement, given its ID and the binding data.
On success, the returned Future will yield results of the same form as the
C<query> method. C<$data> should contain a list of encoded byte-string values.
Any other arguments will be passed on to the underlying C<build_execute_frame>
function of L<Protocol::CassandraCQL::Frames>.

Normally this method is not directly required - instead, use the C<execute>
method on the query object itself, as this will encode the parameters
correctly.

=cut

sub execute
{
   my $self = shift;
   my ( $id, $data, $consistency, %other_args ) = @_;

   $self->send_message( OPCODE_EXECUTE, build_execute_frame( $self->_version,
         id          => $id,
         values      => $data,
         consistency => $consistency,
         %other_args,
      )
   )->then( sub {
      my ( $op, $response, $version ) = @_;
      $op == OPCODE_RESULT or return Future->new->fail( "Expected OPCODE_RESULT" );
      return _decode_result( $version, $response );
   });
}

=head2 $conn->register( $events ) ==> ()

Registers the connection's interest in receiving events of the types given in
the ARRAY reference. Event names may be C<TOPOLOGY_CHANGE>, C<STATUS_CHANGE>
or C<SCHEMA_CHANGE>. On success, the returned Future yields nothing.

=cut

sub register
{
   my $self = shift;
   my ( $events ) = @_;

   $self->send_message( OPCODE_REGISTER, build_register_frame( $self->_version,
         events => $events,
      )
   )->then( sub {
      my ( $op, $response, $version ) = @_;
      $op == OPCODE_READY or Future->new->fail( "Expected OPCODE_READY" );

      return Future->new->done;
   });
}

=head2 $conn->close_when_idle ==> $conn

If the connection is idle (has no outstanding queries), then it is closed
immediately. If not, it is put into close-pending mode, where it will accept
no more queries, and will close when the last pending one is complete.

Returns a future which will eventually yield the (closed) connection when it
becomes closed.

=cut

sub close_when_idle
{
   my $self = shift;

   $self->{cassandra_close_future} ||= do {
      my $f = $self->loop->new_future;
      $f->on_done( sub { $_[0]->close } );

      $f->done( $self ) if !$self->_has_pending;

      $f
   };
}

=head1 SPONSORS

This code was paid for by

=over 2

=item *

Perceptyx L<http://www.perceptyx.com/>

=item *

Shadowcat Systems L<http://www.shadow.cat>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
