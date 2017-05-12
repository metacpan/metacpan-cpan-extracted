#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL::Client;

use strict;
use warnings;

our $VERSION = '0.12';

use base qw( IO::Socket::IP );

use Carp;

use Protocol::CassandraCQL qw(
   :opcodes :results
   send_frame recv_frame FLAG_COMPRESS
);
use Protocol::CassandraCQL::Frame;
use Protocol::CassandraCQL::Frames qw(
   build_startup_frame
   build_credentials_frame
   build_query_frame

   parse_error_frame
   parse_authenticate_frame
   parse_result_frame
);
use Protocol::CassandraCQL::Result;

use Compress::Snappy qw( compress decompress );

use constant DEFAULT_CQL_PORT => 9042;

use constant MAX_SUPPORTED_VERSION => 2;

=head1 NAME

C<Protocol::CassandraCQL::Client> - a minimal Cassandra CQL client

=head1 SYNOPSIS

 use Protocol::CassandraCQL::Client;
 use Protocol::CassandraCQL qw( CONSISTENCY_QUORUM );

 my $cass = Protocol::CassandraCQL::Client->new(
    PeerHost => "localhost",
    Keyspace => "my-keyspace",
 );

 my ( undef, $result ) = $cass->query( "SELECT v FROM numbers" );

 foreach my $row ( $result->rows_hash ) {
    say "We have a number $row->{v}";
 }

=head1 DESCRIPTION

This subclass of L<IO::Socket::IP> implements a client that can execute
queries on a Cassandra CQL database. It is not intended as a complete client,
is simply provides enough functionallity to test that the protocol handling is
working, and is used to implement the bundled F<examples/cqlsh> utility.

For a more complete client, see instead L<Net::Async::CassandraCQL>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $cass = Protocol::CassandraCQL::Client->new( %args )

Takes the following arguments in addition to those accepted by
L<IO::Socket::IP>:

=over 8

=item Username => STRING

=item Password => STRING

Authentication credentials if required by the server.

=item Keyspace => STRING

If defined, selects the keyspace to C<USE> after connection.

=item CQLVersion => INT

If defined, sets the CQL protocol version that will be negotiated. If omitted
will default to 1.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_ == 1 ? ( PeerHost => $_[0] ) : @_;

   $args{PeerService} ||= DEFAULT_CQL_PORT;

   my $self = $class->SUPER::new( %args ) or return;

   ${*$self}{Cassandra_version} = $args{CQLVersion} // 1; # default 1
   $self->_version <= MAX_SUPPORTED_VERSION or
      croak "CQLVersion too high - maximum supported is " . MAX_SUPPORTED_VERSION;

   $self->startup( %args );
   $self->use_keyspace( $args{Keyspace} ) if defined $args{Keyspace};

   return $self;
}

sub _version
{
   my $self = shift;
   return ${*$self}{Cassandra_version};
}

=head1 METHODS

=cut

=head2 ( $result_op, $result_frame ) = $cass->send_message( $opcode, $frame )

Sends a message with the given opcode and L<Protocol::CassandraCQL::Frame> for
the message body. Waits for a response to be received, and returns it.

If the response opcode is C<OPCODE_ERROR> then the error message string is
thrown directly as an exception; this method will only return in non-error
cases.

=cut

