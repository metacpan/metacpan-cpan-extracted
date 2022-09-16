package PDF::Builder::Basic::PDF::Filter::LZWDecode;

use strict;
use warnings;
use Carp;
use POSIX;
use base 'PDF::Builder::Basic::PDF::Filter::FlateDecode';

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.023'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Filter::LZWDecode - compress and uncompress stream filters for Lempel-Ziv-Welch

=cut

sub new {
    my ($class, $decode_parms) = @_;

    my $self = { DecodeParms => $decode_parms, };

    bless $self, $class;
    $self->_reset_code();
    return $self;
}

sub infilt {
    my ($self, $data, $is_last) = @_;

    my ($code, $result);
    my $partial_code = $self->{'partial_code'};
    my $partial_bits = $self->{'partial_bits'};

    my $early_change = 1;
    if ($self->{'DecodeParms'} and $self->{'DecodeParms'}->{'EarlyChange'}) {
        $early_change = $self->{'DecodeParms'}->{'EarlyChange'}->val();
    }
    $self->{'table'} = [ map { chr } 0 .. $self->{'clear_table'} - 1 ];

    while ( $data ne q{} ) {
        ($code, $partial_code, $partial_bits) =
          $self->read_dat(\$data, $partial_code, $partial_bits,
            $self->{'code_length'});
        last unless defined $code;

        unless ($early_change) {
            if ($self->{next_code} == (1 << $self->{code_length})
                and $self->{code_length} < 12) {
                $self->{'code_length'}++;
            }
        }

        if      ($code == $self->{'clear_table'}) {
            $self->{'code_length'} = $self->{'initial_code_length'};
            $self->{'next_code'}   = $self->{'eod_marker'} + 1;
            next;
        } elsif ($code == $self->{'eod_marker'}) {
            last;
        } elsif ($code > $self->{'eod_marker'}) {
            $self->{'table'}[$self->{'next_code'}] = $self->{'table'}[$code];
            $self->{'table'}[$self->{'next_code'}] .=
              substr($self->{'table'}[$code + 1], 0, 1);
            $result .= $self->{'table'}[$self->{'next_code'}];
            $self->{'next_code'}++;
        } else {
            $self->{'table'}[$self->{'next_code'}] = $self->{'table'}[$code];
            $result .= $self->{'table'}[$self->{'next_code'}];
            $self->{'next_code'}++;
        }

        if ($early_change) {
            if ($self->{'next_code'} == (1 << $self->{'code_length'})
                and $self->{code_length} < 12) {
                $self->{'code_length'}++;
            }
        }
    }
    $self->{'partial_code'} = $partial_code;
    $self->{'partial_bits'} = $partial_bits;

    if ($self->_predictor_type() == 2) {
        return $self->_depredict($result);
    }
    return $result;
}

sub outfilt {
    my ($self, $str, $is_end) = @_;
    my $max_code   = 32767;
    my $bytes_in   = 0;
    my $checkpoint = 0;
    my $last_ratio = 0;
    my $seen       = q{};
    $self->{'buf'}     = q{};
    $self->{'buf_pos'} = 0;
    $self->_write_code($self->{'clear_table'});

    if ($self->_predictor_type() == 2) {
        $str = $self->_predict($str);
    }

    for my $i (0 .. length($str)) {
        my $char = substr($str, $i, 1);
        $bytes_in += 1;

        if (exists $self->{'table'}{ $seen . $char }) {
            $seen .= $char;
            next;
        }

        $self->_write_code($self->{'table'}{$seen});

        $self->_new_code($seen . $char);

        $seen = $char;

        if ($self->{'at_max_code'}) {
            $self->_write_code($self->{'clear_table'});
            $self->_reset_code();

            undef $checkpoint;
            undef $last_ratio;
        }
    }
    $self->_write_code($self->{'table'}{$seen});    #last bit of input
    $self->_write_code($self->{'eod_marker'});
    my $padding = length($self->{'buf'}) % 8;
    if ($padding > 0) {
        $padding = 8 - $padding;
        $self->{'buf'} .= '0' x $padding;
    }
    return pack 'B*', $self->{'buf'};
}

sub _reset_code {
    my $self = shift;

    $self->{'initial_code_length'} = 9;
    $self->{'max_code_length'}     = 12;
    $self->{'code_length'}         = $self->{'initial_code_length'};
    $self->{'clear_table'}         = 256;
    $self->{'eod_marker'}          = $self->{'clear_table'} + 1;
    $self->{'next_code'}           = $self->{'eod_marker'} + 1;
    $self->{'next_increase'}       = 2**$self->{'code_length'};
    $self->{'at_max_code'}         = 0;
    $self->{'table'} = { map { chr $_ => $_ } 0 .. $self->{'clear_table'} - 1 };
    return;
}

