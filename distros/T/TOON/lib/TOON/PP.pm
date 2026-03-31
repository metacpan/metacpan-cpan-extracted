package TOON::PP;

use v5.40;
use feature 'signatures';

use Scalar::Util qw(looks_like_number blessed);
use TOON::Error;

our $VERSION = '0.1.0';

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

sub _is_tabular_encodable ($self, $hash) {
  return 0 unless %$hash;

  for my $key (keys %$hash) {
    return 0 unless $key =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/;

    my $val = $hash->{$key};
    return 0 unless ref $val eq 'ARRAY' && @$val > 0;

    my $first = $val->[0];
    return 0 unless ref $first eq 'HASH' && %$first;

    my @fields = sort keys %$first;
    for my $f (@fields) {
      return 0 unless $f =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/;
    }

    for my $row (@$val) {
      return 0 unless ref $row eq 'HASH';
      return 0 unless join(',', sort keys %$row) eq join(',', @fields);
      for my $cell (values %$row) {
        return 0 unless defined $cell;
        return 0 if !looks_like_number($cell) && $cell =~ /[,\n\r]/;
      }
    }
  }

  return 1;
}

sub _encode_tabular ($self, $hash) {
  my @keys = sort keys %$hash;

  my @sections;
  for my $key (@keys) {
    my $arr    = $hash->{$key};
    my $count  = scalar @$arr;
    my @fields = sort keys %{ $arr->[0] };

    my $section = "$key\[$count\]{" . join(',', @fields) . "}:\n";
    for my $row (@$arr) {
      $section .= '  ' . join(',', map { $self->_encode_tabular_value($row->{$_}) } @fields) . "\n";
    }
    push @sections, $section;
  }

  return join('', @sections);
}

sub _encode_tabular_value ($self, $value) {
  return '' unless defined $value;
  return 0 + $value if looks_like_number($value);
  return "$value";
}

sub _encode_hash ($self, $hash, $level) {
  return '{}' unless %$hash;

  if ($level == 0 && $self->_is_tabular_encodable($hash)) {
    return $self->_encode_tabular($hash);
  }

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

  if ($ch =~ /[A-Za-z_]/) {
    return $self->_parse_tabular($state);
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

sub _parse_tabular ($self, $state) {
  my %result;

  while ($state->{pos} < $state->{len}) {
    # Skip blank lines and leading whitespace between sections
    $self->_skip_ws($state);
    last if $state->{pos} >= $state->{len};

    my $ch = $self->_peek($state);
    last unless defined $ch && $ch =~ /[A-Za-z_]/;

    # Parse key name
    my $remaining = substr($state->{text}, $state->{pos});
    $self->_throw($state, 'Expected identifier')
      unless $remaining =~ /\A([A-Za-z_][A-Za-z0-9_-]*)/;
    my $key = $1;
    $state->{pos} += length $key;

    # Parse [count]
    $self->_expect($state, '[');
    $remaining = substr($state->{text}, $state->{pos});
    $self->_throw($state, 'Expected count in [...]')
      unless $remaining =~ /\A([0-9]+)/;
    my $count = int($1);
    $state->{pos} += length $1;
    $self->_expect($state, ']');

    # Parse {field1,field2,...}
    $self->_expect($state, '{');
    my @fields;
    while (1) {
      $remaining = substr($state->{text}, $state->{pos});
      $self->_throw($state, 'Expected field name')
        unless $remaining =~ /\A([A-Za-z_][A-Za-z0-9_-]*)/;
      push @fields, $1;
      $state->{pos} += length $1;
      my $c = $self->_peek($state);
      if (defined $c && $c eq ',') {
        $state->{pos}++;
        next;
      }
      last;
    }
    $self->_expect($state, '}');

    # Expect ':'
    $self->_expect($state, ':');

    # Parse count rows of comma-separated values
    my @rows;
    for (1 .. $count) {
      # Skip to the start of the next line
      while ($state->{pos} < $state->{len}) {
        my $c = substr($state->{text}, $state->{pos}, 1);
        $state->{pos}++;
        last if $c eq "\n";
      }

      # Skip leading whitespace (indentation) on this data line
      while ($state->{pos} < $state->{len}) {
        my $c = substr($state->{text}, $state->{pos}, 1);
        last unless $c eq ' ' || $c eq "\t";
        $state->{pos}++;
      }
      # Parse comma-separated field values
      my %row;
      for my $fi (0 .. $#fields) {
        if ($fi > 0) {
          my $c = $self->_peek($state);
          $self->_throw($state, 'Expected comma between row values')
            unless defined $c && $c eq ',';
          $state->{pos}++;
        }
        $row{$fields[$fi]} = $self->_parse_tabular_value($state);
      }
      push @rows, \%row;
    }

    $result{$key} = \@rows;
  }

  return \%result;
}

sub _parse_tabular_value ($self, $state) {
  my $remaining = substr($state->{text}, $state->{pos});
  $remaining =~ /\A([^,\n\r]*)/;
  my $raw = $1;
  $raw =~ s/\s+\z//;    # right-trim
  $state->{pos} += length $1;

  if ($raw =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/) {
    return 0 + $raw;
  }
  return $raw;
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
