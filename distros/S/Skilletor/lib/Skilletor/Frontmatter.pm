package Skilletor::Frontmatter;
# ABSTRACT: The reference's YAML subset – agent frontmatter and bundle files

use strict;
use warnings;

use Exporter qw( import );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed );
use Skilletor::Error;
use Skilletor::Error::Frontmatter;
use Skilletor::JSON qw( js_ordered );
use Skilletor::JSString qw( js_trim js_ws_re );

our $VERSION = '0.001';

our @EXPORT_OK = qw( split_frontmatter parse_yaml_document is_yaml_float );

# JavaScript's `.` (no line terminator) and `\s`.
my $DOT = qr/[^\n\r\x{2028}\x{2029}]/;
my $WS  = js_ws_re();
my $LT  = qr/[\n\r\x{2028}\x{2029}]/;

my $OPEN  = qr/\A---[ \t]*\r?\n/;
# /^---[ \t]*(?:\r?\n|$)/m: JavaScript's multiline ^ and $ sit at any line terminator.
my $CLOSE = qr/(?:\A|(?<=$LT))---[ \t]*(?:\r?\n|(?=$LT)|\z)/;

# "key": / 'key': / plain key, then `:` followed by whitespace or the end.
my $KEY_RE = qr/\A(?:"((?:[^"\\]|\\$DOT)*)"|'((?:[^']|'')*)'|((?!$WS)[^"'#&*!|>\[\]{},?:\-][^:#]*?))[ \t]*:(?:[ \t]+($DOT*))?\z/;

my %ESCAPES = (
  '0' => "\0", a => "\x07", b => "\b", t => "\t", "\t" => "\t", n => "\n", v => "\x0B", f => "\f", r => "\r",
  e => "\x1b", ' ' => ' ', '"' => '"', '/' => '/', '\\' => '\\', N => "\x{85}", _ => "\x{A0}", L => "\x{2028}",
  P => "\x{2029}",
);

sub split_frontmatter {
  my ( $text ) = @_;
  return { data => js_ordered(), body => $text } unless $text =~ $OPEN;
  my $start = $+[0];
  pos($text) = $start;
  Skilletor::Error::Frontmatter->throw('frontmatter: no closing --- line') unless $text =~ /$CLOSE/g;
  my ( $close, $after ) = ( $-[0], $+[0] );
  my $yaml = substr $text, $start, $close - $start;
  ( my $body = substr $text, $after ) =~ s/\A(?:[ \t]*\r?\n)+//;
  return { data => _parse_yaml( $yaml, 2, 'frontmatter line' ), body => $body };
}

sub parse_yaml_document {
  my ( $text ) = @_;
  return _parse_yaml( $text, 1, 'line' );
}

sub is_yaml_float { blessed $_[0] && $_[0]->isa('Skilletor::Frontmatter::Float') ? 1 : 0 }

#### The parser ########################################################

sub _fail {
  my ( $line, $message ) = @_;
  Skilletor::Error::Frontmatter->throw( ( $line ? $line->{label} : 'line' ).' '.( $line ? $line->{no} : '?' ).': '.$message );
}

sub _indent_of {
  my ( $line ) = @_;
  my ($m) = $line->{raw} =~ /\A([ \t]*)/;
  _fail( $line, 'tabs are not allowed in indentation' ) if index( $m, "\t" ) >= 0;
  return length $m;
}

sub _skippable {
  my ( $line ) = @_;
  my $t = js_trim( $line->{raw} );
  return ( $t eq '' || substr( $t, 0, 1 ) eq '#' ) ? 1 : 0;
}

sub _is_seq_item {
  my ( $text ) = @_;
  return ( $text eq '-' || substr( $text, 0, 2 ) eq '- ' ) ? 1 : 0;
}

sub _parse_yaml {
  my ( $yaml, $first_line, $label ) = @_;
  my $i = 0;
  my @lines = map { +{ no => $i++ + $first_line, raw => $_, label => $label } } split /\r?\n/, $yaml, -1;
  my $p = bless { lines => \@lines }, 'Skilletor::Frontmatter::_Parser';
  my ( $value, $pos ) = $p->mapping( 0, 0 );
  _fail( $lines[$pos], 'unexpected content' ) if $pos < @lines;
  return $value;
}

