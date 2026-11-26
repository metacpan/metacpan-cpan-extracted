##############################################################################
#
#  Net::Tools::Socket::Protocols perl module
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
#  Net::Tools::Socket::Protocols is ported from Decor's
#  Decor::Shared::Net::Protocols: https://github.com/cade-vs/perl-decor
#
##############################################################################
package Net::Tools::Socket::Protocols;
use strict;
use Exporter;
use Carp;
use Data::Tools;
use Net::Tools::Socket;
use Net::Tools::Socket::Err;

our $VERSION = '1.60';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  socket_protocol_read_message
                  socket_protocol_write_message

                  socket_protocols_allow
                );

our %EXPORT_TAGS = (
                   'all'  => \@EXPORT,
                   'none' => [],
                   );

my %PROTOCOL_TYPES = (
                  'b' => {
                         # binary. does not require anything
                         },
                  'p' => {
                         'require' => 'Storable',
                         'pack'    => \&protocol_type_storable_pack,
                         'unpack'  => \&protocol_type_storable_unpack,
                         },
                  'e' => {
                         'require' => 'Sereal',
                         'pack'    => \&protocol_type_sereal_pack,
                         'unpack'  => \&protocol_type_sereal_unpack,
                         },
                  's' => {
                         'require' => 'Data::Stacker',
                         'pack'    => \&protocol_type_stacker_pack,
                         'unpack'  => \&protocol_type_stacker_unpack,
                         },
                  'j' => {
                         'require' => 'JSON',
                         'pack'    => \&protocol_type_json_pack,
                         'unpack'  => \&protocol_type_json_unpack,
                         },
                  'h' => {
                         'require' => undef,
                         'pack'    => \&protocol_type_hash_pack,
                         'unpack'  => \&protocol_type_hash_unpack,
                         },
                  'H' => {
                         'require' => undef,
                         'pack'    => \&protocol_type_hash_url_pack,
                         'unpack'  => \&protocol_type_hash_url_unpack,
                         },
                  );

my %PROTOCOL_ALLOW = map { $_ => 1 } keys %PROTOCOL_TYPES;
delete $PROTOCOL_ALLOW{ 'p' }; # Storable, sadly, is reported unsafe

sub socket_protocol_read_message
{
  my $socket  = shift;
  my $timeout = shift;
  my $maxlen  = shift;

  # socket_read_message() clears and sets $SOCK_ERR
  my $data = socket_read_message( $socket, $timeout, $maxlen ) // return undef;
  my $data_read_len = length( $data );

  return sock_err( SOCK_E_EMPTY ) if $data_read_len < 1; # no protocol type and payload

  my $ptype = substr( $data, 0, 1 );

  return sock_err( SOCK_E_PROTO, undef, "unknown or forbidden PROTOCOL_TYPE [hex:" . str_hex( $ptype ) . "]" ) unless exists $PROTOCOL_ALLOW{ $ptype };

  my $hr;
  if( $ptype eq 'b' )
    {
    # no unpack for binary messages payload
    $hr = substr( $data, 1 );
    }
  else
    {
    local $@;
    $hr = eval { $PROTOCOL_TYPES{ $ptype }->{ 'unpack' }->( substr( $data, 1 ) ) };
    my $err = eval_err_strip( $@ ) || ( ref( $hr ) eq 'HASH' ? undef : 'invalid data, expected HASH reference' );
    return sock_err( SOCK_E_PROTO, undef, $err ) if $err;
    }

  return wantarray ? ( $hr, $ptype ) : $hr;
}

sub socket_protocol_write_message
{
  my $socket  = shift;
  my $ptype   = shift;
  my $hr      = shift; # hash reference or plain data if proto is 'b'inary
  my $timeout = shift;

  sock_err_clear();

  #FIXME: str_hex() wraps a wide character type to its low byte, "\x{16a}" shows as [hex:6a]
  return sock_err( SOCK_E_PROTO, undef, "unknown or forbidden PROTOCOL_TYPE [hex:" . str_hex( $ptype ) . "]" ) unless length( $ptype ) == 1 and exists $PROTOCOL_ALLOW{ $ptype };

  my $data;

  if( $ptype eq 'b' )
    {
    return sock_err( SOCK_E_INVAL ) if ref( $hr );
    # no pack for binary messages payload
    $data = $ptype . $hr;
    }
  else
    {
    return sock_err( SOCK_E_INVAL ) unless ref( $hr ) eq 'HASH';
    local $@;
    my $packed = eval { $PROTOCOL_TYPES{ $ptype }->{ 'pack' }->( $hr ) };
    return sock_err( SOCK_E_PROTO, undef, eval_err_strip( $@ ) ) if $@;
    $data = $ptype . $packed;
    }

  return socket_write_message( $socket, $data, $timeout );
}


