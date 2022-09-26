package Protocol::Dqlite;

use strict;
use warnings;

our $VERSION = '0.02';

# https://dqlite.io/docs/protocol
# https://github.com/canonical/dqlite/blob/master/src/request.h
# https://github.com/canonical/dqlite/blob/master/src/response.h

=encoding utf-8

=head1 NAME

Protocol::Dqlite - L<Dqlite|https://dqlite.io> in Perl

=head1 SYNOPSIS

    use autodie;

    my $dqlite = Protocol::Dqlite->new();

    my $socket = IO::Socket::INET->new('127.0.0.1:9001') or die;

    syswrite $s, Protocol::Dqlite::handshake();

    # Register ourselves as a Dqlite client:
    syswrite $s, Protocol::Dqlite::request( Protocol::Dqlite::REQUEST_CLIENT, 0 );

    # Await the server’s acknowledgement:
    while (sysread $s, my $buf, 512) {
        my ($msg) = $dqlite->feed($buf);
        next if !$msg;

        last if $msg isa Protocol::Dqlite::Response::WELCOME;

        # An unexpected response. Better bail out …
        #
        require Data::Dumper;
        die Data::Dumper::Dumper($msg);
    }

… and now you can exchange messages as you wish.

=head1 DESCRIPTION

This module implements message parsing and creation for
L<Dqlite|https://dqlite.io> clients. To use this module you’ll need to
write the I/O logic yourself.

=head1 CHARACTER ENCODING

Strings designated as “blob”s are I<byte> strings.

All other strings into & out of this module are I<character> strings.

Decode & encode accordingly.

=cut

use Carp ();

my ( $PACK_STRING, $PACK_U64, $PACK_I64, $PACK_ALIGN_U64 );

BEGIN {
    $PACK_ALIGN_U64 = 'x![q]';
    $PACK_STRING    = "Z* $PACK_ALIGN_U64";
    $PACK_U64       = 'Q<';
    $PACK_I64       = 'q<';

    eval { pack $PACK_U64 } or Carp::croak "64-bit perl is required!";
}

use constant {
    _PROTOCOL_VERSION => 1,

    _HEADER_TEMPLATE => 'V C x3',

    _U64_LEN => length( pack $PACK_U64 ),

    TUPLE_INT64   => 1,
    TUPLE_FLOAT   => 2,
    TUPLE_STRING  => 3,
    TUPLE_BLOB    => 4,
    TUPLE_NULL    => 5,
    TUPLE_UNIXTIME => 9,
    TUPLE_ISO8601 => 10,
    TUPLE_BOOLEAN => 11,

    REQUEST_LEADER => 0,
    REQUEST_CLIENT => 1,

    #REQUEST_HEARTBEAT => 2,
    REQUEST_OPEN      => 3,
    REQUEST_PREPARE   => 4,
    REQUEST_EXEC      => 5,
    REQUEST_QUERY     => 6,
    REQUEST_FINALIZE  => 7,
    REQUEST_EXEC_SQL  => 8,
    REQUEST_QUERY_SQL => 9,
    REQUEST_INTERRUPT => 10,
    REQUEST_CONNECT   => 11,
    REQUEST_ADD       => 12,
    REQUEST_ASSIGN    => 13,
    REQUEST_REMOVE    => 14,
    REQUEST_DUMP      => 15,
    REQUEST_CLUSTER   => 16,

};

use constant {
    _HEADER_SIZE => length pack(_HEADER_TEMPLATE),
    handshake => pack( $PACK_U64, _PROTOCOL_VERSION ),
};

my $_NODE_INFO_TEMPLATE = "$PACK_U64 $PACK_STRING $PACK_U64";

my @REQUEST_PACK;
@REQUEST_PACK[
  REQUEST_LEADER,
  REQUEST_CLIENT,
  REQUEST_OPEN,
  REQUEST_PREPARE,

  REQUEST_EXEC,
  REQUEST_QUERY,
  REQUEST_FINALIZE,
  REQUEST_EXEC_SQL,

  REQUEST_QUERY_SQL,
  REQUEST_INTERRUPT,
  REQUEST_CONNECT,
  REQUEST_ADD,

  REQUEST_ASSIGN,
  REQUEST_REMOVE,
  REQUEST_DUMP,
  REQUEST_CLUSTER,
  ]
  = (
    $PACK_U64,
    $PACK_U64,
    "$PACK_STRING $PACK_U64 $PACK_STRING",
    "$PACK_U64 $PACK_STRING",

    'V V',    # plus tuple
    'V V',    # plus tuple
    'V V',    # no tuple
    "$PACK_U64 $PACK_STRING",

    "$PACK_U64 $PACK_STRING",
    $PACK_U64,
    $_NODE_INFO_TEMPLATE,
    $_NODE_INFO_TEMPLATE,

    $PACK_U64,
    $PACK_U64,
    $PACK_STRING,
    $PACK_U64,
  );

