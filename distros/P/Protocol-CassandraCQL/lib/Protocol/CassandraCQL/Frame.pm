#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL::Frame;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;

use Encode qw( encode_utf8 decode_utf8 );
use Socket qw( AF_INET AF_INET6 );

# TODO: At least the lower-level methods of this class should be rewritten in
# efficient XS code

=head1 NAME

C<Protocol::CassandraCQL::Frame> - a byte buffer storing the content of a CQL message frame

=head1 DESCRIPTION

This class provides wire-protocol encoding and decoding support for
constructing and parsing Cassandra CQL message frames. An object represents a
buffer during construction or parsing.

To construct a message frame, create a new empty object and use the C<pack_*>
methods to append data to it, before eventually obtaining the actual frame
bytes using C<bytes>. Each C<pack_*> method returns the frame object, allowing
them to be easily chained:

 my $bytes = Protocol::CassandraCQL::Frame->new
    ->pack_short( 123 )
    ->pack_int( 45678 )
    ->pack_string( "here is the data" )
    ->bytes;

To parse a message frame, create a new object from the bytes in the message,
and use the C<unpack_*> methods to consume the values from it.

 my $frame = Protocol::CassandraCQL::Frame->new( $bytes );
 my $s   = $frame->unpack_short;
 my $i   = $frame->unpack_int;
 my $str = $frame->unpack_string;

=cut

=head1 CONSTRUCTOR

=head2 $frame = Protocol::CassandraCQL::Frame->new( $bytes )

Returns a new frame buffer, optionally initialised with the given byte string.

=cut

sub new
{
   my $class = shift;
   my $bytes = "";
   $bytes = $_[0] if defined $_[0];
   bless \$bytes, $class;
}

=head1 METHODS

=cut

# Legacy back-compat methods
# DO NOT USE THESE - see Protocol::CassandraCQL::parse_frame and ::build_frame instead

sub parse
{
   shift; # class
   my ( $version, $flags, $id, $opcode, $body ) = Protocol::CassandraCQL::parse_frame( $_[0] )
      or return;
   return ( $version, $flags, $id, $opcode, Protocol::CassandraCQL::Frame->new( $body ) );
}

sub build
{
   my $self = shift;
   return Protocol::CassandraCQL::build_frame( @_[0..3], $self->bytes );
}

=head2 $bytes = $frame->bytes

Returns the byte string currently in the buffer.

=cut

sub bytes { ${$_[0]} }

=head2 $frame->pack_byte( $v )

=head2 $v = $frame->unpack_byte

Add or remove a byte value.

=cut

sub pack_byte   { my ( $self, $v ) = @_;
                  $$self .= pack "C", $v;
                  $self }
sub unpack_byte { my ( $self ) = @_;
                  unpack "C", substr $$self, 0, 1, "" }

=head2 $frame->pack_short( $v )

=head2 $v = $frame->unpack_short

Add or remove a short value.

=cut

sub pack_short { my ( $self, $v ) = @_;
                 $$self .= pack "S>", $v;
                 $self }
sub unpack_short { my ( $self ) = @_;
                   unpack "S>", substr $$self, 0, 2, "" }

=head2 $frame->pack_int( $v )

=head2 $v = $frame->unpack_int

Add or remove an int value.

=cut

sub pack_int { my ( $self, $v ) = @_;
               $$self .= pack "l>", $v;
               $self }
sub unpack_int { my ( $self ) = @_;
                 unpack "l>", substr $$self, 0, 4, "" }

=head2 $frame->pack_string( $v )

=head2 $v = $frame->unpack_string

Add or remove a string value.

=cut

sub pack_string { my ( $self, $v ) = @_;
                  my $b = encode_utf8( $v );
                  $self->pack_short( length $b );
                  $$self .= $b;
                  $self }
sub unpack_string { my ( $self ) = @_;
                    my $l = $self->unpack_short;
                    decode_utf8( substr $$self, 0, $l, "" ) }

=head2 $frame->pack_lstring( $v )

=head2 $v = $frame->unpack_lstring

Add or remove a long string value.

=cut

sub pack_lstring { my ( $self, $v ) = @_;
                   my $b = encode_utf8( $v );
                   $self->pack_int( length $b );
                   $$self .= $b;
                   $self }
sub unpack_lstring { my ( $self ) = @_;
                     my $l = $self->unpack_int;
                     decode_utf8( substr $$self, 0, $l, "" ) }

=head2 $frame->pack_uuid( $v )

=head2 $v = $frame->unpack_uuid

Add or remove a UUID as a plain 16-byte raw scalar

=cut

sub pack_uuid { my ( $self, $v ) = @_;
                $$self .= pack "a16", $v;
                $self }
