package SION;

use 5.022;
use strict;
use warnings;
use Carp ();
use B ();
use Encode ();
use MIME::Base64 ();
use POSIX ();
use JSON::PP ();
use Scalar::Util ();
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT    = qw(encode_sion decode_sion);
our @EXPORT_OK = qw(true false is_bool);

use constant INF => 9**9**9;
use constant NAN => 9**9**9 - 9**9**9;

my $HAS_CORE_BOOL = $] >= 5.035009;

sub true  { JSON::PP::true }
sub false { JSON::PP::false }

sub is_bool {
    return 1 if JSON::PP::is_bool( $_[0] );
    return _is_core_bool( $_[0] );
}

sub _is_core_bool {
    return !!0 unless $HAS_CORE_BOOL;
    no warnings;
    return builtin::is_bool( $_[0] );
}

#### functional interface

my $SION_UTF8;

sub encode_sion { ( $SION_UTF8 ||= SION->new->utf8 )->encode( $_[0] ) }
sub decode_sion { ( $SION_UTF8 ||= SION->new->utf8 )->decode( $_[0] ) }

#### constructor and accessors

sub new {
    my $class = shift;
    bless {
        utf8            => 0,
        ascii           => 0,
        indent          => 0,
        indent_length   => 4,
        space_before    => 0,
        space_after     => 0,
        canonical       => 0,
        allow_nonref    => 1,
        allow_blessed   => 0,
        convert_blessed => 0,
        max_depth       => 512,
    }, $class;
}

for my $name (
    qw( utf8 ascii indent space_before space_after canonical
        allow_nonref allow_blessed convert_blessed )
  )
{
    no strict 'refs';
    *{$name} = sub {
        my $self = shift;
        $self->{$name} = @_ ? ( $_[0] ? 1 : 0 ) : 1;
        $self;
    };
    *{"get_$name"} = sub { $_[0]->{$name} };
}

sub pretty {
    my ( $self, $enable ) = @_;
    $enable = 1 unless defined $enable;
    $enable = $enable ? 1 : 0;
    @{$self}{qw(indent space_before space_after)} = ($enable) x 3;
    $self;
}

sub max_depth {
    my $self = shift;
    $self->{max_depth} = @_ ? $_[0] : 0x7FFFFFFF;
    $self;
}
sub get_max_depth { $_[0]->{max_depth} }

sub indent_length {
    my $self = shift;
    $self->{indent_length} = @_ ? $_[0] : 4;
    $self;
}
sub get_indent_length { $_[0]->{indent_length} }

#### encoder

sub encode {
    my ( $self, $data ) = @_;
    if ( !$self->{allow_nonref}
        and not( ref $data eq 'ARRAY' or ref $data eq 'HASH' ) )
    {
        Carp::croak( 'hash- or arrayref expected'
              . ' (not a simple scalar, use allow_nonref to allow this)' );
    }
    my $text = $self->_encode_value( $data, 0 );
    return $self->{utf8} ? Encode::encode( 'UTF-8', $text ) : $text;
}

