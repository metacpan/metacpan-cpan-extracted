package Skilletor::JSON;
# ABSTRACT: JSON read and written exactly as the reference implementation does

use strict;
use warnings;

use B ();
use Carp qw( croak );
use Exporter qw( import );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed reftype );
use Skilletor::Error::JSON;
use Skilletor::JSON::OrderedHash;

our $VERSION = '0.001';

our @EXPORT_OK = qw( js_parse js_stringify js_ordered js_sort_keys js_number js_type );

use constant CORE_BOOL => defined &builtin::is_bool;

#### Writing ###########################################################

sub js_ordered {
  my ( @pairs ) = @_;
  tie my %h, 'Skilletor::JSON::OrderedHash', @pairs;
  return \%h;
}

# Default Array.prototype.sort: by UTF-16 code units.
sub js_sort_keys {
  my ( @keys ) = @_;
  return sort @keys unless grep { /[^\x{0}-\x{FFFF}]/ } @keys;
  my %unit = map { $_ => _utf16_units($_) } @keys;
  return sort { $unit{$a} cmp $unit{$b} } @keys;
}

sub _utf16_units {
  my ( $s ) = @_;
  return join '', map {
    my $c = ord;
    $c > 0xFFFF
      ? do { my $v = $c - 0x10000; chr( 0xD800 + ( $v >> 10 ) ).chr( 0xDC00 + ( $v & 0x3FF ) ) }
      : $_
  } split //, $s;
}

# Property order of a plain hash: written as the reference writes a sorted object –
# index keys ascending first (JavaScript reorders them), then the rest sorted.
sub _hash_keys {
  my ( $h ) = @_;
  my $tied = tied %$h;
  return $tied->keys_in_order if blessed $tied && $tied->isa('Skilletor::JSON::OrderedHash');
  my @keys  = keys %$h;
  my @index = sort { $a <=> $b } grep { Skilletor::JSON::OrderedHash->is_index_key($_) } @keys;
  my @rest  = js_sort_keys( grep { !Skilletor::JSON::OrderedHash->is_index_key($_) } @keys );
  return ( @index, @rest );
}

sub js_stringify {
  my ( $value, $indent ) = @_;
  # A number: that many spaces (at most 10); a string: its first 10 characters.
  my $gap = !defined $indent ? ''
    : ( !ref $indent && !_is_number($indent) ) ? substr( $indent, 0, 10 )
    : $indent > 0 ? ' ' x ( $indent > 10 ? 10 : $indent )
    : '';
  return _write( $value, $gap, '' );
}

sub _is_number {
  my ( $value ) = @_;
  my $flags = B::svref_2object( \$value )->FLAGS;
  return ( $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() ) ) ? 1 : 0;
}

# typeof, with Array.isArray and null told apart: what a validator asks of a parsed value.
sub js_type {
  my ( $value ) = @_;
  return 'null' unless defined $value;
  return 'boolean' if JSON::MaybeXS::is_bool($value);
  if ( ref $value ) {
    my $type = reftype $value;
    return $type eq 'ARRAY' ? 'array' : $type eq 'HASH' ? 'object' : 'other';
  }
  if (CORE_BOOL) {
    no warnings 'experimental::builtin';
    return 'boolean' if builtin::is_bool($value);
  }
  return _is_number($value) ? 'number' : 'string';
}