my $PACK_DQLITE_BLOB = "$PACK_U64/a $PACK_ALIGN_U64";

my @TUPLE_PACK;
@TUPLE_PACK[    #
  TUPLE_INT64,
  TUPLE_FLOAT,
  TUPLE_STRING,
  TUPLE_BLOB,
  TUPLE_NULL,
  TUPLE_UNIXTIME,
  TUPLE_ISO8601,
  TUPLE_BOOLEAN,
  ]
  = (           #
    $PACK_I64,
    'd<',
    $PACK_STRING,
    $PACK_DQLITE_BLOB,
    "x[$PACK_U64]",
    $PACK_I64,
    $PACK_STRING,
    $PACK_U64,
  );

my @TUPLE_PACK_LENGTH = map { $_ && length pack $_ } @TUPLE_PACK;
my %TUPLE_PACK_LENGTH_VARIADIC =
  map { $_ => 1 } ( TUPLE_STRING, TUPLE_BLOB, TUPLE_ISO8601 );

my $TUPLE_BLOB_BASE_LENGTH = length pack $TUPLE_PACK[TUPLE_BLOB], q<>;

my $_NODE_INFO_COUNT =
  @{ [ unpack $_NODE_INFO_TEMPLATE, pack $_NODE_INFO_TEMPLATE ] };

my $_DQLITE_RESPONSE_ROWS_PART = "\xee" x _U64_LEN;
my $_DQLITE_RESPONSE_ROWS_DONE = "\xff" x _U64_LEN;

my @RESPONSE_METADATA = (

    # $classname, $pack_template, @text_members

    [ 'FAILURE',  "$PACK_U64 $PACK_STRING", 1 ],
    [ 'SERVER', $_NODE_INFO_TEMPLATE,     1 ],
    ['WELCOME'],

    # special snowflake: have to UTF-8-decode 2, 5, 8, ...
    [ 'SERVERS', "$PACK_U64 ($_NODE_INFO_TEMPLATE)*" ],

    [ 'DB',          "VV" ],
    [ 'STMT', "VV $PACK_U64" ],
    [ 'RESULT',       "$PACK_U64 $PACK_U64" ],

    # special snowflake: have to decode tuples
    ['ROWS'],
    ['EMPTY'],
    [ 'FILES', "$PACK_U64/($PACK_STRING $PACK_DQLITE_BLOB)", 0 ],
);

my %REQUEST_HAS_SQL_AT_1 =
  map { $_ => 1 } ( REQUEST_PREPARE, REQUEST_QUERY_SQL, REQUEST_EXEC_SQL, );

my %REQUEST_HAS_TUPLE_AT_2 =
  map { $_ => 1 } ( keys %REQUEST_HAS_SQL_AT_1, REQUEST_EXEC, );

#----------------------------------------------------------------------

=head1 CONSTANTS

The following derive from the
L<documentation of Dqlite’s wire protocol|https://dqlite.io/docs/protocol>
as well as
L<protocol.h|https://github.com/canonical/dqlite/blob/master/src/protocol.h>
in Dqlite’s source code.

=head2 Role Codes

C<ROLE_VOTER>, C<ROLE_STANDBY>, C<ROLE_SPARE>

=cut

use constant {
    ROLE_VOTER => 0,
    ROLE_STANDBY => 1,
    ROLE_SPARE => 2,
};

=head2 Tuple Member Types

=over

=item * Numbers: C<TUPLE_INT64>, C<TUPLE_FLOAT>

=item * Buffers: C<TUPLE_STRING>, C<TUPLE_BLOB>

=item * Time: C<TUPLE_UNIXTIME>, C<TUPLE_ISO8601>

=item * Other: C<TUPLE_NULL>, C<TUPLE_BOOLEAN>

=back

=head2 Request Message Types

=over

=item * C<REQUEST_LEADER> (0)

=item * C<REQUEST_CLIENT> (1)

=item * C<REQUEST_OPEN>      (3)