sub _encode_value {
    no warnings 'recursion';    # max_depth is the limit, not perl's warning
    my ( $self, $v, $depth ) = @_;
    if ( $depth > $self->{max_depth} ) {
        Carp::croak( 'SION text or perl structure exceeds maximum nesting'
              . ' level (max_depth set too low?)' );
    }
    if ( my $class = Scalar::Util::blessed($v) ) {
        return ( $v ? 'true' : 'false' ) if $v->isa('JSON::PP::Boolean');
        return _data_str( $v->data )     if $v->isa('SION::Data');
        return '.Ext("' . MIME::Base64::encode_base64( $v->data, '' ) . '")'
          if $v->isa('SION::Ext');
        return '.Date(' . _double_str( 0.0 + $v->epoch ) . ')'
          if $v->isa('SION::Date');
        if ( $self->{convert_blessed} and $v->can('TO_SION') ) {
            return $self->_encode_value( $v->TO_SION, $depth );
        }
        return '.Date(' . _double_str( 0.0 + $v->epoch ) . ')'
          if $v->can('epoch');    # Time::Piece, DateTime, Time::Moment ...
        return 'nil' if $self->{allow_blessed};
        Carp::croak( "encountered object '$v', but neither allow_blessed"
              . ' nor convert_blessed settings are enabled' );
    }
    my $r = ref $v;
    if ( $r eq 'ARRAY' ) {
        my @elems = map { $self->_encode_value( $_, $depth + 1 ) } @$v;
        return $self->_wrap( \@elems, $depth, '[]' );
    }
    if ( $r eq 'HASH' ) {
        my @keys = keys %$v;
        @keys = sort @keys if $self->{canonical};
        my $sb    = $self->{space_before} ? ' ' : '';
        my $sa    = $self->{space_after}  ? ' ' : '';
        my @pairs = map {
                $self->_string_or_data($_)
              . $sb . ':' . $sa
              . $self->_encode_value( $v->{$_}, $depth + 1 )
        } @keys;
        return $self->_wrap( \@pairs, $depth, '[:]' );
    }
    if ( $r eq 'SCALAR' ) {
        return 'true'  if defined $$v and $$v eq '1';
        return 'false' if defined $$v and ( $$v eq '0' or $$v eq '' );
        Carp::croak('cannot encode reference to scalar unless it is \0 or \1');
    }
    if ($r) {
        Carp::croak("cannot encode reference to $r");
    }
    # plain scalar
    return 'nil' unless defined $v;
    return ( $v ? 'true' : 'false' ) if _is_core_bool($v);
    my $flags = B::svref_2object( \$v )->FLAGS;
    if (    $flags & ( B::SVp_IOK() | B::SVp_NOK() )
        and !( $flags & B::SVp_POK() ) )
    {
        return $flags & B::SVp_NOK() ? _double_str($v) : "$v";
    }
    return $self->_string_or_data($v);
}

sub _wrap {
    my ( $self, $elems, $depth, $empty ) = @_;
    return $empty unless @$elems;
    if ( $self->{indent} ) {
        my $in  = ' ' x ( $self->{indent_length} * ( $depth + 1 ) );
        my $out = ' ' x ( $self->{indent_length} * $depth );
        return "[\n" . join( ",\n", map { $in . $_ } @$elems ) . "\n$out]";
    }
    my $sep = ',' . ( $self->{space_after} ? ' ' : '' );
    return '[' . join( $sep, @$elems ) . ']';
}

sub _double_str {
    my $v = shift;
    return 'nan'  if $v != $v;
    return 'inf'  if $v == INF;
    return '-inf' if $v == - INF();
    return sprintf '%a', $v;
}

sub _data_str {
    my $v = shift;
    return '.Data("' . MIME::Base64::encode_base64( $v, '' ) . '")';
}

sub _string_or_data {
    my ( $self, $v ) = @_;
    return $self->_string($v) if utf8::is_utf8($v);
    my $chars = eval {
        Encode::decode( 'UTF-8', $v, Encode::FB_CROAK | Encode::LEAVE_SRC );
    };
    return defined $chars ? $self->_string($chars) : _data_str($v);
}

my %ESC = (
    "\x22" => '\"',
    "\x5c" => '\\\\',
    "\x08" => '\b',
    "\x09" => '\t',
    "\x0a" => '\n',
    "\x0c" => '\f',
    "\x0d" => '\r',
);

sub _string {
    my ( $self, $s ) = @_;
    $s =~ s/([\x22\x5c\x00-\x1f])/$ESC{$1} || sprintf '\u%04x', ord $1/ge;
    if ( $self->{ascii} ) {
        $s =~ s/([^\x00-\x7f])/_ascii_escape(ord $1)/ge;
    }
    return qq("$s");
}

sub _ascii_escape {
    my $cp = shift;
    return sprintf '\u%04x', $cp if $cp <= 0xFFFF;
    $cp -= 0x10000;
    return sprintf '\u%04x\u%04x', 0xD800 + ( $cp >> 10 ),
      0xDC00 + ( $cp & 0x3FF );
}

#### decoder

our $_TEXT;

sub decode {
    my ( $self, $input ) = @_;
    Carp::croak('decode: input is undefined') unless defined $input;
    if ( $self->{utf8} ) {
        $input = Encode::decode( 'UTF-8', $input,
            Encode::FB_CROAK | Encode::LEAVE_SRC );
    }
    local $_TEXT = $input;
    pos($_TEXT) = 0;
    my $value = $self->_decode_value(0);
    _skip_ws();
    if ( pos($_TEXT) != length($_TEXT) ) {
        $self->_croak('garbage after SION value');
    }
    if ( !$self->{allow_nonref}
        and not( ref $value eq 'ARRAY' or ref $value eq 'HASH' ) )
    {
        Carp::croak( 'SION text must be an array or dictionary'
              . ' (but found number, string, or atom,'
              . ' use allow_nonref to allow this)' );
    }
    return $value;
}