sub _write {
  my ( $value, $gap, $current ) = @_;
  return 'null' unless defined $value;
  if ( ref $value ) {
    return $value ? 'true' : 'false' if JSON::MaybeXS::is_bool($value);
    if ( blessed $value && !( tied( %{ $value } ) && reftype $value eq 'HASH' ) ) {
      return _write( $value->TO_JSON, $gap, $current ) if $value->can('TO_JSON');
      croak __PACKAGE__.'->js_stringify cannot write a '.ref($value).' object';
    }
    my $type = reftype $value;
    my $inner = $current.$gap;
    if ( $type eq 'ARRAY' ) {
      return '[]' unless @$value;
      my @parts = map { _write( $_, $gap, $inner ) } @$value;
      return '['.join( ',', @parts ).']' if $gap eq '';
      return "[\n".$inner.join( ",\n".$inner, @parts )."\n".$current.']';
    }
    if ( $type eq 'HASH' ) {
      my @keys = _hash_keys($value);
      return '{}' unless @keys;
      my $colon = $gap eq '' ? ':' : ': ';
      my @parts = map { _quote($_).$colon._write( $value->{$_}, $gap, $inner ) } @keys;
      return '{'.join( ',', @parts ).'}' if $gap eq '';
      return "{\n".$inner.join( ",\n".$inner, @parts )."\n".$current.'}';
    }
    if ( $type eq 'SCALAR' && !blessed $value ) {
      return $$value ? 'true' : 'false' if !defined $$value || $$value eq '1' || $$value eq '0';
    }
    croak __PACKAGE__.'->js_stringify cannot write a '.$type.' reference';
  }
  if ( CORE_BOOL ) {
    no warnings 'experimental::builtin';
    return $value ? 'true' : 'false' if builtin::is_bool($value);
  }
  return js_number($value) if _is_number($value);
  return _quote($value);
}

my %ESCAPE = ( '"' => '\\"', '\\' => '\\\\', "\b" => '\\b', "\f" => '\\f', "\n" => '\\n', "\r" => '\\r', "\t" => '\\t' );

