package TOON::PP;

use v5.40;
use feature 'signatures';

use Scalar::Util qw(looks_like_number blessed);
use TOON::Error;

our $VERSION = '0.0.1';

sub new ($class, %opts) {
  return bless {
    pretty    => $opts{pretty}    // 0,
    canonical => $opts{canonical} // 0,
    indent    => $opts{indent}    // 2,
  }, $class;
}

sub encode ($self, $data) {
  return $self->_encode_value($data, 0);
}

sub decode ($self, $text) {
  my $state = {
    text => $text,
    len  => length($text),
    pos  => 0,
  };

  $self->_skip_ws($state);
  my $value = $self->_parse_value($state);
  $self->_skip_ws($state);

  if ($state->{pos} < $state->{len}) {
    $self->_throw($state, 'Trailing characters after document');
  }

  return $value;
}

sub _encode_value ($self, $value, $level) {
  return 'null' if !defined $value;

  if (blessed($value)) {
    die TOON::Error->new(
      message => 'Encoding blessed references is not supported',
      line    => 1,
      column  => 1,
      offset  => 0,
    );
  }

  my $ref = ref $value;

  if (!$ref) {
    return 'true'  if $value eq 'true';
    return 'false' if $value eq 'false';

    if ($value =~ /\A(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/ || looks_like_number($value)) {
      return 0 + $value;
    }

    return $self->_quote_string($value);
  }

  if ($ref eq 'ARRAY') {
    return $self->_encode_array($value, $level);
  }

  if ($ref eq 'HASH') {
    return $self->_encode_hash($value, $level);
  }

  die TOON::Error->new(
    message => "Encoding $ref references is not supported",
    line    => 1,
    column  => 1,
    offset  => 0,
  );
}

sub _encode_array ($self, $array, $level) {
  return '[]' unless @$array;

  my @items = map { $self->_encode_value($_, $level + 1) } @$array;

  return '[' . join(', ', @items) . ']'
    unless $self->{pretty};

  my $pad      = ' ' x ($self->{indent} * $level);
  my $childpad = ' ' x ($self->{indent} * ($level + 1));

  return "[\n"
    . join(",\n", map { $childpad . $_ } @items)
    . "\n$pad]";
}

sub _encode_hash ($self, $hash, $level) {
  return '{}' unless %$hash;

  my @keys = keys %$hash;
  @keys = sort @keys if $self->{canonical};

  my @pairs = map {
    my $key = $_ =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/
      ? $_
      : $self->_quote_string($_);
    $key . ': ' . $self->_encode_value($hash->{$_}, $level + 1);
  } @keys;

  return '{' . join(', ', @pairs) . '}'
    unless $self->{pretty};

  my $pad      = ' ' x ($self->{indent} * $level);
  my $childpad = ' ' x ($self->{indent} * ($level + 1));

  return "{\n"
    . join(",\n", map { $childpad . $_ } @pairs)
    . "\n$pad}";
}

sub _quote_string ($self, $string) {
  $string =~ s/\\/\\\\/g;
  $string =~ s/"/\\"/g;
  $string =~ s/\n/\\n/g;
  $string =~ s/\r/\\r/g;
  $string =~ s/\t/\\t/g;
  $string =~ s/\f/\\f/g;
  $string =~ s/\x08/\\b/g;
  return qq{"$string"};
}

sub _parse_value ($self, $state) {
  $self->_skip_ws($state);

  my $ch = $self->_peek($state);
  $self->_throw($state, 'Unexpected end of input') unless defined $ch;

  return $self->_parse_object($state) if $ch eq '{';
  return $self->_parse_array($state)  if $ch eq '[';
  return $self->_parse_string($state) if $ch eq '"';

  if ($self->_consume_literal($state, 'null'))  { return undef }
  if ($self->_consume_literal($state, 'true'))  { return 1 }
  if ($self->_consume_literal($state, 'false')) { return 0 }

  if ($ch =~ /[-0-9]/) {
    return $self->_parse_number($state);
  }

  $self->_throw($state, "Unexpected character '$ch'");
}

sub _parse_object ($self, $state) {
  $self->_expect($state, '{');
  $self->_skip_ws($state);

  my %hash;

  if (($self->_peek($state) // '') eq '}') {
    $state->{pos}++;
    return \%hash;
  }

  while (1) {
    $self->_skip_ws($state);
    my $key = $self->_parse_key($state);
    $self->_skip_ws($state);
    $self->_expect($state, ':');
    $self->_skip_ws($state);
    $hash{$key} = $self->_parse_value($state);
    $self->_skip_ws($state);

    my $ch = $self->_peek($state);
    if (defined $ch && $ch eq ',') {
      $state->{pos}++;
      next;
    }
    last;
  }

  $self->_skip_ws($state);
  $self->_expect($state, '}');
  return \%hash;
}

sub _parse_array ($self, $state) {
  $self->_expect($state, '[');
  $self->_skip_ws($state);

  my @array;

  if (($self->_peek($state) // '') eq ']') {
    $state->{pos}++;
    return \@array;
  }

  while (1) {
    push @array, $self->_parse_value($state);
    $self->_skip_ws($state);

    my $ch = $self->_peek($state);
    if (defined $ch && $ch eq ',') {
      $state->{pos}++;
      next;
    }
    last;
  }

  $self->_skip_ws($state);
  $self->_expect($state, ']');
  return \@array;
}

sub _parse_key ($self, $state) {
  my $ch = $self->_peek($state);
  return $self->_parse_string($state) if defined $ch && $ch eq '"';

  my $remaining = substr($state->{text}, $state->{pos});
  if ($remaining =~ /\A([A-Za-z_][A-Za-z0-9_-]*)/) {
    $state->{pos} += length $1;
    return $1;
  }

  $self->_throw($state, 'Expected object key');
}

sub _parse_string ($self, $state) {
  $self->_expect($state, '"');
  my $out = '';

  while ($state->{pos} < $state->{len}) {
    my $ch = substr($state->{text}, $state->{pos}, 1);
    $state->{pos}++;

    return $out if $ch eq '"';

    if ($ch eq '\\') {
      $self->_throw($state, 'Unexpected end of input in string escape')
        if $state->{pos} >= $state->{len};

      my $esc = substr($state->{text}, $state->{pos}, 1);
      $state->{pos}++;

      if    ($esc eq '"') { $out .= '"' }
      elsif ($esc eq '\\') { $out .= '\\' }
      elsif ($esc eq '/')  { $out .= '/' }
      elsif ($esc eq 'n')  { $out .= "\n" }
      elsif ($esc eq 'r')  { $out .= "\r" }
      elsif ($esc eq 't')  { $out .= "\t" }
      elsif ($esc eq 'f')  { $out .= "\f" }
      elsif ($esc eq 'b')  { $out .= "\b" }
      elsif ($esc eq 'u')  {
        my $hex = substr($state->{text}, $state->{pos}, 4);
        $self->_throw($state, 'Invalid unicode escape')
          unless $hex =~ /\A[0-9A-Fa-f]{4}\z/;
        $state->{pos} += 4;
        $out .= chr(hex($hex));
      }
      else {
        $self->_throw($state, "Unknown escape sequence \\$esc");
      }

      next;
    }

    $out .= $ch;
  }

  $self->_throw($state, 'Unterminated string');
}

sub _parse_number ($self, $state) {
  my $remaining = substr($state->{text}, $state->{pos});
  if ($remaining =~ /\A(-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)/) {
    $state->{pos} += length $1;
    return 0 + $1;
  }

  $self->_throw($state, 'Invalid number');
}

sub _consume_literal ($self, $state, $literal) {
  return 0 unless substr($state->{text}, $state->{pos}, length($literal)) eq $literal;

  my $next = substr($state->{text}, $state->{pos} + length($literal), 1);
  return 0 if defined($next) && $next =~ /[A-Za-z0-9_-]/;

  $state->{pos} += length($literal);
  return 1;
}

sub _expect ($self, $state, $char) {
  my $got = $self->_peek($state);
  $self->_throw($state, "Expected '$char'") unless defined $got && $got eq $char;
  $state->{pos}++;
}

sub _peek ($self, $state) {
  return undef if $state->{pos} >= $state->{len};
  return substr($state->{text}, $state->{pos}, 1);
}

sub _skip_ws ($self, $state) {
  while ($state->{pos} < $state->{len}) {
    my $ch = substr($state->{text}, $state->{pos}, 1);
    if ($ch =~ /[\x20\x09\x0A\x0D]/) {
      $state->{pos}++;
      next;
    }
    last;
  }
}

sub _throw ($self, $state, $message) {
  my ($line, $column) = $self->_line_and_column($state->{text}, $state->{pos});
  die TOON::Error->new(
    message => $message,
    line    => $line,
    column  => $column,
    offset  => $state->{pos},
  );
}

sub _line_and_column ($self, $text, $pos) {
  my $prefix = substr($text, 0, $pos);
  my $line   = 1 + ($prefix =~ tr/\n//);
  my $last_nl = rindex($prefix, "\n");
  my $column = $pos - $last_nl;
  return ($line, $column);
}

1;

__END__

=head1 NAME

TOON::PP - Pure-Perl encoder/decoder for Token-Oriented Object Notation

=head1 SYNOPSIS

  use TOON::PP;

  my $pp   = TOON::PP->new(pretty => 1, canonical => 1);
  my $text = $pp->encode({ answer => 42 });
  my $data = $pp->decode($text);

=head1 DESCRIPTION

TOON::PP is the pure-Perl backend used by L<TOON>. It implements a
pragmatic TOON syntax that supports scalars (C<null>, C<true>,
C<false>, numbers, and quoted strings), arrays (C<[ ... ]>), and
objects (C<{ key: value }>). Bareword object keys may consist of the
characters C<[A-Za-z_][A-Za-z0-9_\-]*>; all other keys must be
quoted. Quoted strings use JSON-style escape sequences.

In most cases you will want to use the L<TOON> front-end module rather
than instantiating TOON::PP directly.

=head1 METHODS

=head2 new

  my $pp = TOON::PP->new(%opts);

Creates and returns a new TOON::PP encoder/decoder object. Accepts the
following optional named parameters:

=over 4

=item pretty

Boolean. When true, output is formatted with newlines and indentation.
Defaults to C<0>.

=item canonical

Boolean. When true, hash keys are sorted alphabetically in output.
Defaults to C<0>.

=item indent

Integer. Number of spaces per indentation level when C<pretty> is
enabled. Defaults to C<2>.

=back

=head2 encode

  my $text = $pp->encode($data);

Encodes the given Perl data structure into a TOON string and returns
it. Supported Perl types are: C<undef> (encoded as C<null>), plain
scalars (encoded as numbers, booleans, or quoted strings), array
references (encoded as TOON arrays), and hash references (encoded as
TOON objects). Blessed references and unsupported reference types
cause a L<TOON::Error> exception to be thrown.

=head2 decode

  my $data = $pp->decode($text);

Parses the given TOON string and returns the corresponding Perl data
structure. Throws a L<TOON::Error> exception if the input is not valid
TOON.

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=cut