sub _croak {
    my ( $self, $msg ) = @_;
    my $pos  = pos($_TEXT) // 0;
    my $len  = length($_TEXT) - $pos;
    my $near =
        $len <= 0 ? '(end of string)'
      : $len > 32 ? substr( $_TEXT, $pos, 32 ) . '...'
      :             substr( $_TEXT, $pos );
    Carp::croak( sprintf '%s, at character offset %d (before "%s")',
        $msg, $pos, $near );
}

sub _skip_ws {
    $_TEXT =~ /\G(?:\s+|\/\/[^\n\r]*)+/gc;
    return;
}

sub _decode_value {
    no warnings 'recursion';    # max_depth is the limit, not perl's warning
    my ( $self, $depth ) = @_;
    if ( $depth > $self->{max_depth} ) {
        Carp::croak( 'SION text or perl structure exceeds maximum nesting'
              . ' level (max_depth set too low?)' );
    }
    _skip_ws();
    if ( $_TEXT =~ /\G\[/gc ) {
        return $self->_decode_collection( $depth + 1 );
    }
    if ( $_TEXT =~ /\G"((?:\\.|[^\\"])*+)"/gcs ) {
        return _unescape("$1");
    }
    return undef            if $_TEXT =~ /\Gnil\b/gc;
    return JSON::PP::true   if $_TEXT =~ /\Gtrue\b/gc;
    return JSON::PP::false  if $_TEXT =~ /\Gfalse\b/gc;
    if ( $_TEXT =~ /\G\.Date\(/gc ) {
        _skip_ws();
        my $n = _try_number();
        $self->_croak('number expected while parsing .Date') unless defined $n;
        _skip_ws();
        $_TEXT =~ /\G\)/gc or $self->_croak('")" expected while parsing .Date');
        return SION::Date->new($n);
    }
    if ( $_TEXT =~ /\G\.Data\("([0-9A-Za-z+\/]*={0,3})"\)/gc ) {
        return MIME::Base64::decode_base64($1);
    }
    if ( $_TEXT =~ /\G\.Ext\("([0-9A-Za-z+\/]*={0,3})"\)/gc ) {
        return SION::Ext->new( MIME::Base64::decode_base64($1) );
    }
    my $n = _try_number();
    return $n if defined $n;
    $self->_croak( 'malformed SION string, neither array, dictionary,'
          . ' number, string or atom' );
}