=item * C<REQUEST_PREPARE>   (4)

=item * C<REQUEST_EXEC>      (5)

=item * C<REQUEST_QUERY>     (6)

=item * C<REQUEST_FINALIZE>  (7)

=item * C<REQUEST_EXEC_SQL>  (8)

=item * C<REQUEST_QUERY_SQL> (9)

=item * C<REQUEST_INTERRUPT> (10)

=item * C<REQUEST_CONNECT>   (11)

=item * C<REQUEST_ADD>       (12)

=item * C<REQUEST_ASSIGN>    (13)

=item * C<REQUEST_REMOVE>    (14)

=item * C<REQUEST_DUMP>      (15)

=item * C<REQUEST_CLUSTER>   (16)

=back

=head2 Other

=over

=item * C<handshake> - The string to send after establishing
a connection to the server.

=back

=cut

#----------------------------------------------------------------------

=head1 STATIC FUNCTIONS

=head2 $bytes = request( $TYPE, @ARGUMENTS )

Returns a byte buffer of a Dqlite message. $TYPE is one of the
C<REQUEST_*> constants listed above.

@ARGUMENTS are as Dqlite’s
L<wire protocol documentation|https://dqlite.io/docs/protocol> indicates.
Dqlite tuples are expressed as type/value pairs.

Example:

    my $bytes = Protocol::Dqlite::request(
        Protocol::Dqlite::REQUEST_PREPARE,
        12,
        "SELECT ?, ?",
        Protocol::Dqlite::TUPLE_INT64 => 12345,
        Protocol::Dqlite::TUPLE_BLOB => "\x00\x01\x02",
    );

=cut

