#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL;

use strict;
use warnings;

our $VERSION = '0.12';

use Exporter 'import';
our @EXPORT_OK = qw(
   parse_frame recv_frame
   build_frame send_frame
   lookup_consistency
);

=head1 NAME

C<Protocol::CassandraCQL> - wire protocol support functions for Cassandra CQL

=head1 DESCRIPTION

This module provides the basic constants and other support functions required
to communicate with a Cassandra database using C<CQL>. It is not in itself a
CQL client; it simply provides the necessary support functions to allow one to
be written. It supports the additions added by C<CQL> version 2.

For a complete client, see instead L<Net::Async::CassandraCQL>.

=cut

=head1 CONSTANTS

The following families of constants are defined, along with export tags:

=head2 FLAG_* (:flags)

Bitmask of flags used in message frames.

=head2 OPCODE_* (:opcodes)

Opcodes used in message frames.

=head2 QUERY_* (:queryflags)

Flag constants used in C<OPCODE_QUERY> frames.

=head2 BATCH_* (:batches)

Type constants used in C<OPCODE_BATCH> frames.

=head2 RESULT_* (:results)

Result codes used in C<OPCODE_RESULT> frames.

=head2 ROWS_* (:rowflags)

Flag constants used in C<RESULT_ROWS> frames.

=head2 TYPE_* (:types)

Type codes used in C<TYPE_ROWS> and C<TYPE_PREPARED> column metadata.

=head2 CONSISTENCY_* (:consistencies)

Consistency levels used in C<OPCODE_QUERY> and C<OPCODE_EXECUTE> frames.

=cut

# See also
#   https://github.com/apache/cassandra/blob/cassandra-1.2/doc/native_protocol.spec

my %CONSTANTS = (
   FLAG_COMPRESS => 0x01,
   FLAG_TRACE    => 0x02,

   OPCODE_ERROR        => 0x00,
   OPCODE_STARTUP      => 0x01,
   OPCODE_READY        => 0x02,
   OPCODE_AUTHENTICATE => 0x03,
   OPCODE_CREDENTIALS  => 0x04,
   OPCODE_OPTIONS      => 0x05,
   OPCODE_SUPPORTED    => 0x06,
   OPCODE_QUERY        => 0x07,
   OPCODE_RESULT       => 0x08,
   OPCODE_PREPARE      => 0x09,
   OPCODE_EXECUTE      => 0x0A,
   OPCODE_REGISTER     => 0x0B,
   OPCODE_EVENT        => 0x0C,
   OPCODE_BATCH        => 0x0D,
   OPCODE_AUTH_CHALLENGE => 0x0E,
   OPCODE_AUTH_RESPONSE  => 0x0F,
   OPCODE_AUTH_SUCCESS   => 0x10,

   QUERY_VALUES                  => 0x0001,
   QUERY_SKIP_METADATA           => 0x0002,
   QUERY_PAGE_SIZE               => 0x0004,
   QUERY_WITH_PAGING_STATE       => 0x0008,
   QUERY_WITH_SERIAL_CONSISTENCY => 0x0010,

   BATCH_LOGGED   => 0,
   BATCH_UNLOGGED => 1,
   BATCH_COUNTER  => 2,

   RESULT_VOID          => 0x0001,
   RESULT_ROWS          => 0x0002,
   RESULT_SET_KEYSPACE  => 0x0003,
   RESULT_PREPARED      => 0x0004,
   RESULT_SCHEMA_CHANGE => 0x0005,

   ROWS_HAS_GLOBALTABLESPEC => 0x0001,
   ROWS_HAS_MORE_PAGES      => 0x0002,
   ROWS_NO_METADATA         => 0x0004,

   TYPE_CUSTOM    => 0x0000,
   TYPE_ASCII     => 0x0001,
   TYPE_BIGINT    => 0x0002,
   TYPE_BLOB      => 0x0003,
   TYPE_BOOLEAN   => 0x0004,
   TYPE_COUNTER   => 0x0005,
   TYPE_DECIMAL   => 0x0006,
   TYPE_DOUBLE    => 0x0007,
   TYPE_FLOAT     => 0x0008,
   TYPE_INT       => 0x0009,
   TYPE_TEXT      => 0x000A,
   TYPE_TIMESTAMP => 0x000B,
   TYPE_UUID      => 0x000C,
   TYPE_VARCHAR   => 0x000D,
   TYPE_VARINT    => 0x000E,
   TYPE_TIMEUUID  => 0x000F,
   TYPE_INET      => 0x0010,
   TYPE_LIST      => 0x0020,
   TYPE_MAP       => 0x0021,
   TYPE_SET       => 0x0022,

   CONSISTENCY_ANY          => 0x0000,
   CONSISTENCY_ONE          => 0x0001,
   CONSISTENCY_TWO          => 0x0002,
   CONSISTENCY_THREE        => 0x0003,
   CONSISTENCY_QUORUM       => 0x0004,
   CONSISTENCY_ALL          => 0x0005,
   CONSISTENCY_LOCAL_QUORUM => 0x0006,
   CONSISTENCY_EACH_QUORUM  => 0x0007,
   CONSISTENCY_SERIAL       => 0x0008,
   CONSISTENCY_LOCAL_SERIAL => 0x0009,
   CONSISTENCY_LOCAL_ONE    => 0x000A,
);