sub socket_protocols_allow
{
  my @p = split //, join '', @_;
  my %p;
  for my $ptype ( @p )
    {
    if( $ptype eq '*' )
      {
      %p = map { $_ => 1 } keys %PROTOCOL_TYPES;
      delete $p{ 'p' }; # Storable, sadly, is reported unsafe
      }
    else
      {
      confess( "unknown PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', sort keys %PROTOCOL_TYPES ) . "]" ) unless exists $PROTOCOL_TYPES{ $ptype };
      $p{ $ptype }++;
      }
    }
  %PROTOCOL_ALLOW = %p;
  return 1;
}

my %PROTOCOL_LOADED;
sub load_protocol
{
  my $ptype = shift;
  return 1 if exists $PROTOCOL_LOADED{ $ptype };
  confess( "unknown or forbidden PROTOCOL_TYPE requested [$ptype] expected one of [" . join( ',', sort keys %PROTOCOL_ALLOW ) . "]" ) unless exists $PROTOCOL_ALLOW{ $ptype };

  my $req = $PROTOCOL_TYPES{ $ptype }{ 'require' };
  if( $req )
    {
    local $@;
    eval { my $fn = perl_package_to_file( $req ); require $fn; };
    confess( $@ ) if $@;
    }
  $PROTOCOL_LOADED{ $ptype }++;
  return 2;
}


sub protocol_type_storable_pack
{
  load_protocol( 'p' );
  return Storable::nfreeze( shift );
}

sub protocol_type_storable_unpack
{
  load_protocol( 'p' );
  return Storable::thaw( shift(), 0 ); # do not allow bless and tie
}

sub protocol_type_sereal_pack
{
  load_protocol( 'e' );
  return Sereal::encode_sereal( shift );
}

sub protocol_type_sereal_unpack
{
  load_protocol( 'e' );
  return Sereal::decode_sereal( shift );
}

sub protocol_type_stacker_pack
{
  load_protocol( 's' );
  return Data::Stacker::stack_data( shift );
}

sub protocol_type_stacker_unpack
{
  load_protocol( 's' );
  return Data::Stacker::unstack_data( shift );
}

sub protocol_type_json_pack
{
  load_protocol( 'j' );
  return JSON::encode_json( shift );
}

sub protocol_type_json_unpack
{
  load_protocol( 'j' );
  return JSON::decode_json( shift );
}

sub protocol_type_hash_pack
{
  load_protocol( 'h' );
  return hash2str( shift );
}

sub protocol_type_hash_unpack
{
  load_protocol( 'h' );
  return str2hash( shift );
}

sub protocol_type_hash_url_pack
{
  load_protocol( 'H' );
  return hash2str_url( shift );
}

sub protocol_type_hash_url_unpack
{
  load_protocol( 'H' );
  return str2hash_url( shift );
}

##############################################################################

=pod


=head1 NAME

Net::Tools::Socket::Protocols - transparent serialization on top of the Net::Tools::Socket message functions

=head1 SYNOPSIS

  use Net::Tools::Socket::Protocols qw( :all );  # import all functions
  use Net::Tools::Socket::Protocols;             # the same as :all :)
  use Net::Tools::Socket::Protocols qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  # send a hash reference, serialized with the 'j'son protocol
  socket_protocol_write_message( $socket, 'j', $hash_ref, $timeout );

  # read it back, the protocol type is taken from the message itself
  my $hash_ref = socket_protocol_read_message( $socket, $timeout, $maxlen );

  # in list context the protocol type is returned too, to reply in the same type
  my ( $hash_ref, $ptype ) = socket_protocol_read_message( $socket, $timeout );

  # error details
  use Net::Tools::Socket::Err;
  print "error: $SOCK_ERRSTR\n" unless defined $hash_ref;

  # the 'b'inary protocol carries plain data instead of a hash reference
  socket_protocol_write_message( $socket, 'b', $raw_data, $timeout );

  # --------------------------------------------------------------------------

  # restrict which protocol types will be accepted and sent
  socket_protocols_allow( 'bjh' );      # only binary, json and hash
  socket_protocols_allow( 'b', 'jh' );  # the same, arguments are concatenated
  socket_protocols_allow( '*' );        # all types again, except 'p' Storable
  socket_protocols_allow( '*p' );       # really all types, including Storable

  # --------------------------------------------------------------------------

=head1 PROTOCOL TYPES

A protocol type is a single character, sent as the first byte of every
message. The rest of the message is the payload, serialized accordingly:

  'b'  binary,        payload is plain data, not a hash reference
  'p'  Storable       (nfreeze/thaw), forbidden by default, see below
  'e'  Sereal
  's'  Data::Stacker
  'j'  JSON
  'h'  hash2str()     from Data::Tools, needs no extra module
  'H'  hash2str_url() from Data::Tools, needs no extra module