sub unpack_uuid { my ( $self ) = @_;
                  substr $$self, 0, 16, "" }

=head2 $frame->pack_string_list( $v )

=head2 $v = $frame->unpack_string_list

Add or remove a list of strings from or to an ARRAYref

=cut

sub pack_string_list { my ( $self, $v ) = @_;
                       $self->pack_short( scalar @$v );
                       $self->pack_string($_) for @$v;
                       $self }
sub unpack_string_list { my ( $self ) = @_;
                         my $n = $self->unpack_short;
                         [ map { $self->unpack_string } 1 .. $n ] }

=head2 $frame->pack_bytes( $v )

=head2 $v = $frame->unpack_bytes

Add or remove opaque bytes or C<undef>.

=cut

sub pack_bytes { my ( $self, $v ) = @_;
                 if( defined $v ) { $self->pack_int( length $v ); $$self .= $v }
                 else             { $self->pack_int( -1 ) }
                 $self }
sub unpack_bytes { my ( $self ) = @_;
                   my $l = $self->unpack_int;
                   $l > 0 ? substr $$self, 0, $l, "" : undef }

=head2 $frame->pack_short_bytes( $v )

=head2 $v = $frame->unpack_short_bytes

Add or remove opaque short bytes.

=cut

sub pack_short_bytes { my ( $self, $v ) = @_;
                       $self->pack_short( length $v );
                       $$self .= $v;
                       $self }
sub unpack_short_bytes { my ( $self ) = @_;
                         my $l = $self->unpack_short;
                         substr $$self, 0, $l, "" }

=head2 $frame->pack_inet( $v )

=head2 $v = $frame->unpack_inet

Add or remove an IPv4 or IPv6 address from or to a packed sockaddr string
(such as returned from C<pack_sockaddr_in> or C<pack_sockaddr_in6>.

=cut

sub pack_inet { my ( $self, $v ) = @_;
                my $family = Socket::sockaddr_family($v);
                if   ( $family == AF_INET  ) { $$self .= "\x04"; $self->_pack_inet4( $v ) }
                elsif( $family == AF_INET6 ) { $$self .= "\x10"; $self->_pack_inet6( $v ) }
                else { croak "Expected AF_INET or AF_INET6 address" }
                $self }
sub unpack_inet { my ( $self ) = @_;
                  my $addrlen = unpack "C", substr $$self, 0, 1, "";
                  if   ( $addrlen ==  4 ) { $self->_unpack_inet4 }
                  elsif( $addrlen == 16 ) { $self->_unpack_inet6 }
                  else { croak "Expected address length 4 or 16" } }

# AF_INET
sub _pack_inet4 { my ( $self, $v ) = @_;
                  my ( $port, $addr ) = Socket::unpack_sockaddr_in( $v );
                  $$self .= $addr; $self->pack_int( $port ) }
sub _unpack_inet4 { my ( $self ) = @_;
                    my $addr = substr $$self, 0, 4, "";
                    Socket::pack_sockaddr_in( $self->unpack_int, $addr ) }

# AF_INET6
sub _pack_inet6 { my ( $self, $v ) = @_;
                  my ( $port, $addr ) = Socket::unpack_sockaddr_in6( $v );
                  $$self .= $addr; $self->pack_int( $port ) }
sub _unpack_inet6 { my ( $self ) = @_;
                    my $addr = substr $$self, 0, 16, "";
                    Socket::pack_sockaddr_in6( $self->unpack_int, $addr ) }

=head2 $frame->pack_string_map( $v )

=head2 $v = $frame->unpack_string_map

Add or remove a string map from or to a HASH of strings.

=cut

# Don't strictly need to sort the keys but it's nice for unit testing
sub pack_string_map { my ( $self, $v ) = @_;
                      $self->pack_short( scalar keys %$v );
                      $self->pack_string( $_ ), $self->pack_string( $v->{$_} ) for sort keys %$v;
                      $self }
sub unpack_string_map { my ( $self ) = @_;
                        my $n = $self->unpack_short;
                        +{ map { $self->unpack_string => $self->unpack_string } 1 .. $n } }

=head2 $frame->pack_string_multimap( $v )

=head2 $v = $frame->unpack_string_multimap

Add or remove a string multimap from or to a HASH of ARRAYs of strings.

=cut

sub pack_string_multimap { my ( $self, $v ) = @_;
                           $self->pack_short( scalar keys %$v );
                           $self->pack_string( $_ ), $self->pack_string_list( $v->{$_} ) for sort keys %$v;
                           $self }
sub unpack_string_multimap { my ( $self ) = @_;
                             my $n = $self->unpack_short;
                             +{ map { $self->unpack_string => $self->unpack_string_list } 1 .. $n } }

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