package    # hide from PAUSE
  Skilletor::Frontmatter::_Parser;

sub next_content {
  my ( $self, $pos ) = @_;
  my $lines = $self->{lines};
  $pos++ while $pos < @$lines && Skilletor::Frontmatter::_skippable( $lines->[$pos] );
  return $pos;
}

sub mapping {
  my ( $self, $start, $indent ) = @_;
  my $lines = $self->{lines};
  my $obj = Skilletor::JSON::js_ordered();
  my $pos = $start;
  for ( ;; ) {
    $pos = $self->next_content($pos);
    last if $pos >= @$lines;
    my $line = $lines->[$pos];
    my $ind  = Skilletor::Frontmatter::_indent_of($line);
    last if $ind < $indent;
    Skilletor::Frontmatter::_fail( $line, 'unexpected indentation' ) if $ind > $indent;
    my $text = substr $line->{raw}, $ind;
    Skilletor::Frontmatter::_fail( $line, 'unexpected sequence item' ) if Skilletor::Frontmatter::_is_seq_item($text);
    my @m = $text =~ $KEY_RE or Skilletor::Frontmatter::_fail( $line, 'expected `key: value`' );
    my $key = defined $m[0] ? Skilletor::Frontmatter::_unescape_double( $m[0], $line )
      : defined $m[1] ? $m[1] =~ s/''/'/gr
      : Skilletor::JSString::js_trim( $m[2] );
    Skilletor::Frontmatter::_fail( $line, 'duplicate key "'.$key.'"' ) if exists $obj->{$key};
    my ( $value, $next ) = $self->value( $m[3] // '', $pos + 1, $indent, $line );
    $obj->{$key} = $value;
    $pos = $next;
  }
  return ( $obj, $pos );
}

# The value after `key:` on $line; $pos is the line after it.
sub value {
  my ( $self, $rest, $pos, $indent, $line ) = @_;
  my $lines = $self->{lines};
  my $r = Skilletor::JSString::js_trim($rest);
  return $self->block_scalar( $r, $pos, $indent, $line ) if $r =~ /\A[|>]/;
  if ( $r eq '' || substr( $r, 0, 1 ) eq '#' ) {
    my $q = $self->next_content($pos);
    return ( undef, $q ) if $q >= @$lines;
    my $next = $lines->[$q];
    my $ind  = Skilletor::Frontmatter::_indent_of($next);
    my $text = substr $next->{raw}, $ind;
    if ( $ind > $indent ) {
      return Skilletor::Frontmatter::_is_seq_item($text) ? $self->sequence( $q, $ind ) : $self->mapping( $q, $ind );
    }
    return $self->sequence( $q, $ind ) if $ind == $indent && Skilletor::Frontmatter::_is_seq_item($text);
    return ( undef, $q );
  }
  # An inline value, possibly continued on more-indented lines (folded with spaces).
  my @parts = ($r);
  my $p = $pos;
  for ( ;; ) {
    my $q = $self->next_content($p);
    last if $q >= @$lines || Skilletor::Frontmatter::_indent_of( $lines->[$q] ) <= $indent;
    push @parts, Skilletor::JSString::js_trim( $lines->[$q]{raw} );
    $p = $q + 1;
  }
  return ( Skilletor::Frontmatter::_inline( $r, $line ), $pos ) if @parts == 1;
  return ( Skilletor::Frontmatter::_inline( join( ' ', @parts ), $line ), $p ) if $r =~ /\A["'\[{]/;
  Skilletor::Frontmatter::_fail( $line, 'anchors, aliases and tags are not supported' ) if $r =~ /\A[&*!]/;
  return ( join( ' ', map { Skilletor::Frontmatter::_strip_comment($_) } @parts ), $p );
}

sub sequence {
  my ( $self, $start, $indent ) = @_;
  my $lines = $self->{lines};
  my @arr;
  my $pos = $start;
  for ( ;; ) {
    $pos = $self->next_content($pos);
    last if $pos >= @$lines;
    my $line = $lines->[$pos];
    my $ind  = Skilletor::Frontmatter::_indent_of($line);
    last if $ind < $indent;
    Skilletor::Frontmatter::_fail( $line, 'unexpected indentation in a sequence' ) if $ind > $indent;
    my $text = substr $line->{raw}, $ind;
    last unless Skilletor::Frontmatter::_is_seq_item($text);
    my $item = Skilletor::JSString::js_trim( substr $text, 1 );
    if ( $item eq '' || substr( $item, 0, 1 ) eq '#' ) {
      Skilletor::Frontmatter::_fail( $line, 'nested blocks inside sequences are not supported' );
    }
    Skilletor::Frontmatter::_fail( $line, 'mappings inside sequences are not supported' ) if $item =~ $KEY_RE;
    Skilletor::Frontmatter::_fail( $line, 'nested collections are not supported' ) if $item =~ /\A[\[{]/;
    push @arr, Skilletor::Frontmatter::_inline( $item, $line );
    $pos++;
  }
  return ( \@arr, $pos );
}

sub block_scalar {
  my ( $self, $header, $pos, $indent, $line ) = @_;
  my $lines = $self->{lines};
  my @h = $header =~ /\A([|>])([+-]?)([1-9]?)[ \t]*(?:#$DOT*)?\z/
    or Skilletor::Frontmatter::_fail( $line, 'unsupported block scalar header "'.$header.'"' );
  my $folded = $h[0] eq '>';
  my $chomp  = $h[1];
  my $content_indent = length $h[2] ? $indent + $h[2] : -1;
  my @collected;
  my $p = $pos;
  while ( $p < @$lines ) {
    my $l = $lines->[$p];
    if ( Skilletor::JSString::js_trim( $l->{raw} ) eq '' ) {
      push @collected, $l;
      $p++;
      next;
    }
    my $ind = Skilletor::Frontmatter::_indent_of($l);
    last if $ind <= $indent;
    $content_indent = $ind if $content_indent == -1;
    Skilletor::Frontmatter::_fail( $l, 'block scalar line is less indented than its first line' ) if $ind < $content_indent;
    push @collected, $l;
    $p++;
  }
  my @texts = map { Skilletor::JSString::js_trim( $_->{raw} ) eq '' ? '' : substr( $_->{raw}, $content_indent ) } @collected;
  my $trailing = 0;
  while ( @texts && $texts[-1] eq '' ) {
    pop @texts;
    $trailing++;
  }
  my $body;
  if ( !$folded ) {
    $body = join "\n", @texts;
  }
  else {
    $body = '';
    my ( $pending, $first, $prev_more ) = ( 0, 1, 0 );
    for my $t (@texts) {
      if ( $t eq '' ) {
        $pending++;
        next;
      }
      my $more = $t =~ /\A[ \t]/ ? 1 : 0;
      if    ($first)                { $body = $t }
      elsif ( $pending > 0 )        { $body .= ( "\n" x $pending ).$t }
      elsif ( $more || $prev_more ) { $body .= "\n".$t }
      else                          { $body .= ' '.$t }
      $first     = 0;
      $pending   = 0;
      $prev_more = $more;
    }
  }
  return ( $body, $p ) if $chomp eq '-';
  return ( '', $p ) if $body eq '' && $chomp ne '+';
  return ( $body."\n".( $chomp eq '+' ? "\n" x $trailing : '' ), $p );
}

package Skilletor::Frontmatter;

#### Inline values #####################################################

sub _strip_comment {
  my ( $s ) = @_;
  return js_trim( $s =~ /(?:\A|[ \t])#/ ? substr( $s, 0, $-[0] ) : $s );
}

sub _typed_plain {
  my ( $s ) = @_;
  return undef if $s eq '' || $s eq '~' || $s =~ /\A(?:null|Null|NULL)\z/;
  return JSON::MaybeXS::true()  if $s =~ /\A(?:true|True|TRUE)\z/;
  return JSON::MaybeXS::false() if $s =~ /\A(?:false|False|FALSE)\z/;
  if ( $s =~ /\A[-+]?([0-9]+)\z/ ) {
    ( my $digits = $1 ) =~ s/\A0+(?=.)//;
    # Number.isSafeInteger: |n| <= 2**53 - 1, else the text stays a string.
    my $safe = length($digits) < 16 || ( length($digits) == 16 && $digits le '9007199254740991' );
    return $safe ? 0 + $s : $s;
  }
  if ( $s =~ /\A[-+]?(?:\.[0-9]+|[0-9]+\.[0-9]*|[0-9]+(?=[eE]))(?:[eE][-+]?[0-9]+)?\z/ ) {
    no warnings 'numeric';
    return Skilletor::Frontmatter::Float->new( 0 + $s );
  }
  return $s;
}

sub _unescape_double {
  my ( $s, $line ) = @_;
  my $out = '';
  my $n = length $s;
  for ( my $i = 0; $i < $n; $i++ ) {
    my $ch = substr $s, $i, 1;
    if ( $ch ne '\\' ) {
      $out .= $ch;
      next;
    }
    $i++;
    _fail( $line, 'dangling backslash in a double-quoted string' ) if $i >= $n;
    my $e = substr $s, $i, 1;
    my $hex_len = $e eq 'x' ? 2 : $e eq 'u' ? 4 : $e eq 'U' ? 8 : 0;
    if ($hex_len) {
      my $hex = substr $s, $i + 1, $hex_len;
      _fail( $line, 'bad \\'.$e.' escape' ) unless $hex =~ /\A[0-9a-fA-F]{$hex_len}\z/;
      my $cp = hex $hex;
      # Above U+10FFFF the reference refuses the escape like any other bad one.
      _fail( $line, 'bad \\'.$e.' escape' ) if $cp > 0x10FFFF;
      no warnings qw( surrogate nonchar non_unicode );
      $out .= chr $cp;
      $i += $hex_len;
    }
    elsif ( exists $ESCAPES{$e} ) {
      $out .= $ESCAPES{$e};
    }
    else {
      _fail( $line, 'unknown escape \\'.$e );
    }
  }
  return $out;
}

# One quoted scalar at substr($s, $i, 1) (a quote): the value and the index after it.
sub _quoted {
  my ( $s, $i, $line ) = @_;
  my $q = substr $s, $i, 1;
  my $n = length $s;
  my $j = $i + 1;
  if ( $q eq "'" ) {
    my $out = '';
    for ( ;; ) {
      _fail( $line, 'unterminated single-quoted string' ) if $j >= $n;
      if ( substr( $s, $j, 1 ) eq "'" ) {
        if ( $j + 1 < $n && substr( $s, $j + 1, 1 ) eq "'" ) {
          $out .= "'";
          $j += 2;
          next;
        }
        return ( $out, $j + 1 );
      }
      $out .= substr $s, $j++, 1;
    }
  }
  for ( ;; ) {
    _fail( $line, 'unterminated double-quoted string' ) if $j >= $n;
    my $c = substr $s, $j, 1;
    if ( $c eq '\\' ) {
      $j += 2;
      next;
    }
    return ( _unescape_double( substr( $s, $i + 1, $j - $i - 1 ), $line ), $j + 1 ) if $c eq '"';
    $j++;
  }
}

sub _assert_end {
  my ( $s, $i, $line ) = @_;
  my $rest = js_trim( $i < length $s ? substr( $s, $i ) : '' );
  _fail( $line, 'unexpected text after a value: "'.$rest.'"' ) if $rest ne '' && substr( $rest, 0, 1 ) ne '#';
}

sub _char { $_[1] < length $_[0] ? substr( $_[0], $_[1], 1 ) : '' }

# A scalar inside a flow collection: quoted, or plain up to `,` or the closing bracket.
sub _flow_scalar {
  my ( $s, $i, $closer, $line ) = @_;
  $i++ while _char( $s, $i ) eq ' ' || _char( $s, $i ) eq "\t";
  my $c = _char( $s, $i );
  return _quoted( $s, $i, $line ) if $c eq '"' || $c eq "'";
  _fail( $line, 'nested collections are not supported' ) if $c eq '[' || $c eq '{';
  my $j = $i;
  $j++ while $j < length $s && _char( $s, $j ) ne ',' && _char( $s, $j ) ne $closer;
  return ( _typed_plain( js_trim( substr $s, $i, $j - $i ) ), $j );
}

sub _flow_separator {
  my ( $s, $j, $closer, $line ) = @_;
  $j++ while _char( $s, $j ) eq ' ' || _char( $s, $j ) eq "\t";
  return ( 0, $j + 1 ) if _char( $s, $j ) eq ',';
  return ( 1, $j + 1 ) if _char( $s, $j ) eq $closer;
  _fail( $line, 'expected "," or "'.$closer.'"' );
}

sub _inline {
  my ( $value, $line ) = @_;
  my $s = js_trim($value);
  _fail( $line, 'anchors, aliases and tags are not supported' ) if $s =~ /\A[&*!]/;
  my $c = _char( $s, 0 );
  if ( $c eq '"' || $c eq "'" ) {
    my ( $v, $j ) = _quoted( $s, 0, $line );
    _assert_end( $s, $j, $line );
    return $v;
  }
  if ( $c eq '[' ) {
    my @arr;
    if ( $s =~ /\A\[$WS*\]/ ) {
      _assert_end( $s, index( $s, ']' ) + 1, $line );
      return \@arr;
    }
    my $j = 1;
    for ( ;; ) {
      my ( $v, $k ) = _flow_scalar( $s, $j, ']', $line );
      push @arr, $v;
      my ( $done, $n ) = _flow_separator( $s, $k, ']', $line );
      $j = $n;
      last if $done;
    }
    _assert_end( $s, $j, $line );
    return \@arr;
  }
  if ( $c eq '{' ) {
    my $obj = js_ordered();
    if ( $s =~ /\A\{$WS*\}/ ) {
      _assert_end( $s, index( $s, '}' ) + 1, $line );
      return $obj;
    }
    my $j = 1;
    for ( ;; ) {
      $j++ while _char( $s, $j ) eq ' ';
      my $colon = index $s, ':', $j;
      _fail( $line, 'expected `key: value` in a flow mapping' ) if $colon == -1;
      ( my $key = js_trim( substr $s, $j, $colon - $j ) ) =~ s/\A(["'])($DOT*)\1\z/$2/;
      _fail( $line, 'bad key in a flow mapping' ) if $key eq '' || $key =~ /[,{}\[\]]/;
      my ( $v, $k ) = _flow_scalar( $s, $colon + 1, '}', $line );
      $obj->{$key} = $v;
      my ( $done, $n ) = _flow_separator( $s, $k, '}', $line );
      $j = $n;
      last if $done;
    }
    _assert_end( $s, $j, $line );
    return $obj;
  }
  return _typed_plain( _strip_comment($s) );
}

package Skilletor::Frontmatter::Float;

# A YAML float: JavaScript cannot tell 1 from 1.0, TOML can (Codex agents).
sub new   { my ( $class, $value ) = @_; return bless { value => $value }, $class }
sub value { $_[0]{value} }

package Skilletor::Frontmatter;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Frontmatter - The reference's YAML subset – agent frontmatter and bundle files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Frontmatter qw( split_frontmatter parse_yaml_document );

  my $fm = split_frontmatter($agent_markdown);
  # { data => { name => 'reviewer', tools => [ 'Read', 'Grep' ] }, body => "You review…\n" }

  my $bundle = parse_yaml_document($bundle_yaml);    # line numbers from 1

=head1 DESCRIPTION

The reference's C<frontmatter.ts>: a deliberately small subset of YAML, enough
for what agent files and bundle files (spec §15.1) use – nested block
mappings, block and flow sequences of scalars, flat flow mappings, plain,
quoted and block (C<|>, C<E<gt>>) scalars, comments. Anything else – anchors,
aliases, tags, mappings inside sequences, nested flow collections – is a
L<Skilletor::Error::Frontmatter> naming the line, worded as the reference words
it. Ported rather than taken from a YAML module, so a file reads the same and
fails the same in both implementations.

Values: mappings are insertion-ordered hashes (L<Skilletor::JSON/js_ordered>),
sequences array references, C<null> C<undef>, booleans C<JSON::MaybeXS>
booleans, integers numbers (a non-safe integer stays its text), floats
L</Skilletor::Frontmatter::Float> objects.

=head2 split_frontmatter

  my $fm = split_frontmatter($text);   # { data, body }

Without an opening C<---> line the data is empty and the body the whole text.
The body is what follows the closing fence, leading blank lines removed.

=head2 parse_yaml_document

A whole document in the same subset (a bundle file); errors count lines from 1.

=head2 is_yaml_float

True for a L</Skilletor::Frontmatter::Float>.

=head1 Skilletor::Frontmatter::Float

A YAML float; C<< ->value >> is the number.

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
