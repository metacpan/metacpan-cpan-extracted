package PLON;
use 5.008005;
use strict;
use warnings FATAL => 'all';
use Scalar::Util qw(blessed reftype);
use parent qw(Exporter);
use B;
use Encode ();
use Carp ();

our $VERSION = "0.08";

our @EXPORT = qw(encode_plon decode_pson $_perl);

our $INDENT;

my $WS = qr{[ \t]*};

sub encode_plon { PLON->new->encode(shift) }
sub decode_pson { PLON->new->decode(shift) }

sub mk_accessor {
    my ($pkg, $name) = @_;

    no strict 'refs';
    *{"${pkg}::${name}"} = sub {
        my $enable = defined($_[1]) ? $_[1] : 1;
        if ($enable) {
            $_[0]->{$name} = 1;
        } else {
            $_[0]->{$name} = 0;
        }
        $_[0];
    };
    *{"${pkg}::get_${name}"} = sub {
        $_[0]->{$name} ? 1 : '';
    };
}

sub new {
    my $class = shift;
    bless {
    }, $class;
}

mk_accessor(__PACKAGE__, $_) for qw(pretty ascii deparse canonical);

sub encode {
    my ($self, $stuff) = @_;
    local $INDENT = -1;
    return $self->_encode($stuff);
}

sub _encode {
    my ($self, $value) = @_;
    local $INDENT = $INDENT + 1;

    my $blessed = blessed($value);

    if (defined $blessed) {
        'bless(' . $self->_encode_basic($value, 1) . ',' . $self->_encode_basic($blessed) . ')';
    } else {
        $self->_encode_basic($value);
    }
}