sub request {
    my ( $type, @vars ) = @_;

    my $tmpl =
      $REQUEST_PACK[$type] || Carp::croak("Unknown request type: $type");

    if ( $type == REQUEST_OPEN ) {
        $_ && utf8::encode($_) for @vars[ 0, 2 ];
    }
    elsif ( $type == REQUEST_CLUSTER ) {

        # undocumented; dqlite uses this to determine whether
        # to show the last node-info piece.
        $vars[0] = 1;
    }
    else {
        if ( $REQUEST_HAS_SQL_AT_1{$type} ) {
            utf8::encode( $vars[1] );
        }
    }

    my $packed = pack $tmpl, @vars;

    if ( $REQUEST_HAS_TUPLE_AT_2{$type} ) {
        $packed .= _encode_query_tuple( @vars[ 2 .. $#vars ] );
    }

    substr( $packed, 0, 0,
        pack _HEADER_TEMPLATE, length($packed) >> 3, $type, );

    return $packed;
}
=head1 METHODS

=head2 $obj = I<CLASS>->new()

Instantiates I<CLASS>.

=cut

sub new {
    return bless { _pending => q<> }, shift;
}

=head2 @messages = I<OBJ>->feed( $BYTES )

Give new input to I<OBJ>. Returns any messages parsed out of $BYTES
as C<Protocol::Dqlite::Response> instances.

=cut

sub feed {
    my ( $self, $input ) = @_;

    $self->{'_pending'} .= $input;

    return $self->_parse_pending();
}

sub _parse_pending {
    my $self = shift;

    my $pending_sr = \$self->{'_pending'};

    my @msgs;

    while (1) {
        if ( !defined $self->{'_body_size'} ) {
            last if length $$pending_sr < _HEADER_SIZE;

            @{$self}{ '_body_size', '_msg_type' } =
              unpack( _HEADER_TEMPLATE,
                substr( $$pending_sr, 0, _HEADER_SIZE, q<> ),
              );

            # Body size is expressed in words, which are 8 bytes each.
            #
            $self->{'_body_size'} <<= 3;
        }

        last if length $$pending_sr < $self->{'_body_size'};

        push @msgs, _parse_msg(
            $self->{'_msg_type'},
            substr( $$pending_sr, 0, $self->{'_body_size'}, q<> ),
        );

        undef $self->{'_body_size'};
    }

    return @msgs;
}

sub _parse_msg {
    my ( $type, $body ) = @_;

    my $metadata_ar = $RESPONSE_METADATA[$type] || do {
        warn "Unknown Dqlite message response type: $type\n";
        return;
    };

    my ( $class, $tmpl, @text_indexes ) = @$metadata_ar;

    my $msg = bless [], "Protocol::Dqlite::Response::$class";

    if ( $type == 7 ) {
        my $end = substr( $body, -_U64_LEN() );

        my $is_done = ( $end eq $_DQLITE_RESPONSE_ROWS_DONE );

        if ( !$is_done && $end ne $_DQLITE_RESPONSE_ROWS_PART ) {
            warn sprintf
"Dqlite TableRows response ends with unexpected sequence: %v.02x\n",
              $end;
        }
        else {
            substr( $body, -_U64_LEN() ) = q<>;

            push @$msg, $is_done, _decode_response_rows($body);
        }
    }
    elsif ($tmpl) {
        @$msg = unpack $tmpl, $body;

        utf8::decode($_) || warn "Bad UTF-8: $_\n" for @{$msg}[@text_indexes];

        if ( $type == 3 ) {    # ClusterInfo
            my $i = 2;
            while ( $i < @$msg ) {
                _decode_utf8( $msg->[$i] );
                $i += $_NODE_INFO_COUNT;
            }
        }
    }

    return $msg;
}

sub _decode_utf8 {
    utf8::decode( $_[0] ) || warn "Bad UTF-8: $_[0]\n";
}

sub _encode_query_tuple {
    my (@type_vals) = @_;

    my $count = @type_vals >> 1;

    my ( @types, @values );

    for my $i ( 0 .. ( $count - 1 ) ) {
        $i <<= 1;

        my $type  = $type_vals[$i];
        my $value = $type_vals[ 1 + $i ];

        push @types, $type;

        if ( $type == TUPLE_STRING ) {
            utf8::encode($value);
        }

        push @values, $value;
    }

    my $tmpl = join(
        q<>,

        # header
        'C',
        ( $count ? "C$count" : () ),
        'x',
        $PACK_ALIGN_U64,

        # body
        map { $TUPLE_PACK[$_] } @types,
    );

    return pack $tmpl, $count, @types, @values;
}

# $VAR2 = "\5\0\0\0\0\0\0\0type\0\0\0\0name\0\0\0\0tbl_name\0\0\0\0\0\0\0\0rootpage\0\0\0\0\0\0\0\0sql\0\0\0\0\0003\23\3\0\0\0\0\0table\0\0\0model\0\0\0model\0\0\0\2\0\0\0\0\0\0\0CREATE TABLE model (key TEXT, value TEXT, UNIQUE(key))\0\0003\23\5\0\0\0\0\0index\0\0\0sqlite_autoindex_model_1\0\0\0\0\0\0\0\0model\0\0\0\3\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
#
sub _decode_response_rows {
    my ($body) = @_;

    my @col_names = unpack "$PACK_U64/($PACK_STRING)", $body;

    # Ideally Perl could just *tell* us how many bytes it just read …
    #
    my $names_len = _U64_LEN;
    for my $name (@col_names) {
        $names_len += 1 + length $name;
        _align_u64_in_place($names_len);
    }
    substr( $body, 0, $names_len ) = q<>;

    my @rows = _decode_response_tuples( 0 + @col_names, $body );

    utf8::decode($_) for @col_names;

    return \@col_names, \@rows;
}

sub _align_u64_in_place {
    $_[0] += ( _U64_LEN - ( $_[0] % _U64_LEN ) ) if $_[0] % _U64_LEN;
}

sub _decode_response_tuples {
    my ( $cols_count, $bytes ) = @_;

    my @rows;

    while ( length $bytes ) {
        my @types = map { vec $bytes, $_, 4 } 0 .. ( $cols_count - 1 );

        my $unpacked_bytes = $cols_count >> 1;
        $unpacked_bytes++ if ( $cols_count % 2 );
        _align_u64_in_place($unpacked_bytes);

        substr( $bytes, 0, $unpacked_bytes ) = q<>;

        my $tmpl = join q<>,
          map { $TUPLE_PACK[$_] || die "No pack for type $_" } @types;

        my @values = unpack "$tmpl", $bytes;

        $unpacked_bytes = 0;

        # The loop below does a few things:
        # - Figure out how many bytes pack actually read.
        # - UTF-8 decode as needed
        # - Insert Perl undef wherever Dqlite indicated NULL
        #
        for my $t ( 0 .. $#types ) {
            my $type = $types[$t];
            if ( $type == TUPLE_STRING || $type == TUPLE_ISO8601 ) {
                $unpacked_bytes += 1 + length $values[$t];
                utf8::decode( $values[$t] );
            }
            elsif ( $type == TUPLE_BLOB ) {
                $unpacked_bytes += $TUPLE_BLOB_BASE_LENGTH + length $values[$t];
            }
            else {
                if ( $type == TUPLE_NULL ) {
                    splice @values, $t, 0, undef;
                }

                $unpacked_bytes += $TUPLE_PACK_LENGTH[$type];
            }

            _align_u64_in_place($unpacked_bytes);
        }

        substr( $bytes, 0, $unpacked_bytes ) = q<>;

        push @rows, [ \@types, \@values ];
    }

    return @rows;
}

package Protocol::Dqlite::Response;

=head1 RESPONSE CLASSES

All of the below extend C<Protocol::Dqlite::Response>.
They expose various accessors as documented below:

=over

=cut

package Protocol::Dqlite::Response::FAILURE;

=item * C<Protocol::Dqlite::Response::FAILURE>: C<code()>, C<message()>

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub code { $_[0][0] }
sub message { $_[0][1] }

package Protocol::Dqlite::Response::SERVER;

=item * C<Protocol::Dqlite::Response::SERVER>: C<id()>, C<address()>,
C<role()>

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub id { $_[0][0] }
sub address { $_[0][1] }
sub role { $_[0][2] }

package Protocol::Dqlite::Response::WELCOME;

=item * C<Protocol::Dqlite::Response::WELCOME>: (none)

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

package Protocol::Dqlite::Response::SERVERS;

=item * C<Protocol::Dqlite::Response::SERVERS>: C<count()>, C<id()>,
C<address()>, C<role()>; the latter 3 require an index argument, which
MUST be between 0 and (C<count()> - 1), inclusive.

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub count { $_[0][0] }

sub id {
    my $which = _get_which($_[1]);
    return $_[0][1 + $which];
}

sub address {
    my $which = _get_which($_[1]);
    return $_[0][2 + $which];
}

sub role {
    my $which = _get_which($_[1]);
    return $_[0][3 + $which];
}

sub _get_which {
    my $which = $_[0];
    Carp::croak "Give node index" if !defined $which;
    return $which;
}

package Protocol::Dqlite::Response::DB;

=item * C<Protocol::Dqlite::Response::DB>: C<id()>

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub id { $_[0][0] }

package Protocol::Dqlite::Response::STMT;

=item * C<Protocol::Dqlite::Response::STMT>: C<database_id()>,
C<statement_id()>, C<params_count()>

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub database_id { $_[0][0] }
sub statement_id { $_[0][1] }
sub params_count { $_[0][2] }

package Protocol::Dqlite::Response::RESULT;

=item * C<Protocol::Dqlite::Response::RESULT>: C<last_row_id()>,
C<rows_count()>

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub last_row_id { $_[0][0] }
sub rows_count { $_[0][1] }

package Protocol::Dqlite::Response::ROWS;

=item * C<Protocol::Dqlite::Response::ROWS>:

=over

=item * C<is_final()>

=item * C<column_names()> - returns a list, or a count in scalar context

=item * C<rows_count()>

=item * C<row_types()>, C<row_data()> - these need an index,
max=(C<rows_count()>-1)

=back

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub is_final { $_[0][0] }
sub column_names { @{ $_[0][1] } }
sub rows_count { 0 + @{ $_[0][2] } }

sub row_types {
    my $which = Protocol::Dqlite::Response::SERVERS::_get_which($_[1]);
    @{ $_[0][2][$which][0] }
}

sub row_data {
    my $which = Protocol::Dqlite::Response::SERVERS::_get_which($_[1]);
    @{ $_[0][2][$which][1] }
}

package Protocol::Dqlite::Response::EMPTY;

=item * C<Protocol::Dqlite::Response::EMPTY>: (none)

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

package Protocol::Dqlite::Response::FILES;

=item * C<Protocol::Dqlite::Response::FILES>: C<names()> (list/count) and
C<content()> (takes an index)

=cut

use parent -norequire => 'Protocol::Dqlite::Response';

sub names {
    my @names;
    for (my $i=0; $i < @_; $i += 2) {
        push @names, $_[0][$i];
    }

    return @names;
}

sub content {
    my $name = $_[1];
    Carp::croak("Need name") if !defined $name || !length $name;
    for (my $i=0; $i < @_; $i += 2) {
        next if $_[0][$i] ne $name;
    return $_[0][1 + $i];
    }

    Carp::croak("No file named “$name”");
}

=back

=cut

1;