sub send_message
{
   my $self = shift;
   my ( $opcode, $frame ) = @_;

   {
      my $flags = 0;
      my $body = $frame->bytes;

      my $body_compressed = compress( $body );
      if( length $body_compressed < length $body ) {
         $body = $body_compressed;
         $flags |= FLAG_COMPRESS;
      }

      send_frame( $self, $self->_version, $flags, 0, $opcode, $body );
   }

   my ( $version, $flags, $streamid, $result_op, $body ) = recv_frame( $self ) or croak "Unable to ->recv: $!";

   $version & 0x80 or croak "Expected response frame to have RESPONSE bit set";
   $version &= 0x7f;

   $version <= $self->_version or
      croak sprintf "Received message version too high to parse (%d)", $version;

   if( $flags & FLAG_COMPRESS ) {
      $body = decompress( $body );
      $flags &= ~FLAG_COMPRESS;
   }
   $flags == 0 or
      croak sprintf "Unexpected flags 0x%02x", $flags;

   $streamid == 0 or
      croak "Unexpected stream ID $streamid";

   my $response = Protocol::CassandraCQL::Frame->new( $body );

   if( $result_op == OPCODE_ERROR ) {
      my ( undef, $message ) = parse_error_frame( $version, $response );
      croak "OPCODE_ERROR: $message";
   }

   # Version check after OPCODE_ERROR in case of "insupported version" error
   $version == $self->_version or
      croak sprintf "Unexpected message version %#02x", $version;

   return ( $result_op, $response );
}

sub startup
{
   my $self = shift;
   my %args = @_;

   my ( $op, $response ) = $self->send_message( OPCODE_STARTUP,
      build_startup_frame( $self->_version, options => {
         CQL_VERSION => "3.0.5",
         COMPRESSION => "Snappy",
      } ),
   );

   if( $op == OPCODE_AUTHENTICATE ) {
      my ( $authenticator ) = parse_authenticate_frame( $self->_version, $response );
      if( $authenticator eq "org.apache.cassandra.auth.PasswordAuthenticator" ) {
         defined $args{Username} and defined $args{Password} or
            croak "Cannot authenticate without a username/password";

         ( $op, $response ) = $self->send_message( OPCODE_CREDENTIALS,
            build_credentials_frame( $self->_version, credentials => {
               username => $args{Username},
               password => $args{Password},
            } )
         );
      }
      else {
         croak "Unrecognised authenticator $authenticator";
      }
   }

   $op == OPCODE_READY or croak "Expected OPCODE_READY";
}

=head2 ( $type, $result ) = $cass->query( $cql, $consistency )

Performs a CQL query and returns the result, as decoded by
L<Protocol::CassandraCQL::Frames/parse_result_frame>.

For C<USE> queries, the type is C<RESULT_SET_KEYSPACE> and C<$result> is a
string giving the name of the new keyspace.

For C<CREATE>, C<ALTER> and C<DROP> queries, the type is
C<RESULT_SCHEMA_CHANGE> and C<$result> is a 3-element ARRAY reference
containing the type of change, the keyspace and the table name.

For C<SELECT> queries, the type is C<RESULT_ROWS> and C<$result> is an
instance of L<Protocol::CassandraCQL::Result> containing the returned row
data.

For other queries, such as C<INSERT>, C<UPDATE> and C<DELETE>, the method
returns C<RESULT_VOID> and C<$result> is C<undef>.

=cut

sub query
{
   my $self = shift;
   my ( $cql, $consistency ) = @_;

   my ( $op, $response ) = $self->send_message( OPCODE_QUERY,
      build_query_frame( $self->_version, cql => $cql, consistency => $consistency )
   );

   $op == OPCODE_RESULT or croak "Expected OPCODE_RESULT";
   return parse_result_frame( $self->_version, $response );
}

=head2 ( $type, $result ) = $cass->use_keyspace( $keyspace )

A convenient shortcut to the C<USE $keyspace> query which escapes the keyspace
name.

=cut

sub use_keyspace
{
   my $self = shift;
   my ( $keyspace ) = @_;

   # CQL's "quoting" handles any character except quote marks, which have to
   # be doubled
   $keyspace =~ s/"/""/g;

   $self->query( qq(USE "$keyspace"), 0 );
}

=head1 TODO

=over 8

=item *

Consider how the server's maximum supported CQL version can be detected on
startup. This is made hard by the fact that the server closes the connection
if the version is too high, so we'll have to reconnect it.

=back

=cut

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