sub _new_code {
    my ($self, $word) = @_;

    if ($self->{'at_max_code'} == 0) {
        $self->{'table'}{$word} = $self->{'next_code'};
        $self->{'next_code'} += 1;
    }

    if ($self->{'next_code'} >= $self->{'next_increase'}) {
        if ($self->{'code_length'} < $self->{'max_code_length'}) {
            $self->{'code_length'}   += 1;
            $self->{'next_increase'} *= 2;
        } else {
            $self->{'at_max_code'} = 1;
        }
    }
    return;
}

sub _write_code {
    my ($self, $code) = @_;

    if (not defined $code) { return; }

    if ($code > (2**$self->{'code_length'})) {
        croak
          "Code $code too large for current code length $self->{'code_length'}";
    }

    for my $bit (reverse 0 .. ($self->{'code_length'} - 1)) {
        if (($code >> $bit) & 1) {
            $self->{'buf'} .= '1';
        } else {
            $self->{'buf'} .= '0';
        }
    }

    $self->{'buf_pos'} += $self->{'code_length'};
    return;
}

sub read_dat {
    my ($self, $data_ref, $partial_code, $partial_bits, $code_length) = @_;

    if (not defined $partial_bits) { $partial_bits = 0; }
    if (not defined $partial_code) { $partial_code = 0; }

    while ($partial_bits < $code_length ) {
        return (undef, $partial_code, $partial_bits) unless length($$data_ref);
        $partial_code = ($partial_code << 8 ) + unpack('C', $$data_ref);
        substr($$data_ref, 0, 1, q{});
        $partial_bits += 8;
    }

    my $code = $partial_code >> ($partial_bits - $code_length);
    $partial_code &= (1 << ($partial_bits - $code_length)) - 1;
    $partial_bits -= $code_length;

    return ($code, $partial_code, $partial_bits);
}

sub _predictor_type {
    my ($self) = @_;
    if ($self->{'DecodeParms'} and $self->{'DecodeParms'}->{'Predictor'}) {
        my $predictor = $self->{'DecodeParms'}->{'Predictor'}->val();
        if      ($predictor == 1 or $predictor == 2) {
            return $predictor;
        } elsif ($predictor == 3) {
            croak 'Floating point TIFF predictor not yet supported';
        } else {
            croak "Invalid predictor: $predictor";
        }
    }
    return 1;
}

sub _depredict {
    my ($self, $data) = @_;
    my $param = $self->{'DecodeParms'};
    my $alpha = $param->{'Alpha'} ? $param->{'Alpha'}->val() : 0;
    my $bpc =
      $param->{'BitsPerComponent'} ? $param->{'BitsPerComponent'}->val() : 8;
    my $colors  = $param->{'Colors'}  ? $param->{'Colors'}->val()  : 1;
    my $columns = $param->{'Columns'} ? $param->{'Columns'}->val() : 1;
    my $rows    = $param->{'Rows'}    ? $param->{'Rows'}->val()    : 0;

    my $comp = $colors + $alpha;
    my $bpp  = ceil($bpc * $comp / 8);
    my $max  = 256;
    if ($bpc == 8) {
        my @data = unpack('C*', $data);
        for my $j (0 .. $rows - 1) {
            my $count = $bpp * ($j * $columns + 1);
            for my $i ($bpp .. $columns * $bpp - 1) {
                $data[$count] =
                  ($data[$count] + $data[$count - $bpp]) % $max;
                $count++;
            }
        }
        $data = pack('C*', @data);
        return $data;
    }
    return $data;
}

sub _predict {
    my ($self, $data) = @_;
    my $param = $self->{'DecodeParms'};
    my $alpha = $param->{'Alpha'} ? $param->{'Alpha'}->val() : 0;
    my $bpc =
      $param->{'BitsPerComponent'} ? $param->{'BitsPerComponent'}->val() : 8;
    my $colors  = $param->{'Colors'}  ? $param->{'Colors'}->val()  : 1;
    my $columns = $param->{'Columns'} ? $param->{'Columns'}->val() : 1;
    my $rows    = $param->{'Rows'}    ? $param->{'Rows'}->val()    : 0;

    my $comp = $colors + $alpha;
    my $bpp  = ceil($bpc * $comp / 8);
    my $max  = 256;
    if ($bpc == 8) {
        my @data = unpack('C*', $data);
        for my $j (0 .. $rows - 1) {
            my $count = $bpp * $columns * ($j + 1) - 1;
            for my $i ($bpp .. $columns * $bpp - 1) {
                $data[$count] -= $data[$count - $bpp];
                if ($data[$count] < 0) { $data[$count] += $max; }
                $count--;
            }
        }
        $data = pack('C*', @data);
        return $data;
    }
    return $data;
}

1;