sub _try_number {
    if ( $_TEXT =~
        /\G([+-]?)0[xX]([0-9A-Fa-f]+)(?:\.([0-9A-Fa-f]*))?[pP]([+-]?[0-9]+)/gc )
    {
        return _mk_hexfloat( $1, $2, $3, $4 );
    }
    if ( $_TEXT =~ /\G([+-]?)0[xX]([0-9A-Fa-f]+)/gc ) {
        my $v = hex $2;
        return $1 eq '-' ? -$v : $v;
    }
    if ( $_TEXT =~ /\G([+-]?)0[oO]([0-7]+)/gc ) {
        my $v = oct "0$2";
        return $1 eq '-' ? -$v : $v;
    }
    if ( $_TEXT =~ /\G([+-]?)0[bB]([01]+)/gc ) {
        my $v = oct "0b$2";
        return $1 eq '-' ? -$v : $v;
    }
    if ( $_TEXT =~
        /\G([+-]?)((?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)/gc )
    {
        my ( $sign, $body ) = ( $1, $2 );
        my $v = $body =~ /[.eE]/ ? 0.0 + $body : 0 + $body;
        return $sign eq '-' ? -$v : $v;
    }
    return NAN if $_TEXT =~ /\G[+-]?[Nn]a[Nn]\b/gc;
    if ( $_TEXT =~ /\G([+-]?)[Ii]nf(?:inity)?\b/gc ) {
        return $1 eq '-' ? - INF() : INF;
    }
    return undef;
}

sub _mk_hexfloat {
    my ( $sign, $int, $frac, $exp ) = @_;
    $frac = '' unless defined $frac;
    my $mant = 0.0;
    $mant = $mant * 16.0 + hex($_) for split //, $int . $frac;
    my $e = $exp - 4 * length $frac;
    $e = $e > 99_999 ? 99_999 : $e < -99_999 ? -99_999 : $e;
    # ldexp() keeps the result an NV so Double survives a round trip
    my $v = POSIX::ldexp( $mant, $e );
    return $sign eq '-' ? -$v : $v;
}

my %UNESC = (
    '"'  => '"',
    '\\' => '\\',
    '/'  => '/',
    "'"  => "'",
    '0'  => "\0",
    'b'  => "\b",
    'f'  => "\f",
    'n'  => "\n",
    'r'  => "\r",
    't'  => "\t",
);

sub _unescape {
    my $s = shift;
    no warnings 'surrogate', 'non_unicode';
    # surrogate pairs first
    $s =~ s{\\[uU]([Dd][89ABab][0-9A-Fa-f]{2})\\[uU]([Dd][C-Fc-f][0-9A-Fa-f]{2})}
           {chr(0x10000 + ((hex($1) - 0xD800) << 10) + (hex($2) - 0xDC00))}ge;
    $s =~ s{\\(?:[uU]\{([0-9A-Fa-f]{1,6})\}|[uU]([0-9A-Fa-f]{4})|(.))}
           {
               defined $1 ? chr hex $1
             : defined $2 ? chr hex $2
             : defined $UNESC{$3} ? $UNESC{$3}
             : Carp::croak(qq(illegal backslash escape: \\$3 in SION string))
           }sge;
    return $s;
}

sub _decode_collection {
    my ( $self, $depth ) = @_;
    _skip_ws();
    if ( $_TEXT =~ /\G:/gc ) {    # [:] -- empty dictionary
        _skip_ws();
        $_TEXT =~ /\G\]/gc or $self->_croak('"]" expected after "[:"');
        return {};
    }
    return [] if $_TEXT =~ /\G\]/gc;    # [] -- empty array
    my $first = $self->_decode_value($depth);
    _skip_ws();
    if ( $_TEXT =~ /\G:/gc ) {          # dictionary
        my %hash;
        $hash{ $self->_key_str($first) } = $self->_decode_value($depth);
        while (1) {
            _skip_ws();
            if ( $_TEXT =~ /\G,/gc ) {
                _skip_ws();
                last if $_TEXT =~ /\G\]/gc;    # trailing comma
                my $k = $self->_decode_value($depth);
                _skip_ws();
                $_TEXT =~ /\G:/gc
                  or $self->_croak('":" expected while parsing dictionary');
                $hash{ $self->_key_str($k) } = $self->_decode_value($depth);
            }
            elsif ( $_TEXT =~ /\G\]/gc ) { last }
            else {
                $self->_croak('"," or "]" expected while parsing dictionary');
            }
        }
        return \%hash;
    }
    my @array = ($first);                      # array
    while (1) {
        _skip_ws();
        if ( $_TEXT =~ /\G,/gc ) {
            _skip_ws();
            last if $_TEXT =~ /\G\]/gc;        # trailing comma
            push @array, $self->_decode_value($depth);
        }
        elsif ( $_TEXT =~ /\G\]/gc ) { last }
        else {
            $self->_croak('"," or "]" expected while parsing array');
        }
    }
    return \@array;
}

# SION allows any value as a dictionary key; perl hash keys are strings,
# so non-string keys are stringified.
sub _key_str {
    my ( $self, $k ) = @_;
    return 'nil' unless defined $k;
    if ( Scalar::Util::blessed($k) ) {
        return $k ? 'true' : 'false' if $k->isa('JSON::PP::Boolean');
    }
    return "$k" unless ref $k;
    return SION->new->canonical->encode($k);
}

#### helper classes

package SION::Date;

use overload
  '0+'     => sub { ${ $_[0] } },
  '""'     => sub { '.Date(' . SION::_double_str( 0.0 + ${ $_[0] } ) . ')' },
  fallback => 1;

sub new {
    my ( $class, $epoch ) = @_;
    $epoch = 0.0 + $epoch;
    return bless \$epoch, $class;
}

sub epoch { ${ $_[0] } }

package SION::Data;

sub new {
    my ( $class, $data ) = @_;
    utf8::downgrade($data);    # dies if $data contains wide characters
    return bless \$data, $class;
}

sub data { ${ $_[0] } }

package SION::Ext;