# QuoteJSONString: the short escapes, \u00xx for other controls and lone surrogates, nothing
# else – no "/" and no non-ASCII escaped.
sub _quote {
  my ( $s ) = @_;
  $s = "$s";
  $s =~ s{([\x{0}-\x{1F}"\\\x{D800}-\x{DFFF}])}{ $ESCAPE{$1} // sprintf( '\\u%04x', ord $1 ) }ge;
  return '"'.$s.'"';
}

# Number::toString for a finite double; JSON.stringify writes NaN and the infinities as null.
sub js_number {
  my ( $n ) = @_;
  $n = 0 + $n;
  return 'null' if $n != $n || $n == 9**9**9 || $n == -9**9**9;
  return '0' if $n == 0;
  my $flags = B::svref_2object( \$n )->FLAGS;
  if ( ( $flags & B::SVf_IOK() ) && !( $flags & B::SVf_NOK() ) && abs($n) <= 9007199254740992 ) {
    return "$n";
  }
  $n = unpack 'd', pack 'd', $n;
  my $neg = $n < 0 ? '-' : '';
  my $abs = abs $n;
  my ( $digits, $exp );
  for my $p ( 1 .. 17 ) {
    my $s = sprintf '%.*e', $p - 1, $abs;
    next unless ( 0 + $s ) == $abs || $p == 17;
    ( $digits, $exp ) = $s =~ /\A([0-9.]+)e([-+][0-9]+)\z/;
    $digits =~ s/\.//;
    $digits =~ s/0+\z// if length $digits > 1;
    last;
  }
  my $k = length $digits;
  my $e = $exp + 1;     # the decimal point sits after $e digits
  my $out;
  if ( $k <= $e && $e <= 21 ) {
    $out = $digits.( '0' x ( $e - $k ) );
  }
  elsif ( 0 < $e && $e <= 21 ) {
    $out = substr( $digits, 0, $e ).'.'.substr( $digits, $e );
  }
  elsif ( -6 < $e && $e <= 0 ) {
    $out = '0.'.( '0' x -$e ).$digits;
  }
  else {
    my $x = $e - 1;
    my $mant = $k == 1 ? $digits : substr( $digits, 0, 1 ).'.'.substr( $digits, 1 );
    $out = $mant.'e'.( $x < 0 ? '-' : '+' ).abs($x);
  }
  return $neg.$out;
}

#### Reading ###########################################################

# A recursive-descent JSON.parse with V8's error messages. Objects come back as hashes tied
# to Skilletor::JSON::OrderedHash, so they keep the property order JavaScript gives them.

sub js_parse {
  my ( $text ) = @_;
  croak __PACKAGE__.'->js_parse needs a string' unless defined $text;
  my $p = { s => "$text", i => 0, len => length "$text" };
  _ws($p);
  my $value = _value($p);
  _ws($p);
  _fail_at( $p, 'Unexpected non-whitespace character after JSON', undef, 1 ) if $p->{i} < $p->{len};
  return $value;
}

sub _ws {
  my ( $p ) = @_;
  pos( $p->{s} ) = $p->{i};
  $p->{i} = pos( $p->{s} ) if $p->{s} =~ /\G[ \t\n\r]+/gc;
}

sub _peek { $_[0]{i} < $_[0]{len} ? substr( $_[0]{s}, $_[0]{i}, 1 ) : undef }

sub _eos { Skilletor::Error::JSON->throw('Unexpected end of JSON input') }

# The position as JavaScript counts it, in UTF-16 code units.
sub _units {
  my ( $p, $i ) = @_;
  my $before = substr( $p->{s}, 0, $i );
  my $astral = () = $before =~ /[^\x{0}-\x{FFFF}]/g;
  return $i + $astral;
}

sub _fail_at {
  my ( $p, $what, $i, $bare ) = @_;
  $i //= $p->{i};
  my $before = substr( $p->{s}, 0, $i );
  my $line   = 1;
  my $last   = -1;
  while ( $before =~ /\r\n|\r|\n/g ) {
    $line++;
    $last = pos($before) - 1;
  }
  my $pos    = _units( $p, $i );
  my $column = $last < 0 ? $pos + 1 : $pos - _units( $p, $last );
  Skilletor::Error::JSON->throw( $what.( $bare ? '' : ' in JSON' ).' at position '.$pos.' (line '.$line.' column '.$column.')' );
}

sub _unexpected_token {
  my ( $p ) = @_;
  my $i   = $p->{i};
  my $tok = substr( $p->{s}, $i, 1 );
  my $len = $p->{len};
  my $context;
  if ( $len <= 20 ) {
    $context = '"'.$p->{s}.'"';
  }
  else {
    my $start = $i - 10 < 0 ? 0 : $i - 10;
    my $end   = $i + 10 > $len ? $len : $i + 10;
    $context = ( $start > 0 ? '...' : '' ).'"'.substr( $p->{s}, $start, $end - $start ).'"'.( $end < $len ? '...' : '' );
  }
  Skilletor::Error::JSON->throw( "Unexpected token '".$tok."', ".$context.' is not valid JSON' );
}

sub _value {
  my ( $p ) = @_;
  my $c = _peek($p);
  _eos() unless defined $c;
  return _string($p) if $c eq '"';
  return _object($p) if $c eq '{';
  return _array($p)  if $c eq '[';
  return _number($p) if $c eq '-' || $c =~ /[0-9]/;
  return _literal( $p, 'true', JSON::MaybeXS::true() )  if $c eq 't';
  return _literal( $p, 'false', JSON::MaybeXS::false() ) if $c eq 'f';
  return _literal( $p, 'null', undef ) if $c eq 'n';
  _unexpected_token($p);
}

sub _literal {
  my ( $p, $word, $value ) = @_;
  for my $ch ( split //, $word ) {
    my $c = _peek($p);
    _eos() unless defined $c;
    _unexpected_token($p) unless $c eq $ch;
    $p->{i}++;
  }
  return $value;
}

sub _number {
  my ( $p ) = @_;
  my $start = $p->{i};
  my $s     = $p->{s};
  if ( _peek($p) eq '-' ) {
    $p->{i}++;
    my $c = _peek($p);
    _fail_at( $p, 'No number after minus sign' ) unless defined $c && $c =~ /[0-9]/;
  }
  my $int_start = $p->{i};
  if ( _peek($p) eq '0' ) {
    $p->{i}++;
    my $c = _peek($p);
    _fail_at( $p, 'Unexpected number' ) if defined $c && $c =~ /[0-9]/;
  }
  else {
    pos($s) = $p->{i};
    $s =~ /\G[0-9]+/gc;
    $p->{i} = pos($s);
  }
  my $simple = 1;
  if ( ( _peek($p) // '' ) eq '.' ) {
    $simple = 0;
    $p->{i}++;
    pos($s) = $p->{i};
    _fail_at( $p, 'Unterminated fractional number' ) unless $s =~ /\G[0-9]+/gc;
    $p->{i} = pos($s);
  }
  if ( ( _peek($p) // '' ) =~ /\A[eE]\z/ ) {
    $simple = 0;
    $p->{i}++;
    $p->{i}++ if ( _peek($p) // '' ) =~ /\A[-+]\z/;
    pos($s) = $p->{i};
    _fail_at( $p, 'Exponent part is missing a number' ) unless $s =~ /\G[0-9]+/gc;
    $p->{i} = pos($s);
  }
  my $text = substr( $s, $start, $p->{i} - $start );
  my $n = 0 + $text;
  # A JavaScript number is a double: an integer beyond 2**53 loses its low digits there.
  $n = unpack 'd', pack 'd', $n unless $simple && $p->{i} - $int_start <= 15;
  return $n;
}

my %UNESCAPE = ( '"' => '"', '\\' => '\\', '/' => '/', b => "\b", f => "\f", n => "\n", r => "\r", t => "\t" );

sub _string {
  my ( $p ) = @_;
  $p->{i}++;    # the opening quote
  my $s   = $p->{s};
  my $out = '';
  while (1) {
    pos($s) = $p->{i};
    if ( $s =~ /\G([^"\\\x{0}-\x{1F}]+)/gc ) {
      $out .= $1;
      $p->{i} = pos($s);
    }
    my $c = _peek($p);
    _fail_at( $p, 'Unterminated string' ) unless defined $c;
    if ( $c eq '"' ) {
      $p->{i}++;
      return $out;
    }
    _fail_at( $p, 'Bad control character in string literal' ) if ord($c) < 0x20;
    # a backslash
    $p->{i}++;
    my $e = _peek($p);
    _eos() unless defined $e;
    if ( exists $UNESCAPE{$e} ) {
      $out .= $UNESCAPE{$e};
      $p->{i}++;
      next;
    }
    _fail_at( $p, 'Bad escaped character' ) unless $e eq 'u';
    $p->{i}++;
    my $code = _hex4($p);
    if ( $code >= 0xD800 && $code <= 0xDBFF && substr( $s, $p->{i}, 2 ) eq '\\u' ) {
      my $save = $p->{i};
      $p->{i} += 2;
      my $low = _hex4($p);
      if ( $low >= 0xDC00 && $low <= 0xDFFF ) {
        $out .= chr( 0x10000 + ( ( $code - 0xD800 ) << 10 ) + ( $low - 0xDC00 ) );
        next;
      }
      $p->{i} = $save;
    }
    { no warnings qw( surrogate utf8 ); $out .= chr $code; }
  }
}

sub _hex4 {
  my ( $p ) = @_;
  my $v = 0;
  for ( 1 .. 4 ) {
    my $c = _peek($p);
    _fail_at( $p, 'Bad Unicode escape' ) unless defined $c && $c =~ /\A[0-9a-fA-F]\z/;
    $v = $v * 16 + hex $c;
    $p->{i}++;
  }
  return $v;
}

sub _object {
  my ( $p ) = @_;
  $p->{i}++;
  my $obj = js_ordered();
  _ws($p);
  my $c = _peek($p);
  if ( defined $c && $c eq '}' ) {
    $p->{i}++;
    return $obj;
  }
  _fail_at( $p, "Expected property name or '}'" ) unless defined $c && $c eq '"';
  while (1) {
    my $key = _string($p);
    _ws($p);
    _fail_at( $p, "Expected ':' after property name" ) unless ( _peek($p) // '' ) eq ':';
    $p->{i}++;
    _ws($p);
    $obj->{$key} = _value($p);
    _ws($p);
    my $n = _peek($p) // '';
    if ( $n eq '}' ) {
      $p->{i}++;
      return $obj;
    }
    _fail_at( $p, "Expected ',' or '}' after property value" ) unless $n eq ',';
    $p->{i}++;
    _ws($p);
    _fail_at( $p, 'Expected double-quoted property name' ) unless ( _peek($p) // '' ) eq '"';
  }
}

sub _array {
  my ( $p ) = @_;
  $p->{i}++;
  my @out;
  _ws($p);
  my $c = _peek($p);
  if ( defined $c && $c eq ']' ) {
    $p->{i}++;
    return \@out;
  }
  while (1) {
    _ws($p);
    push @out, _value($p);
    _ws($p);
    my $n = _peek($p) // '';
    if ( $n eq ']' ) {
      $p->{i}++;
      return \@out;
    }
    _fail_at( $p, "Expected ',' or ']' after array element" ) unless $n eq ',';
    $p->{i}++;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::JSON - JSON read and written exactly as the reference implementation does

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::JSON qw( js_parse js_stringify js_ordered );

  my $config = js_parse( $text );               # objects keep their key order
  $config->{sources}{shared} = js_ordered( git => 'https://github.com/Getty/skills' );
  my $out = js_stringify( $config, 2 )."\n";    # JSON.stringify(config, null, 2) + "\n"

=head1 DESCRIPTION

The reference implementation reads every file with C<JSON.parse> and writes
every file with C<JSON.stringify(value, null, 2)>; a lock file, C<trust.json>
or an edited config written by either implementation must be the same bytes.
L<JSON::MaybeXS> cannot give that: its pretty printer indents by three, sorts
or scrambles keys, and escapes differently. This module is the JavaScript
behaviour, in Perl.

Strings in and out are character strings; decode and encode UTF-8 at the file
boundary (L<Skilletor::FSUtil/read_text>).

=head2 js_parse

  my $value = js_parse($text);

C<JSON.parse>. An object is a hash tied to L<Skilletor::JSON::OrderedHash>
(C<keys> in JavaScript property order; a duplicate key keeps its first place
and its last value), C<true>/C<false> are L<JSON::MaybeXS> booleans, C<null> is
C<undef>, a number is a double as in JavaScript (C<1e400> is infinity). A text
that is no JSON throws L<Skilletor::Error::JSON> with V8's message, position
and line/column counted in UTF-16 code units as V8 counts them, e.g.
C<Expected ',' or '}' after property value in JSON at position 6 (line 1 column 7)>.

=head2 js_stringify

  my $text = js_stringify( $value );      # JSON.stringify(value)
  my $text = js_stringify( $value, 2 );   # JSON.stringify(value, null, 2)
  my $text = js_stringify( $value, "\t" ); # JSON.stringify(value, null, "\t")

C<JSON.stringify>, byte for byte. Keys of a hash from L</js_parse> or
L</js_ordered> come in their property order; keys of a plain Perl hash come as
the reference writes a sorted object (C<Object.keys(x).sort()>, then
JavaScript's reordering of array-index keys first). Strings escape only C<">,
C<\>, control characters and lone surrogates. Numbers are written by
L</js_number>; a scalar is a number when Perl holds it as one and not as a
string (the rule of L<JSON::PP>). C<undef> is C<null>; a blessed object needs a
C<TO_JSON> method. No trailing newline: the reference's files add C<"\n">.

=head2 js_ordered

  my $h = js_ordered( source => 'shared', version => 'git:ab12cd3' );

A hash reference that keeps the given key order, for objects whose key order
the reference fixes (a lock entry: C<source>, C<version>, C<files>, …).

=head2 js_sort_keys

  my @sorted = js_sort_keys(@keys);

C<Array.prototype.sort> without a comparator: by UTF-16 code units, so
characters beyond U+FFFF sort before U+E000 .. U+FFFF.

=head2 js_number

  js_number(0.1 + 0.2);   # "0.30000000000000004"

C<Number.prototype.toString> of a double: the shortest digits that read back
as the same double, in JavaScript's fixed or exponent form (C<1e+21>,
C<1e-7>); C<null> for NaN and the infinities, as C<JSON.stringify> writes them.

=head2 js_type

  js_type($value);   # 'null', 'boolean', 'number', 'string', 'array' or 'object'

C<typeof> of a parsed value, with C<null> and arrays told apart – the question
a validator asks (C<typeof v !== "string">, C<Array.isArray(v)>). An absent key
is C<undefined> in JavaScript: test it with C<exists>.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