Except for 'b', the payload is always a hash reference.

The module needed by a protocol type is loaded on demand, the first time
that type is actually used, so a missing module is only a problem if the
corresponding protocol type is used. 'b', 'h' and 'H' need no extra module.

'p' Storable is not safe on untrusted input, so it is forbidden by default
and is not allowed by '*' either. It must be allowed explicitly with
socket_protocols_allow(), only when both peers are trusted.

  NOTE: Storable is a core module and JSON is already required by
        Data::Tools, so those modules are always installed ('p' still
        has to be allowed first). Sereal and Data::Stacker are not
        required by this distribution and may need to be installed
        separately.

=head1 FUNCTIONS

=head2 socket_protocol_write_message( $socket, $ptype, $data, $timeout )

Serializes $data according to the $ptype protocol type, prefixes it with the
protocol type character and sends it with socket_write_message().

$data must be a hash reference, unless $ptype is 'b', in which case it is
plain data (a string, not a reference).

$timeout is passed to socket_write_message(), see L<Net::Tools::Socket>.

Returns 1 on success or undef if the message could not be sent, with
$SOCK_ERR set (see L</ERRORS>):

  SOCK_E_PROTO   $ptype is not a single known and allowed protocol type,
                 or serializing failed (including a missing serializer
                 module), details in $SOCK_ERRSTR
  SOCK_E_INVAL   $data is not a hash reference for a non-binary protocol
                 type, or is a reference or has wide characters for 'b'
  ...            any socket_write_message() error

On a socket_write_message() error the stream may be out of sync, see
L<Net::Tools::Socket>.

WARNING! Writing to a socket closed by the peer raises SIGPIPE, which kills
the process by default. The caller must set C<$SIG{ 'PIPE' } = 'IGNORE'>,
see socket_write() in L<Net::Tools::Socket>.

=head2 socket_protocol_read_message( $socket, $timeout, $maxlen )

Reads a message with socket_read_message(), takes the protocol type from its
first byte and deserializes the rest accordingly.

$timeout and $maxlen are passed to socket_read_message(), see
L<Net::Tools::Socket>. $maxlen limits the whole message, including the
protocol type byte.

Returns the deserialized hash reference, or the plain data for 'b' ("" if
the 'b' message has no payload), or undef on error with $SOCK_ERR set (see
L</ERRORS>):

  SOCK_E_EMPTY   the message is empty, it has no protocol type byte
  SOCK_E_PROTO   the protocol type is not known or not allowed, or the
                 payload does not deserialize into a hash reference
                 (including an empty payload and a missing deserializer
                 module), details in $SOCK_ERRSTR
  ...            any socket_read_message() error

After SOCK_E_EMPTY and SOCK_E_PROTO the socket stream is still in sync (the
whole message was read), so the socket may be used further.

In list context it returns the data and the protocol type character of the
message, for example to reply in the same protocol type:

  my ( $hash_ref, $ptype ) = socket_protocol_read_message( $socket, $timeout );
  socket_protocol_write_message( $socket, $ptype, $reply_ref, $timeout ) if $hash_ref;

On error it returns a single undef in list context too, so both $hash_ref
and $ptype are undef.

NOTE: arguments of a function without a prototype, such as Test::More's
is_deeply(), are evaluated in list context, use scalar() there to get the
data only.

=head2 socket_protocols_allow( @protocol_types )

Sets which protocol types will be accepted and sent, replacing the previous
set. The arguments are concatenated and then split into single characters,
so these are the same:

  socket_protocols_allow( 'bjh' );
  socket_protocols_allow( 'b', 'j', 'h' );

'*' stands for all known protocol types except 'p'. It replaces everything
before it, so 'j*' is the same as '*', and types after it are added, so
'*p' allows all types including 'p'.

Called with no arguments (or only empty strings) it forbids all protocol
types, no message can be sent or accepted until it is called again.

By default all protocol types except 'p' are allowed.

Returns 1. Confesses if an unknown protocol type is given, in which case
the allowed set is not changed.

=head1 ERRORS

Both read and write functions clear $SOCK_ERR and $SOCK_ERRSTR on entry and
set them on failure. They are exported by L<Net::Tools::Socket::Err>, which
must be used by the caller to read them. See also L<Net::Tools::Socket>.

=head1 REQUIRED MODULES

Net::Tools::Socket::Protocols uses:

  * Data::Tools
  * Net::Tools::Socket
  * Net::Tools::Socket::Err

and, on demand and only for the corresponding protocol types:

  * Storable, Sereal, Data::Stacker, JSON

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-net-tools.git

  git clone https://github.com/cade-vs/perl-net-tools.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

##############################################################################
1;