sub new {
    my ( $class, $data ) = @_;
    utf8::downgrade($data);    # dies if $data contains wide characters
    return bless \$data, $class;
}

sub data { ${ $_[0] } }

package SION;

1;

__END__

=encoding utf-8

=head1 NAME

SION - a serialization format a little more expressive than JSON

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use SION;    # exports encode_sion() and decode_sion()

    # functional interface: SION text is UTF-8 octets
    my $data = decode_sion($sion_text);
    my $sion = encode_sion($data);

    # OO interface, a la JSON::PP: SION text is a character string
    # unless ->utf8 is enabled
    my $codec = SION->new->canonical->pretty;
    $sion = $codec->encode($data);
    $data = $codec->decode($sion);

=head1 DESCRIPTION

L<SION|https://dankogai.github.io/SION/> is a data serialization format
whose origin is Swift literals, just like JSON's origin is JavaScript
literals.  It is a little more expressive than JSON:

    [
        "nil":      nil,                // nil is allowed
        "bool":     true,
        "int":      -42,               // Int is distinguished from Double
        "double":   0x1.518f5c28f5c29p+5,   // C99 hexadecimal notation
        "string":   "漢字、カタカナ、ひらがなの入ったstring😇",
        "array":    [nil, true, 1, 1.0, "one", [1], ["one":1.0]],
        "dictionary": ["nil":nil, "array":[], "object":[:]],
        "data":     .Data("R0lGODlh"), // binary data in Base64
        "date":     .Date(0x0p+0),     // date in seconds since epoch
        "ext":      .Ext("1NTU"),      // msgpack-style extension
        1:          "non-string keys are also allowed", // comments, too!
    ]

This module implements a SION encoder/decoder for Perl with an interface
modeled after L<JSON::PP>.

=head2 MAPPING

    SION            Perl
    --------------- ------------------------------------------
    nil             undef
    true/false      JSON::PP::true / JSON::PP::false
    Int             integer (IV)
    Double          floating point number (NV)
    String          character string (decoded UTF-8 string)
    Data            byte string (raw octets); SION::Data to force
    Date            SION::Date object
    Ext             SION::Ext object
    Array           ARRAY reference
    Dictionary      HASH reference

=over 4

=item booleans

Booleans are handled exactly like L<JSON::PP>: C<true> and C<false>
decode to C<JSON::PP::true> and C<JSON::PP::false>.  On encoding,
C<JSON::PP::Boolean> objects, C<\1> and C<\0>, and (on perl 5.36+)
native booleans like C<!!1> all encode to C<true>/C<false>.

=item Int vs Double

Like JSON::PP, this module looks at the internal flags of a scalar to
tell an integer from a floating point number: C<1> encodes to C<1>
while C<1.0> encodes to C<0x1p+0>.  Doubles are always encoded in C99
hexadecimal floating point notation via C<sprintf '%a'>, which is
lossless; C<nan>, C<inf> and C<-inf> are also supported.  On decoding,
Int becomes an IV and Double becomes an NV, so the distinction
round-trips.

=item String vs Data

SION strings are utf-8 strings and SION data are byte strings.  On
decoding, a String becomes a perl character string (decoded text) while
C<.Data("...")> becomes a plain byte string of raw octets.  On
encoding, a scalar with the UTF8 flag set, or a byte string which is
valid UTF-8 (including plain ASCII), encodes as a String; a byte
string which is I<not> valid UTF-8 encodes as C<.Data("...")> in
Base64.  To force a valid-UTF-8 byte string to encode as Data, wrap it
in C<< SION::Data->new($bytes) >>.

=item dates

C<.Date(n)> decodes to a C<SION::Date> object where C<n> is seconds
since epoch (may be fractional).  C<< $date->epoch >> returns it; the
object also numifies to it.  On encoding, C<SION::Date> objects and any
object with an C<epoch> method (L<Time::Piece>, L<DateTime>,
L<Time::Moment>, ...) encode as C<.Date(...)>.

=item dictionaries

SION allows non-string dictionary keys.  Since perl hash keys are
strings, non-string keys are stringified on decoding (numbers via plain
stringification, C<nil>/C<true>/C<false> as those words, anything else
via its canonical SION encoding).  On encoding, hash keys are always
emitted as Strings.

=back

=head1 FUNCTIONS

=head2 encode_sion

    $sion_octets = encode_sion($data);