require constant;
constant->import( $_, $CONSTANTS{$_} ) for keys %CONSTANTS;
push @EXPORT_OK, keys %CONSTANTS;

our %EXPORT_TAGS = (
   'flags'         => [ grep { m/^FLAG_/        } keys %CONSTANTS ],
   'opcodes'       => [ grep { m/^OPCODE_/      } keys %CONSTANTS ],
   'queryflags'    => [ grep { m/^QUERY_/       } keys %CONSTANTS ],
   'batches'       => [ grep { m/^BATCH_/       } keys %CONSTANTS ],
   'results'       => [ grep { m/^RESULT_/      } keys %CONSTANTS ],
   'rowflags'      => [ grep { m/^ROWS_/        } keys %CONSTANTS ],
   'types'         => [ grep { m/^TYPE_/        } keys %CONSTANTS ],
   'consistencies' => [ grep { m/^CONSISTENCY_/ } keys %CONSTANTS ],
);

=head1 FUNCTIONS

=cut

=head2 ( $version, $flags, $streamid, $opcode, $body ) = parse_frame( $bytes )

Attempts to parse a complete message frame from the given byte string. If it
succeeds, it returns the header fields and the body as an opaque byte string.
If it fails, it returns an empty list.

If successful, it will remove the bytes of the message from the C<$bytes>
scalar, which must therefore be mutable.

=cut

sub parse_frame
{
   return unless length $_[0] >= 8; # header length

   my $bodylen = unpack( "x4 N", $_[0] );
   return unless length $_[0] >= 8 + $bodylen;

   # Now committed to extracting a frame
   my ( $version, $flags, $streamid, $opcode ) = unpack( "C C C C x4", substr $_[0], 0, 8, "" );
   my $body = substr $_[0], 0, $bodylen, "";

   return ( $version, $flags, $streamid, $opcode, $body );
}

=head2 ( $version, $flags, $streamid, $opcode, $body ) = recv_frame( $fh )

Attempts to read a complete frame from the given filehandle, blocking until it
is available. If an IO error happens, returns an empty list. The results are
undefined if this method is called on a non-blocking filehandle.

=cut

sub recv_frame
{
   my ( $fh ) = @_;

   $fh->read( my $header, 8 ) or return;
   my ( $version, $flags, $streamid, $opcode, $bodylen ) = unpack( "C C C C N", $header );

   my $body = "";
   $fh->read( $body, $bodylen ) or return if $bodylen;

   return ( $version, $flags, $streamid, $opcode, $body );
}

=head2 $bytes = build_frame( $version, $flags, $streamid, $opcode, $body )

Returns a byte string containing a complete message with the given fields as
the header and body.

=cut

sub build_frame
{
   my ( $version, $flags, $streamid, $opcode, $body ) = @_;

   return pack "C C C C N a*", $version, $flags, $streamid, $opcode, length $body, $body;
}

=head2 send_frame( $fh, $version, $flags, $streamid, $opcode, $body )

Sends a complete frame to the given filehandle.

=cut

sub send_frame
{
   my $fh = shift;
   $fh->print( build_frame( @_ ) );
}

=head2 $consistency = lookup_consistency( $name )

Returns the C<CONSISTENCY_*> value for the given name (without the initial
C<CONSISTENCY_> prefix).

=cut

my %consvals = map { substr($_, 12) => __PACKAGE__->$_ } grep { m/^CONSISTENCY_/ } keys %CONSTANTS;

sub lookup_consistency
{
   my ( $name ) = @_;
   return $consvals{$name};
}

=head2 $name = typename( $type )

Returns the name of the given C<TYPE_*> value, without the initial C<TYPE_>
prefix.

=cut

my %typevals = map { substr($_, 5) => __PACKAGE__->$_ } grep { m/^TYPE_/ } keys %CONSTANTS;
my %typenames = reverse %typevals;

sub typename
{
   my ( $type ) = @_;
   return $typenames{$type};
}

=head1 TODO

=over 8

=item *

Reimplement L<Protocol::CassandraCQL::Frame> in XS code for better
performance.

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
