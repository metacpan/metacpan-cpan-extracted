package Skilletor::TOML;
# ABSTRACT: The reference's TOML writer – what a Codex agent role needs

use strict;
use warnings;

use Exporter qw( import );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed reftype );
use Skilletor::Error::TOML;
use Skilletor::JSON qw( js_number js_sort_keys js_stringify js_type );
use Skilletor::JSON::OrderedHash;

our $VERSION = '0.008000';

our @EXPORT_OK = qw( stringify_toml toml_key toml_float is_toml_float );

my $BARE_KEY = qr/\A[A-Za-z0-9_-]+\z/;

sub toml_key {
  my ( $key ) = @_;
  return $key =~ $BARE_KEY ? $key : _basic_string($key);
}

sub toml_float { Skilletor::TOML::Float->new( $_[0] ) }

sub is_toml_float { blessed $_[0] && $_[0]->isa('Skilletor::TOML::Float') ? 1 : 0 }

#### Strings ###########################################################

my %ESCAPE = ( '\\' => '\\\\', '"' => '\\"', "\n" => '\\n', "\t" => '\\t', "\r" => '\\r' );

# What a basic string escapes: `\`, `"` and every control character. The multi-line form
# keeps LF and tab literal.
my $BASIC_ESCAPED     = qr/[\\"\x00-\x1F\x7F]/;
my $MULTILINE_ESCAPED = qr/[\\"\x00-\x08\x0B-\x1F\x7F]/;

sub _escape_basic {
  my ( $s, $keep_newlines ) = @_;
  my $re = $keep_newlines ? $MULTILINE_ESCAPED : $BASIC_ESCAPED;
  $s =~ s/($re)/ $ESCAPE{$1} \/\/ sprintf( '\\u%04X', ord $1 ) /ge;
  return $s;
}

sub _basic_string { '"'._escape_basic( $_[0], 0 ).'"' }

# Control characters a literal string cannot hold (tab and LF are fine; CR is refused too, so
# CRLF survives exactly). A trailing `'` goes to the basic form, as in the reference.
my $LITERAL_UNSAFE = qr/[\x00-\x08\x0A-\x1F\x7F]/;

sub _multiline_string {
  my ( $s ) = @_;
  ( my $without_lf = $s ) =~ s/\n//g;
  return "'''\n$s'''" if index( $s, "'''" ) < 0 && $s !~ /'\z/ && $without_lf !~ $LITERAL_UNSAFE;
  return qq("""\n)._escape_basic( $s, 1 ).'"""';
}

#### Values ############################################################

sub _fail { Skilletor::Error::TOML->throw( $_[0] ) }

my $INF = 9**9**9;

# String(n) for any number, NaN and the infinities included.
sub _number_text {
  my ( $n ) = @_;
  return 'NaN' if $n != $n;
  return $n > 0 ? 'Infinity' : '-Infinity' if $n == $INF || $n == -$INF;
  return js_number($n);
}

sub _is_finite { $_[0] == $_[0] && $_[0] != $INF && $_[0] != -$INF }

sub _is_safe_integer {
  my ( $n ) = @_;
  return _is_finite($n) && $n == int($n) && abs($n) <= 9007199254740991;
}

sub _is_table {
  my ( $v ) = @_;
  return ref $v && ( reftype $v // '' ) eq 'HASH' && !is_toml_float($v) && !JSON::MaybeXS::is_bool($v);
}

sub _scalar {
  my ( $v, $where, $multiline ) = @_;
  if ( is_toml_float($v) ) {
    my $x = $v->value;
    _fail( $where.': '._number_text($x).' is not a finite float' ) unless _is_finite($x);
    my $text = js_number($x);
    return $text =~ /[.eE]/ ? $text : $text.'.0';
  }
  my $type = js_type($v);
  return $multiline ? _multiline_string($v) : _basic_string($v) if $type eq 'string';
  return $v ? 'true' : 'false' if $type eq 'boolean';
  if ( $type eq 'number' ) {
    _fail( $where.': '._number_text($v).' is not an integer (use TomlFloat)' ) unless _is_safe_integer($v);
    return js_number($v);
  }
  # JSON.stringify(v): undefined for what JSON cannot write.
  my $json = defined $v ? eval { js_stringify($v) } // 'undefined' : 'null';
  _fail( $where.': unsupported value '.$json );
}

sub _value {
  my ( $v, $where, $multiline ) = @_;
  if ( ref $v && ( reftype $v // '' ) eq 'ARRAY' ) {
    for my $item (@$v) {
      _fail( $where.': only string arrays are supported' ) unless js_type($item) eq 'string';
    }
    return '['.join( ', ', map { _basic_string($_) } @$v ).']';
  }
  return _scalar( $v, $where, $multiline );
}

# A JavaScript object's property order: a tied ordered hash keeps it; a plain hash is written
# as JSON.stringify writes a sorted object – index keys ascending, then the rest sorted.
sub _keys {
  my ( $h ) = @_;
  my $tied = tied %$h;
  return $tied->keys_in_order if blessed $tied && $tied->isa('Skilletor::JSON::OrderedHash');
  my @keys = keys %$h;
  my @index = sort { $a <=> $b } grep { Skilletor::JSON::OrderedHash->is_index_key($_) } @keys;
  return ( @index, js_sort_keys( grep { !Skilletor::JSON::OrderedHash->is_index_key($_) } @keys ) );
}

sub stringify_toml {
  my ( $table, $opts ) = @_;
  my %multiline = map { ( $_ => 1 ) } @{ ( $opts // {} )->{multiline} // [] };
  my ( @lines, @tables );
  for my $k ( _keys($table) ) {
    my $v = $table->{$k};
    if   ( _is_table($v) ) { push @tables, [ $k, $v ] }
    else                   { push @lines, toml_key($k).' = '._value( $v, $k, $multiline{$k} ) }
  }
  for my $t (@tables) {
    my ( $k, $sub ) = @$t;
    push @lines, '', '['.toml_key($k).']';
    for my $sk ( _keys($sub) ) {
      my $sv = $sub->{$sk};
      _fail( $k.'.'.$sk.': nested tables are not supported' ) if _is_table($sv);
      push @lines, toml_key($sk).' = '._value( $sv, $k.'.'.$sk, 0 );
    }
  }
  return join( "\n", @lines )."\n";
}

package    # hide from PAUSE
  Skilletor::TOML::Float;

# A TOML float: Perl, like JavaScript, cannot tell 1 from 1.0 by the value alone.
sub new   { my ( $class, $value ) = @_; return bless { value => $value }, $class }
sub value { $_[0]{value} }

package Skilletor::TOML;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::TOML - The reference's TOML writer – what a Codex agent role needs

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::JSON qw( js_ordered );
  use Skilletor::TOML qw( stringify_toml toml_float );

  my $text = stringify_toml(
    js_ordered(
      name                   => 'reviewer',
      temperature            => toml_float(0.5),
      developer_instructions => "You review.\n",
      sandbox                => js_ordered( network_access => JSON::MaybeXS::true() ),
    ),
    { multiline => ['developer_instructions'] },
  );

=head1 DESCRIPTION

The reference's C<toml.ts> (spec §14.7): a minimal TOML writer for strings,
integers, floats, booleans, string arrays and one level of tables – exactly
what a Codex agent role needs. Its text is the reference's, byte for byte.

Strings are the whole game. A single-line value is a basic string with every
C<\>, C<"> and control character escaped. A key listed in C<multiline> is
written as a multi-line literal string when its content allows (readable, no
escapes), else as a multi-line basic string that escapes every C<\> and C<"> –
so no content can close the string early.

Values are told apart as the reference's C<typeof> tells them (see
L<Skilletor::JSON/js_type>): a string is a string even when it holds digits, a
number is an integer or an error, a float is a L</toml_float>. Booleans are
C<JSON::MaybeXS> booleans or Perl's own. A hash is a table; an ordered hash
(L<Skilletor::JSON/js_ordered>) keeps its key order, a plain hash is written
with its keys sorted. A value TOML cannot hold is a L<Skilletor::Error::TOML>
with the reference's message.

=head2 stringify_toml

  my $text = stringify_toml( $table, { multiline => [ @keys ] } );

The table as TOML text (characters, not bytes): top-level keys first, then one
C<[table]> section per table value, each line ending in a newline.

=head2 toml_key

  toml_key('a b');   # '"a b"'

A key: bare when it is made of C<A-Za-z0-9_->, else a basic string.

=head2 toml_float

  toml_float(1);   # written as 1.0

Marks a number as a TOML float (the reference's C<TomlFloat>); C<< ->value >>
is the number.

=head2 is_toml_float

True for what L</toml_float> returns.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