Encodes a perl data structure to UTF-8 encoded SION text.
Equivalent to C<< SION->new->utf8->encode($data) >>.
Exported by default.

=head2 decode_sion

    $data = decode_sion($sion_octets);

Decodes UTF-8 encoded SION text to a perl data structure.
Equivalent to C<< SION->new->utf8->decode($sion_octets) >>.
Exported by default.

=head2 true

=head2 false

Return C<JSON::PP::true> and C<JSON::PP::false> respectively.
Exportable on demand.

=head2 is_bool

    $bool = SION::is_bool($value);

Returns true if C<$value> is a boolean: a C<JSON::PP::Boolean> object
or (on perl 5.36+) a native boolean.  Exportable on demand.

=head1 METHODS

The mutators below return the object itself so that they can be
chained, just like JSON::PP:

    my $sion = SION->new->utf8->canonical->pretty->encode($data);

Each C<foo> mutator has a corresponding C<get_foo> accessor.

=head2 new

    $codec = SION->new;

Creates a new encoder/decoder object with the default settings:
non-C<utf8>, non-C<ascii>, compact output, non-C<canonical>,
C<allow_nonref> enabled, C<max_depth> of 512.

=head2 encode

    $sion_text = $codec->encode($data);

Encodes a perl data structure to SION text.

=head2 decode

    $data = $codec->decode($sion_text);

Decodes SION text to a perl data structure.  Croaks on malformed input
with the character offset of the error, a la JSON::PP.

=head2 utf8

    $codec = $codec->utf8([$enable]);

If enabled, C<encode> returns UTF-8 encoded octets and C<decode>
expects UTF-8 encoded octets.  If disabled (default), SION text is a
perl character string.

=head2 ascii

    $codec = $codec->ascii([$enable]);

If enabled, C<encode> escapes all non-ASCII characters in strings as
C<\uXXXX> (using surrogate pairs beyond U+FFFF) so the output is pure
ASCII.

=head2 pretty

    $codec = $codec->pretty([$enable]);

Enables (or disables) C<indent>, C<space_before> and C<space_after> at
once, for human readable output.

=head2 indent

=head2 indent_length

=head2 space_before

=head2 space_after

Fine-grained control over the output format, a la JSON::PP: C<indent>
puts each element on its own line indented by C<indent_length> (default
4) spaces per level; C<space_before>/C<space_after> add a space
before/after the C<:> of dictionary entries.

=head2 canonical

    $codec = $codec->canonical([$enable]);

If enabled, dictionary keys are sorted, so the output is deterministic.

=head2 allow_nonref

    $codec = $codec->allow_nonref([$enable]);

If disabled, C<encode>/C<decode> croak unless the top level value is an
array or dictionary.  Enabled by default, following JSON::PP 4.x /
RFC 8259.

=head2 allow_blessed

=head2 convert_blessed

Like JSON::PP: if C<convert_blessed> is enabled, a blessed object with
a C<TO_SION> method is encoded as the value that method returns;
otherwise, if C<allow_blessed> is enabled, unknown blessed objects
encode as C<nil>; otherwise they croak.  (C<JSON::PP::Boolean>,
C<SION::Date>, C<SION::Data>, C<SION::Ext> and objects with an C<epoch>
method are always handled natively.)

=head2 max_depth

    $codec = $codec->max_depth($n);

Maximum nesting level (default 512) accepted while encoding or
decoding; exceeding it croaks.

=head1 HELPER CLASSES

=over 4

=item SION::Date

    my $date = SION::Date->new($epoch);  # seconds since epoch, may be fractional
    $date->epoch;                        # get it back
    0 + $date;                           # numifies to epoch

=item SION::Data

    my $data = SION::Data->new($bytes);  # force encoding as .Data(...)
    $data->data;                         # the byte string

=item SION::Ext

    my $ext = SION::Ext->new($bytes);    # decoded from / encodes to .Ext(...)
    $ext->data;                          # the byte string

=back

=head1 SEE ALSO

L<https://dankogai.github.io/SION/>,
L<https://github.com/dankogai/swift-sion>,
L<https://github.com/dankogai/js-sion>,
L<JSON::PP>

=head1 AUTHOR

Dan Kogai <dankogai@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sion at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SION>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SION

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/dankogai/p5-sion>

=item * CPAN

L<https://metacpan.org/release/SION>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Dan Kogai <dankogai@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
