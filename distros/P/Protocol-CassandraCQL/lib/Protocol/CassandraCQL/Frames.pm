#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL::Frames;

use strict;
use warnings;

our $VERSION = '0.12';

use Exporter 'import';
our @EXPORT_OK = qw(
   build_startup_frame
   build_credentials_frame
   build_query_frame
   build_prepare_frame
   build_execute_frame
   build_register_frame

   parse_error_frame
   parse_authenticate_frame
   parse_supported_frame
   parse_result_frame
   parse_event_frame
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

use Carp;

use Protocol::CassandraCQL qw( :queryflags :results );
use Protocol::CassandraCQL::Frame;
use Protocol::CassandraCQL::Result;

# The highest version we know about
use constant MAX_VERSION => 2;

=head1 NAME

C<Protocol::CassandraCQL::Frames> - build or parse frame bodies for specific
message types

=head1 SYNOPSIS

 use Protocol::CassandraCQL qw( build_frame );
 use Protocol::CassandraCQL::Frames qw( build_query_frame );

 my $bytes = build_frame( 0x01, 0, $streamid, OPCODE_QUERY,
    build_query_frame( 1,
       cql => "CQL STRING",
       consistency => $consistency
    )->bytes
 );

=head1 DESCRIPTION

This module provides a number of convenient functions to build and parse frame
bodies for specific kinds of C<CQL> message. Each should be paired with a call
to C<build_frame> or C<send_frame> with the appropriate opcode constant, or
invoked after C<parse_frame> or C<recv_frame> has received a frame with the
appropriate opcode.

Each C<build_*> function takes as its first argument the C<CQL> protocol
version (the value that will be passed to C<build_frame> or C<send_frame>).
This value is used to ensure all the correct information is present in the
frame body, and that no optional parameters are passed that the chosen version
of the protocol cannot support.

=cut

=head1 FUNCTIONS

=cut

=head2 $frame = build_startup_frame( $version, options => \%options )

Builds the frame for an C<OPCODE_STARTUP> message. Takes a reference to a hash
of named options. These options should include C<CQL_VERSION>.

=cut

sub build_startup_frame
{
   my ( $version, %params ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   defined( my $options = $params{options} ) or croak "Need 'options'";

   croak "'CQL_VERSION' missing" unless defined $options->{CQL_VERSION};

   return Protocol::CassandraCQL::Frame->new
      ->pack_string_map( $options );
}

=head2 $frame = build_credentials_frame( $version, credentials => \%credentials )

Builds the frame for an C<OPCODE_CREDENTIALS> message. Takes a reference to a
hash of credentials, the exact keys of which will depend on the authenticator
returned by the C<OPCODE_AUTHENTICATE> message.

=cut

sub build_credentials_frame
{
   my ( $version, %params ) = @_;

   # OPCODE_CREDENTIALS is only v1
   croak "Unsupported version" if $version < 1 or $version > 1;

   defined( my $credentials = $params{credentials} ) or croak "Need 'credentials'";

   return Protocol::CassandraCQL::Frame->new
      ->pack_string_map( $credentials );
}

=head2 $frame = build_query_frame( $version, cql => $cql, QUERY_PARAMS )

Builds the frame for an C<OPCODE_QUERY> message. Takes the CQL string and the
query parameters.

C<QUERY_PARAMS> contains the following keys:

=over 4

=item consistency => INT

The consistency level. (required)

=item values => ARRAY of STRING

The encoded byte values of the bind parameters (optional, v2+ only)

=item skip_metadata => BOOL

If true, sets the C<QUERY_SKIP_METADATA> flag. (optional, v2+ only)

=item page_size => INT

The paging size (optional, v2+ only)

=item paging_state => STRING

The paging state from the previous result to a query or execute. (optional,
v2+ only)

=item serial_consistency => INT

The consistency level for CAS serialisation operations (optional, v2+ only)

=back

=cut

# Shared by QUERY and EXECUTE frames at version 2
sub _pack_query_params
{
   my ( $version, $frame, %params ) = @_;

   defined( my $consistency = $params{consistency} ) or croak "Need 'consistency'";

   $frame->pack_short( $consistency );

   if( $version < 2 ) {
      defined $params{$_} and croak "Cannot set '$_' for version 1"
         for qw( values page_size paging_state serial_consistency );
      return $frame;
   }

   my $flags = 0;

   my $values       = $params{values};
   my $page_size    = $params{page_size};
   my $paging_state = $params{paging_state};
   my $ser_cons     = $params{serial_consistency};

   $flags |= QUERY_VALUES            if $values;
   $flags |= QUERY_SKIP_METADATA     if $params{skip_metadata};
   $flags |= QUERY_PAGE_SIZE         if defined $page_size;
   $flags |= QUERY_WITH_PAGING_STATE if defined $paging_state;
   $flags |= QUERY_WITH_SERIAL_CONSISTENCY if defined $ser_cons;

   $frame->pack_byte( $flags );

   if( $values ) {
      $frame->pack_short( scalar @$values );
      $frame->pack_bytes( $_ ) for @$values;
   }

   if( defined $page_size ) {
      $frame->pack_int( $page_size );
   }

   if( defined $paging_state ) {
      $frame->pack_bytes( $paging_state );
   }

   if( defined $ser_cons ) {
      $frame->pack_short( $ser_cons );
   }

   return $frame;
}

sub build_query_frame
{
   my ( $version, %params ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   defined( my $cql = $params{cql} ) or croak "Need 'cql'";

   my $frame = Protocol::CassandraCQL::Frame->new
      ->pack_lstring( $cql );

   _pack_query_params( $version, $frame, %params );

   return $frame;
}

=head2 $frame = build_prepare_frame( $version, cql => $cql )

Builds the frame for an C<OPCODE_PREPARE> message. Takes the CQL string.

=cut

sub build_prepare_frame
{
   my ( $version, %params ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   defined( my $cql = $params{cql} ) or croak "Need 'cql'";

   return Protocol::CassandraCQL::Frame->new
      ->pack_lstring( $cql );
}

=head2 $frame = build_execute_frame( $version, id => $id, QUERY_PARAMS )

Builds the frame for an C<OPCODE_EXECUTE> message. Takes the prepared
statement ID, and the query parameters. C<QUERY_PARAMS> is as for
C<build_query_frame>, except that the C<values> key is required and permitted
even at protocol version 1.

=cut

sub build_execute_frame
{
   my ( $version, %params ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   defined( my $id          = $params{id}          ) or croak "Need 'id'";

   # v1 had a different layout
   defined( my $values      = $params{values}      ) or croak "Need 'values'";
   defined( my $consistency = $params{consistency} ) or croak "Need 'consistency'";

   my $frame = Protocol::CassandraCQL::Frame->new
      ->pack_short_bytes( $id );

   if( $version == 1 ) {
      defined $params{$_} and croak "Cannot set '$_' for version 1"
         for qw( page_size paging_state serial_consistency );
      $frame->pack_short( scalar @$values );
      $frame->pack_bytes( $_ ) for @$values;
      $frame->pack_short( $consistency );
   }
   else {
      _pack_query_params( $version, $frame, %params );
   }

   return $frame;
}

=head2 $frame = build_register_frame( $version, events => \@events )

Builds the frame for an C<OPCODE_REGISTER> message. Takes an ARRAY reference
of strings giving the event names.

=cut

sub build_register_frame
{
   my ( $version, %params ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   defined( my $events = $params{events} ) or croak "Need 'events'";

   return Protocol::CassandraCQL::Frame->new
      ->pack_string_list( $events );
}

=head2 ( $err, $message ) = parse_error_frame( $version, $frame )

Parses the frame from an C<OPCODE_ERROR> message. Returns an error code value
and a string message.

=cut

sub parse_error_frame
{
   my ( $version, $frame ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   return ( $frame->unpack_int,
            $frame->unpack_string );
}

=head2 ( $authenticator ) = parse_authenticate_frame( $version, $frame )

Parses the frame from an C<OPCODE_AUTHENTICATE> message. Returns the
authenticator name as a string.

=cut

sub parse_authenticate_frame
{
   my ( $version, $frame ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   return ( $frame->unpack_string );
}

=head2 ( $options ) = parse_supported_frame( $version, $frame )

Parses the frame from an C<OPCODE_SUPPORTED> message. Returns a HASH reference
mapping option names to ARRAYs of supported values.

=cut

sub parse_supported_frame
{
   my ( $version, $frame ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   return $frame->unpack_string_multimap;
}

=head2 ( $type, $result ) = parse_result_frame( $version, $frame )

Parses the frame from an C<OPCODE_RESULT> message. Returns a type value (one
of the C<TYPE_*> constants), and a value whose interpretation depends on the
type.

=over 4

=item * RESULT_VOID

C<$result> is C<undef>. (This is returned by data modification queries such as
C<INSERT>, C<UPDATE> and C<DELETE>).

=item * RESULT_ROWS

C<$result> is an instance of L<Protocol::CassandraCQL::Result> containing the
row data. (This is returned by C<SELECT> queries).

=item * RESULT_SET_KEYSPACE

C<$result> is a string containing the new keyspace name. (This is returned by
C<USE> queries).

=item * RESULT_PREPARED

C<$result> is an ARRAY reference containing the query ID as a string, and the
bind parameters' metadata as an instance of
L<Protocol::CassandraCQL::ColumnMeta>. For v2+ this will also return the
result metadata as another C<Protocol::CassandraCQL::ColumnMeta> instance.

=item * RESULT_SCHEMA_CHANGE

C<$result> is an ARRAY reference containing three strings, giving the type
of change, the keyspace, and the table name. (This is returned by data
definition queries such as C<CREATE>, C<ALTER> and C<DROP>).

=back

If any other type is encountered, C<$result> will be the C<$frame> object
itself.

=cut

sub parse_result_frame
{
   my ( $version, $frame ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   my $type = $frame->unpack_int;

   if( $type == RESULT_VOID ) {
      return ( $type, undef );
   }
   elsif( $type == RESULT_ROWS ) {
      return ( $type, Protocol::CassandraCQL::Result->from_frame( $frame, $version ) );
   }
   elsif( $type == RESULT_SET_KEYSPACE ) {
      return ( $type, $frame->unpack_string );
   }
   elsif( $type == RESULT_PREPARED ) {
      my $id = $frame->unpack_short_bytes;
      my $params_meta = Protocol::CassandraCQL::ColumnMeta->from_frame( $frame );

      if( $version < 2 ) {
         return ( $type, [
            $id,
            $params_meta
         ] );
      }

      return ( $type, [
         $id,
         $params_meta,
         Protocol::CassandraCQL::ColumnMeta->from_frame( $frame )
      ] );
   }
   elsif( $type == RESULT_SCHEMA_CHANGE ) {
      return ( $type, [ map { $frame->unpack_string } 1 .. 3 ] );
   }
   else {
      return ( $type, $frame );
   }
}

=head2 ( $event, @args ) = parse_event_frame( $version, $frame )

Parses the frame from an C<OPCODE_EVENT> message. Returns the event name and a
list of its arguments; which will vary depending on the event name.

=over 4

=item * TOPOLOGY_CHANGE

C<@args> will contain the change type string and a node inet address

=item * STATUS_CHANGE

C<@args> will contain the status type string and a node inet address

=item * SCHEMA_CHANGE

C<@args> will contain three strings, containing the change type, keyspace,
and table name

=back

If the event name is unrecognised, C<@args> will return just the C<$frame>
object itself.

=cut

sub parse_event_frame
{
   my ( $version, $frame ) = @_;

   croak "Unsupported version" if $version < 1 or $version > MAX_VERSION;

   my $event = $frame->unpack_string;

   if( $event eq "TOPOLOGY_CHANGE" ) {
      return ( $event, $frame->unpack_string, $frame->unpack_inet );
   }
   elsif( $event eq "STATUS_CHANGE" ) {
      return ( $event, $frame->unpack_string, $frame->unpack_inet );
   }
   elsif( $event eq "SCHEMA_CHANGE" ) {
      return ( $event, map { $frame->unpack_string } 1 .. 3 );
   }
   else {
      return ( $event, $frame );
   }
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