sub _encode_basic {
    my ($self, $value, $blessing) = @_;

    if (not defined $value) {
        return 'undef';
    }

    my $reftype = reftype($value);
    if (not defined $reftype) {
        my $flags = B::svref_2object(\$value)->FLAGS;
        return 0 + $value if $flags & (B::SVp_IOK | B::SVp_NOK) && $value * 0 == 0;

        # string
        if ($self->{ascii}) {
            $value =~ s/"/\\"/g;
            if (Encode::is_utf8($value)) {
                my $buf = '';
                for (split //, $value) {
                    if ($_ =~ /\G[a-zA-Z0-9_ -]\z/) {
                        $buf .= Encode::encode_utf8($_);
                    } else {
                        $buf .= sprintf "\\x{%X}", ord $_;
                    }
                }
               $value = $buf;
            } else {
                $value = $value;
            }
            q{"} . $value . q{"};
        } else {
            #
            # Here is the list of special characters from perlop.pod
            #
            # Sequence     Note  Description
            # \t                  tab               (HT, TAB)
            # \n                  newline           (NL)
            # \r                  return            (CR)
            # \f                  form feed         (FF)
            # \b                  backspace         (BS)
            # \a                  alarm (bell)      (BEL)
            # \e                  escape            (ESC)
            # \x{263A}     [1,8]  hex char          (example: SMILEY)
            # \x1b         [2,8]  restricted range hex char (example: ESC)
            # \N{name}     [3]    named Unicode character or character sequence
            # \N{U+263D}   [4,8]  Unicode character (example: FIRST QUARTER MOON)
            # \c[          [5]    control char      (example: chr(27))
            # \o{23072}    [6,8]  octal char        (example: SMILEY)
            # \033         [7,8]  restricted range octal char  (example: ESC)
            #
            my %special_chars = (
                qq{"}  => q{\"},
                qq{\t} => q{\t},
                qq{\n} => q{\n},
                qq{\r} => q{\r},
                qq{\f} => q{\f},
                qq{\b} => q{\b},
                qq{\a} => q{\a},
                qq{\e} => q{\e},
                q{$}   => q{\$},
                q{@}   => q{\@},
                q{%}   => q{\%},
                q{\\}  => q{\\\\},
            );
            $value =~ s/(.)/
                if (exists($special_chars{$1})) {
                    $special_chars{$1};
                } else {
                    $1
                }
            /gexs;
            $value = Encode::is_utf8($value) ? Encode::encode_utf8($value) : $value;
            q{"} . $value . q{"};
        }
    } elsif ($reftype eq 'SCALAR') {
        if ($blessing) {
            '\\(do {my $o=' . $self->_encode($$value) . '})';
        } else {
            '\\(' . $self->_encode($$value) . ')';
        }
    } elsif ($reftype eq 'REF') {
        '\\(' . $self->_encode($$value) . ')';
    } elsif ($reftype eq 'ARRAY') {
        join('',
            '[',
            $self->_nl,
            (map { $self->_indent(1) . $self->_encode($_) . "," . $self->_nl }
                @$value),
            $self->_indent,
            ']',
        );
    } elsif ($reftype eq 'CODE') {
        if ($self->get_deparse) {
            require B::Deparse;
            my $code = B::Deparse->new($self->get_pretty ? '' : '-si0')->coderef2text($value);
            $code = "sub ${code}";
            if ($self->get_pretty) {
                my $indent = $self->_indent;
                $code =~ s/^/$indent/gm;
                $code;
            } else {
                $code =~ s/\n//g;
                $code;
            }
        } else {
            'sub { "DUMMY" }'
        }
    } elsif ($reftype eq 'HASH') {
        my @keys = keys %$value;
        if ($self->get_canonical) {
            @keys = sort { $a cmp $b } @keys;
        }

        join('',
            '{',
            $self->_nl,
            (map {
                    $self->_indent(1) . $self->_encode($_)
                      . $self->_before_sp . '=>' . $self->_after_sp
                      . $self->_encode($value->{$_})
                      . "," . $self->_nl,
                  } @keys),
            $self->_indent,
            '}',
        );
    } elsif ($reftype eq 'GLOB') {
        "\\(" . $$value . ")";
    } else {
        die "Unknown type: ${reftype}";
    }
}

sub _indent {
    my ($self, $n) = @_;
    if (not defined $n) { $n = 0 };
    $self->get_pretty ? '  ' x ($INDENT+$n) : ''
}

sub _nl {
    my $self = shift;
    $self->get_pretty ? "\n" : '',
}

sub _before_sp {
    my $self = shift;
    $self->get_pretty ? " " : ''
}

sub _after_sp {
    my $self = shift;
    $self->get_pretty ? " " : ''
}

sub decode {
    my ($self, $src) = @_;
    local $_ = $src;
    return $self->_decode();
}

sub _decode {
    my ($self) = @_;

    if (/\G$WS\{/gc) {
        return $self->_decode_hash();
    } elsif (/\G$WS\[/gc) {
        return $self->_decode_array();
    } elsif (/\G$WS"/gc) {
        return $self->_decode_string();
    } elsif (/\G${WS}undef/gc) {
        return undef;
    } elsif (/\G${WS}\\\(/gc) {
        return $self->_decode_scalarref();
    } elsif (/\G${WS}sub\s*\{/gc) {
        return $self->_decode_code();
    } elsif (/\G$WS"/gc) {
        return $self->_decode_string;
    } elsif (/\G$WS([0-9\.]+)/gc) {
        return 0+$1;
    } elsif (/\G${WS}bless\(/gc) {
        return $self->_decode_object;
    } elsif (/\G${WS}do \{my \$o=/gc) {
        return $self->_decode_do;
    } elsif (/\G$WS\*([a-zA-Z0-9_:]+)/gc) {
        no strict 'refs';
        *{$1};
    } else {
        Carp::confess("Unexpected token: " . substr($_, pos, 9));
    }
}

sub _decode_hash {
    my ($self) = @_;

    my %ret;
    until (/\G$WS(,$WS)?\}/gc) {
        my $k = $self->_decode();
        /\G$WS=>$WS/gc
            or _exception("Unexpected token in Hash");
        my $v = $self->_decode();

        $ret{$k} = $v;

        /\G$WS,/gc
            or last;
    }
    return \%ret;
}

sub _decode_array {
    my ($self) = @_;

    my @ret;
    until (/\G$WS,?$WS\]/gc) {
        my $term = $self->_decode();
        push @ret, $term;
    }
    return \@ret;
}

sub _decode_code {
    # We can't decode coderef. Because it makes security issue.
    # And, we can't detect end of code block.
    Carp::confess("Cannot decode PLON contains CodeRef.");
}

sub _decode_object {
    my ($self) = @_;
    my $body  = $self->_decode; # class name
    m!\G${WS},\s*!gc
        or _exception("Missing comma after bless");
    my $str = $self->_decode; # class name
    m!\G${WS}\)!gc
        or _exception("Missing closing paren after bless");
    return bless($body, $str);
}

sub _decode_scalarref {
    my $self = shift;
    my $value = $self->_decode();
    /\G\s*\)/gc
        or _exception("Missing closing paren after scalarref");
    return \$value;
}

# do {my $o=3}
sub _decode_do {
    my $self = shift;
    my $value = $self->_decode;
    m!\G\}!gc
        or _exception("Missing closing blace after `do {`");
    return $value;
}

sub _decode_string {
    my $self = shift;

    my $ret;
    until (/\G"/gc) {
        if (/\G\\"/gc) {
            $ret .= q{"};
        } elsif (/\G\\\$/gc) {
            $ret .= qq{\$};
        } elsif (/\G\\t/gc) {
            $ret .= qq{\t};
        } elsif (/\G\\n/gc) {
            $ret .= qq{\n};
        } elsif (/\G\\r/gc) {
            $ret .= qq{\r};
        } elsif (/\G\\f/gc) {
            $ret .= qq{\f};
        } elsif (/\G\\b/gc) {
            $ret .= qq{\b};
        } elsif (/\G\\a/gc) {
            $ret .= qq{\a};
        } elsif (/\G\\e/gc) {
            $ret .= qq{\e};
        } elsif (/\G\\$/gc) {
            $ret .= qq{\$};
        } elsif (/\G\\@/gc) {
            $ret .= qq{\@};
        } elsif (/\G\\%/gc) {
            $ret .= qq{\%};
        } elsif (/\G\\\\/gc) {
            $ret .= qq{\\};
        } elsif (/\G\\x\{([0-9a-fA-F]+)\}/gc) { # \x{5963}
            $ret .= chr(hex $1);
        } elsif (/\G([^"\\]+)/gc) {
            $ret .= $1;
        } else {
            _exception("Unexpected EOF in string");
        }
    }
    # If it's utf-8, it means the PLON encoded by ASCII mode.
    # The PLON contains "\x{5963}". Then, we shouldn't decode the string.
    return Encode::is_utf8($ret) ? $ret : Encode::decode_utf8($ret);
}

sub _exception {

  # Leading whitespace
  m/\G$WS/gc;

  # Context
  my $context = 'Malformed PLON: ' . shift;
  if (m/\G\z/gc) { $context .= ' before end of data' }
  else {
    my @lines = split "\n", substr($_, 0, pos);
    $context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
  }

  die "$context\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

PLON - Serialize object to Perl code

=head1 SYNOPSIS

    use PLON;

    my $plon = encode_plon([]);
    # $plon is `[]`

=head1 DESCRIPTION

PLON is yet another serialization library for Perl5, has the JSON.pm like interface.

=head1 WHY?

I need data dumper library supports JSON::XS/JSON::PP like interface.
I use JSON::XS really hard. Then, I want to use other serialization library with JSON::XS/JSON::PP's interface.

Data::Dumper escapes multi byte chars. When I want copy-and-paste from Data::Dumper's output to my test code, I need to un-escape C<\x{5963}> by my hand. PLON.pm don't escape multi byte characters by default.

=head1 STABILITY

This release is a prototype. Every API will change without notice.
(But, I may not remove C<encode_plon($scalar)> interface. You can use this.)

I need your feedback. If you have ideas or comments, please report to L<Github Issues|https://github.com/tokuhirom/PLON/issues>.

=head1 OBJECT-ORIENTED INTERFACE

The object oriented interface lets you configure your own encoding or
decoding style, within the limits of supported formats.

=over 4

=item $plon = PLON->new()

Creates a new PLON object that can be used to de/encode PLON
strings. All boolean flags described below are by default I<disabled>.

=item C<< $plon = $plon->pretty([$enabled]) >>

This enables (or disables) all of the C<indent>, C<space_before> and
C<space_after> (and in the future possibly more) flags in one call to
generate the most readable (or most compact) form possible.

=item C<< $plon->ascii([$enabled]) >>

=item C<< my $enabled = $plon->get_ascii() >>

    $plon = $plon->ascii([$enable])

    $enabled = $plon->get_ascii

If $enable is true (or missing), then the encode method will not generate characters outside
the code range 0..127. Any Unicode characters outside that range will be escaped using either
a \x{XXXX} escape sequence.

If $enable is false, then the encode method will not escape Unicode characters unless
required by the PLON syntax or other flags. This results in a faster and more compact format.

    PLON->new->ascii(1)->encode([chr 0x10401])
    => ["\x{10401}"]

=item C<< $plon->deparse([$enabled]) >>

=item C<< my $enabled = $plon->get_deparse() >>

If $enable is true (or missing), then the encode method will de-parse the code by L<B::Deparse>.
Otherwise, encoder generates C<sub { "DUMMY" }> like L<Data::Dumper>.

=item C<< $plon->canonical([$enabled]) >>

=item C<< my $enabled = $plon->get_canonical() >>

If $enable is true (or missing), then the "encode" method will output
PLON objects by sorting their keys. This is adding a comparatively
high overhead.

=back

=head1 PLON Spec

=over 4

=item PLON only supports UTF-8. Serialized PLON string must be UTF-8.

=item PLON string must be eval-able.

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

=over 4

=item L<Data::Dumper>

=item L<Data::Pond>

=item L<Acme::PSON>

=back

=cut

