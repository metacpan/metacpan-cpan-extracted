package Peta::MP3::Encode;
# ABSTRACT: MP3 (MPEG-1 and MPEG-2 Layer III) encoder

# An MPEG-1 Layer III encoder, and MPEG-2's at the lower sample rates:
# samples go in, MP3 frames come out. The work is shared out like this:
#
#   Filterbank   the polyphase filterbank and the MDCT, 576 lines a granule
#                (::PDL does the same with PDL, faster on both perls)
#   Psy          how much noise each scalefactor band can hide; attacks
#   Quantize     the lines as integers and Huffman codes, within a budget
#   Tables       the tables of ISO 11172-3
#
# This module builds the frames. A frame holds 1152 samples of each channel
# in two granules (MPEG-2: 576, one granule): a header, the side
# information, then the main data. The main data need not fit its own
# frame: room a frame leaves unused is taken by the frames after it (the
# bit reservoir, reaching 511 bytes back, MPEG-2 255), so that a granule
# can have more bits than its share when it needs them. In joint stereo a
# frame whose channels are much alike is coded as their sum and difference
# (mid and side).
#
# A granule with an attack is coded in short blocks, so that its noise does
# not spread to before the attack (pre-echo). The granule before it ends in
# a start window, the one after it begins with a stop window. Deciding that
# needs one granule of samples ahead, which the encoder holds back. Both
# channels always have the same block type.
#
# The bitrate is constant, or variable with vbr => 0 .. 9 (as LAME's -V, 0
# the finest): then every granule is quantized as finely as the model
# allows, and each frame is the smallest whose room, with what the
# reservoir holds, takes its main data.

use v5.36;
use Peta::MP3::Encode::Tables;
use Peta::MP3::Encode::Filterbank;
use Peta::MP3::Encode::Psy;
use Peta::MP3::Encode::Quantize;

our $VERSION = '0.2610180';

use constant SQRT_HALF => 0.7071067811865476;
use constant DELAY     => 528;    # samples the encoder delays the sound by
use constant DECODER   => 529;    # and a decoder (the filterbank's synthesis)
use constant AHEAD     => 576;    # samples held back to see the next granule's attack

# Block types, as the side information has them.
use constant {
    NORMAL => 0,
    START  => 1,
    SHORT  => 2,
    STOP   => 3,
};

# The noise each VBR level allows, in dB against what the model allows.
# Chosen so that each level comes out near the bitrate of LAME's -V of the
# same number.
my @VBR_DB = (-14, -10, -6.5, -4, -2, 1, 3, 5, 7, 9);

my %MODE = (stereo => 0, joint => 1, mono => 3);

sub new ($class, %arg) {
    my $rate     = $arg{rate}     // 44100;
    my $channels = $arg{channels} // 2;
    my $vbr      = $arg{vbr};
    my $lsf      = exists $Peta::MP3::Encode::Tables::LSF_RATE_CODE{$rate} ? 1 : 0;    # MPEG-2's low sample rates
    my $bitrate  = $arg{bitrate} // ($lsf ? 48 : 96) * $channels;
    my $mode     = $channels == 1 ? 'mono' : $arg{mode} // 'joint';

    my ($rate_codes, $bitrates) = $lsf
        ? (\%Peta::MP3::Encode::Tables::LSF_RATE_CODE, \@Peta::MP3::Encode::Tables::LSF_BITRATES)
        : (\%Peta::MP3::Encode::Tables::RATE_CODE,     \@Peta::MP3::Encode::Tables::BITRATES);
    my @rates     = @$bitrates;
    my $rate_code = $rate_codes->{$rate};
    my ($index)   = grep { $rates[$_] == $bitrate } 1 .. $#rates;

    die "vbr: 0 to 9\n" if defined $vbr && $vbr !~ /\A[0-9]\z/;
    die "Layer III has 32000, 44100 and 48000 Hz (MPEG-1), 16000, 22050 and 24000 Hz (MPEG-2), not $rate\n"
        if !defined $rate_code;
    die "no bitrate of $bitrate kbit/s (have: @rates[1 .. $#rates])\n" if !$index && !defined $vbr;
    die "channels: 1 or 2\n" if $channels != 1 && $channels != 2;
    die "mode: stereo, joint or mono\n" if !defined $MODE{$mode} || ($mode eq 'mono') != ($channels == 1);

    my $bank = _filterbank($arg{filterbank} // 'auto');
    my $side = $lsf ? ($channels == 1 ?  9 : 17)
                    : ($channels == 1 ? 17 : 32);

    return bless {
        rate          => $rate,
        rate_code     => $rate_code,
        channels      => $channels,
        mode          => $mode,
        bitrate       => $bitrate,
        bitrate_index => $index,
        rates         => \@rates,
        vbr           => $vbr,
        vbr_scale     => defined $vbr ? 10**($VBR_DB[$vbr] / 10) : 1,
        name          => $arg{ffmpeg_gapless} ? 'LavfPeta' : 'PetaMP3',    # see "THE ENCODER'S NAME"

        lsf           => $lsf,
        granules      => $lsf ? 1 : 2,
        frame_samples => $lsf ? 576 : 1152,
        side          => $side,                # bytes of side information
        most_back     => $lsf ? 255 : 511,     # bytes main_data_begin reaches back

        banks => [ map { $bank->new($rate) } 1 .. $channels ],
        psy   => Peta::MP3::Encode::Psy->new($rate),
        quant => Peta::MP3::Encode::Quantize->new($rate),

        pcm     => [ map { [] } 1 .. $channels ],    # samples not yet coded
        wants   => [],    # whether the granules not yet coded have an attack
        seen    => 0,     # how many of those granules have been looked at
        type    => 0,     # the block type of the last granule coded
        rest    => 0,     # what the frames' sizes have left over, for padding
        pending => [],    # frames whose room for main data is not yet full
        offsets => [],    # VBR: where each frame given out begins
        counts  => [],    # VBR: the frames at each bitrate index

        frames  => 0,
        samples => 0,
        bytes   => 0,     # of the frames given out
        shorts  => 0,     # granules in short blocks
    }, $class;
}

# The filterbank's class: 'pdl', 'perl', or 'auto' (PDL where it loads).
sub _filterbank ($name) {
    my $fbank = 'Peta::MP3::Encode::Filterbank';

    return $fbank          if $name eq 'perl';
    return "${fbank}::PDL" if eval { require Peta::MP3::Encode::Filterbank::PDL; 1 };
    return $fbank          if $name ne 'pdl';

    die "the PDL filterbank needs PDL: $@";
}

sub filterbank ($self) { return ref($self->{banks}[0]) =~ /PDL\z/ ? 'pdl' : 'perl' }

sub frames  ($self) { return $self->{frames} }
sub samples ($self) { return $self->{samples} }
sub shorts  ($self) { return $self->{shorts} }
sub vbr     ($self) { return $self->{vbr} }

# The bitrate in kbit/s: the constant one, or the average of the frames so far.
sub bitrate ($self) {
    return $self->{bitrate} if !defined $self->{vbr};
    return 0                if !$self->{frames};

    return 8 * $self->{bytes} * $self->{rate} / ($self->{frame_samples} * $self->{frames}) / 1000;
}

# Takes samples (-1 .. 1), one array reference per channel. Returns the
# frames they complete, as bytes.
sub encode ($self, @channels) {
    die "expected $self->{channels} channel(s)\n" if @channels != $self->{channels};

    my $pcm = $self->{pcm};
    push @{ $pcm->[$_] }, @{ $channels[$_] } for 0 .. $#channels;
    $self->{samples} += @{ $channels[0] };

    return $self->_frames;
}

# Returns the rest: the samples still held, followed by enough silence to
# come out of a decoder whole, and every frame still waiting.
sub finish ($self) {
    my $pcm = $self->{pcm};
    my $n   = $self->{frame_samples};

    # The frames must hold the samples and both delays, and each frame is
    # coded with the next granule seen.
    my $frames = int(($self->{samples} + DELAY + DECODER + $n - 1) / $n);
    $frames = 2 if $frames < 2;    # FFmpeg knows MP3 by two frames in a row
    my $more = ($frames - $self->{frames}) * $n + AHEAD - @{ $pcm->[0] };
    if ($more > 0) { push @$_, (0.0) x $more for @$pcm }

    my $out = $self->_frames;
    for my $frame (@{ $self->{pending} }) {
        $frame->{data} .= "\0" x ($frame->{room} - length $frame->{data});
    }
    return $out . $self->_flush;
}

# A frame's bytes at a bitrate index, without padding.
sub _frame_bytes ($self, $index) {
    return int($self->{frame_samples} * 125 * $self->{rates}[$index] / $self->{rate});
}

# Codes every frame there are samples for (and a granule more to look
# ahead at). Returns the frames completed.
sub _frames ($self) {
    my $pcm = $self->{pcm};
    my $n   = $self->{frame_samples};
    my $out = '';

    while (@{ $pcm->[0] } >= $n + AHEAD) {
        my @frame = map { [ splice @$_, 0, $n ] } @$pcm;
        my @ahead = map { [ @$_[ 0 .. AHEAD - 1 ] ] } @$pcm;
        $out .= $self->_frame(\@frame, \@ahead);
    }
    return $out;
}

# Codes one frame: $pcm its samples by channel, $ahead the next granule's.
# Returns the frames this one completes.
sub _frame ($self, $pcm, $ahead) {
    $self->_find_attacks($pcm, $ahead);
    my ($xr, $types) = $self->_spectra($pcm);

    my $ms = $self->{mode} eq 'joint' && _alike($xr);
    _to_mid_side($xr) if $ms;

    my ($index, $padding, $room) = $self->_frame_size;
    my $back = 0;    # bytes the frames still waiting have free
    $back += $_->{room} - length $_->{data} for @{ $self->{pending} };

    my $gi   = $self->_quantize($xr, $types, $room, $back);
    my $data = $self->_main_data($gi, $xr);

    ($index, $room) = $self->_smallest_frame(length($data) - $back) if defined $self->{vbr};

    # Room that would stay unused beyond the reservoir's reach is filled now.
    my $unused = $back + $room - length $data;
    $data .= "\0" x ($unused - $self->{most_back}) if $unused > $self->{most_back};

    my $head = $self->_header($index, $padding, $ms, $back, $gi, $types);
    push @{ $self->{pending} }, { head => $head, room => $room, data => '' };
    $self->{counts}[$index]++;
    $self->{frames}++;

    $self->_place($data);
    return $self->_flush;
}

# Whether this frame's granules, and the one after them, have attacks. The
# samples of each granule tell for it and for the next.
sub _find_attacks ($self, $pcm, $ahead) {
    my $granules = $self->{granules};
    my $wants    = $self->{wants};

    while ($self->{seen} < $granules + 1) {
        my $g = $self->{seen}++;
        my @samples = $g < $granules ? map { _granule_of($_, $g) } @$pcm : @$ahead;
        my ($early, $late) = $self->{psy}->attack(@samples);
        $wants->[$g]     ||= $early;
        $wants->[$g + 1] ||= $late;
    }
    return;
}

# The 576 samples of granule $g.
sub _granule_of ($samples, $g) { return [ @$samples[ 576 * $g .. 576 * $g + 575 ] ] }

# The granules' block types, and their lines by [granule][channel].
sub _spectra ($self, $pcm) {
    my $granules = $self->{granules};
    my $wants    = $self->{wants};
    my (@xr, @types);

    for my $gr (0 .. $granules - 1) {
        my $type = _block_type($self->{type}, $wants->[$gr], $wants->[$gr + 1]);
        $self->{type} = $types[$gr] = $type;
        $self->{shorts}++ if $type == SHORT;

        for my $ch (0 .. $self->{channels} - 1) {
            $xr[$gr][$ch] = $self->{banks}[$ch]->granule(_granule_of($pcm->[$ch], $gr), $type);
        }
    }
    splice @$wants, 0, $granules;
    $self->{seen} -= $granules;

    return (\@xr, \@types);
}

# A granule's block type, from the last granule's and whether this one and
# the next have attacks: short where there is one, a start window before
# short blocks, a stop window after them.
sub _block_type ($last, $now, $next) {
    return SHORT  if $now;
    return SHORT  if $last == SHORT && $next;    # no window both stops and starts
    return STOP   if $last == SHORT;
    return START  if $next;
    return NORMAL;
}

# Whether the two channels of a frame are alike enough to code as mid and side.
sub _alike ($xr) {
    my ($mid, $side) = (0.0, 0.0);
    for my $granule (@$xr) {
        my ($l, $r) = @$granule;
        for my $i (0 .. 575) {
            my $s = $l->[$i] + $r->[$i];
            my $d = $l->[$i] - $r->[$i];
            $mid  += $s * $s;
            $side += $d * $d;
        }
    }
    return $side < 0.5 * $mid;
}

# Left and right become mid and side, in place.
sub _to_mid_side ($xr) {
    for my $granule (@$xr) {
        my ($l, $r) = @$granule;
        my @mid  = map { ($l->[$_] + $r->[$_]) * SQRT_HALF } 0 .. 575;
        my @side = map { ($l->[$_] - $r->[$_]) * SQRT_HALF } 0 .. 575;
        @$granule = (\@mid, \@side);
    }
    return;
}

# The frame's bitrate index, its padding (0 or 1), and the bytes of main
# data it has room for. At a constant bitrate a frame is padded by a byte
# now and then, so that the sizes come out right on average. At a variable
# bitrate the size is chosen once the main data is made; until then the
# largest frame's room is what the granules can spend.
sub _frame_size ($self) {
    my $overhead = 4 + $self->{side};    # the header and the side information

    return (undef, 0, $self->_frame_bytes($#{ $self->{rates} }) - $overhead) if defined $self->{vbr};

    my $whole   = $self->{frame_samples} * 125 * $self->{bitrate};
    my $padding = 0;
    $self->{rest} += $whole % $self->{rate};
    if ($self->{rest} >= $self->{rate}) {
        $padding = 1;
        $self->{rest} -= $self->{rate};
    }
    return ($self->{bitrate_index}, $padding, int($whole / $self->{rate}) + $padding - $overhead);
}

# VBR: the smallest frame whose room takes $need bytes; its index and room.
sub _smallest_frame ($self, $need) {
    my $overhead = 4 + $self->{side};
    my $last     = $#{ $self->{rates} };

    my $index = 1;
    $index++ while $index < $last && $self->_frame_bytes($index) - $overhead < $need;

    return ($index, $self->_frame_bytes($index) - $overhead);
}

# Quantizes the granules: [granule][channel] of what Quantize returns.
#
# Each granule gets its share of the frame, and of what the reservoir holds;
# what a granule leaves, those after it can use. At a constant bitrate, what
# would otherwise be left beyond the reservoir's reach must be used: finer
# quantization than the model asks for, rather than bits thrown away. (At a
# variable bitrate a smaller frame is chosen instead.)
sub _quantize ($self, $xr, $types, $room, $back) {
    my $granules = $self->{granules};
    my $channels = $self->{channels};
    my $count    = $granules * $channels;

    my $share = 8 * $room / $count;
    my $left  = 8 * ($room + $back);
    my $must  = defined $self->{vbr} ? 0 : 8 * ($room + $back - $self->{most_back});
    my @gi;
    my $n = 0;

    for my $gr (0 .. $granules - 1) {
        for my $ch (0 .. $channels - 1) {
            my $rest   = $count - $n;    # granules still to code, this one too
            my $spare  = $left - $share * $rest;
            my $budget = int($share + ($spare > 0 ? $spare / $rest : 0));
            $budget = $left if $budget > $left;
            my $least = $must > 0 ? int($must / $rest) : 0;

            my $allowed = $self->{psy}->allowed($xr->[$gr][$ch], $types->[$gr]);
            if ($self->{vbr_scale} != 1) { $_ *= $self->{vbr_scale} for @$allowed }

            my $first = $gr ? $gi[0][$ch] : undef;    # for scfsi
            my $g = $self->{quant}->granule($xr->[$gr][$ch], $allowed, $budget, $least, $types->[$gr], $first);
            $left -= $g->{part2_3_length};
            $must -= $g->{part2_3_length};
            $gi[$gr][$ch] = $g;
            $n++;
        }
    }
    return \@gi;
}

# The frame's main data, as bytes.
sub _main_data ($self, $gi, $xr) {
    my $main = Peta::MP3::Encode::Bits->new;

    for my $gr (0 .. $self->{granules} - 1) {
        for my $ch (0 .. $self->{channels} - 1) {
            my $before = $main->bits;
            $self->{quant}->write($gi->[$gr][$ch], $main, $xr->[$gr][$ch]);

            my $wrote   = $main->bits - $before;
            my $counted = $gi->[$gr][$ch]{part2_3_length};
            die "internal: granule $gr channel $ch wrote $wrote bits, counted $counted\n" if $wrote != $counted;
        }
    }
    return $main->bytes;
}

# The frame's header and side information, as bytes.
sub _header ($self, $index, $padding, $ms, $back, $gi, $types) {
    my $lsf      = $self->{lsf};
    my $channels = $self->{channels};
    my $head     = Peta::MP3::Encode::Bits->new;

    $head->put($lsf ? 0xFFF3 : 0xFFFB, 16);    # sync, MPEG-1 or 2, Layer III, no CRC
    $head->put($index, 4);
    $head->put($self->{rate_code}, 2);
    $head->put($padding, 1);
    $head->put(0, 1);                          # private
    $head->put($MODE{ $self->{mode} }, 2);
    $head->put($ms ? 2 : 0, 2);                # mode extension: mid and side or not
    $head->put(0, 1);                          # copyright
    $head->put(1, 1);                          # original
    $head->put(0, 2);                          # emphasis

    if ($lsf) {
        $head->put($back, 8);                  # main_data_begin
        $head->put(0, $channels);              # private
    }
    else {
        $head->put($back, 9);                  # main_data_begin
        $head->put(0, $channels == 1 ? 5 : 3); # private
        $head->put(oct('0b' . join '', @{ $gi->[1][$_]{scfsi} }), 4) for 0 .. $channels - 1;
    }

    for my $gr (0 .. $self->{granules} - 1) {
        for my $ch (0 .. $channels - 1) {
            my $g = $gi->[$gr][$ch];
            $head->put($g->{part2_3_length}, 12);
            $head->put($g->{big_values}, 9);
            $head->put($g->{global_gain}, 8);
            $head->put($g->{scalefac_compress}, $lsf ? 9 : 4);

            if ($types->[$gr] == NORMAL) {
                $head->put(0, 1);              # no window switching
                $head->put($_, 5) for @{ $g->{table_select} };
                $head->put($g->{region0_count}, 4);
                $head->put($g->{region1_count}, 3);
            }
            else {
                $head->put(1, 1);              # window switching
                $head->put($types->[$gr], 2);
                $head->put(0, 1);              # not mixed
                $head->put($_, 5) for @{ $g->{table_select} }[ 0, 1 ];
                $head->put($_, 3) for @{ $g->{subblock_gain} };
            }

            $head->put($g->{preflag}, 1) if !$lsf;    # MPEG-2 has it in scalefac_compress
            $head->put($g->{scalefac_scale}, 1);
            $head->put($g->{count1table}, 1);
        }
    }
    return $head->bytes;
}

# Puts the main data into the rooms still free, oldest frame first.
sub _place ($self, $data) {
    for my $frame (@{ $self->{pending} }) {
        last if $data eq '';

        my $free = $frame->{room} - length $frame->{data};
        next if $free <= 0;

        $frame->{data} .= substr $data, 0, $free, '';
    }
    die "internal: main data beyond the frame\n" if $data ne '';
    return;
}

# Returns the frames whose rooms are full, in order.
sub _flush ($self) {
    my $pending = $self->{pending};
    my $out     = '';

    while (@$pending && length $pending->[0]{data} == $pending->[0]{room}) {
        my $frame = shift @$pending;
        push @{ $self->{offsets} }, $self->{bytes} + length $out if defined $self->{vbr};
        $out .= $frame->{head} . $frame->{data};
    }
    $self->{bytes} += length $out;

    return $out;
}

# The frame that goes before all the others: a frame of silence whose main
# data is an Info tag (Xing at a variable bitrate) with the LAME extension.
# The tag gives the frames, the bytes and a table for seeking; the extension
# says how many samples the encoder put before and after the sound, so that
# a decoder can give back exactly the samples encoded.
#
# Its numbers are those of the frames given out so far: write it once at
# the start, to keep its place, and again when all is encoded. The frame
# has the stream's bitrate, or at a variable bitrate the smallest that
# holds the tag.
sub info_frame ($self) {
    my $vbr  = defined $self->{vbr};
    my $side = $self->{side};

    my $index = $vbr ? 1 : $self->{bitrate_index};
    $index++ while $index < $#{ $self->{rates} } && $self->_frame_bytes($index) < 4 + $side + 156;
    my $bytes = $self->_frame_bytes($index);
    my $total = $bytes + $self->{bytes};

    my $head = pack 'n C C',
        $self->{lsf} ? 0xFFF3 : 0xFFFB,                 # sync, MPEG-1 or 2, Layer III, no CRC
        ($index << 4) | ($self->{rate_code} << 2),      # bitrate, sample rate, no padding
        ($MODE{ $self->{mode} } << 6) | 4;              # mode, no extension, original

    my @toc = $vbr ? $self->_seek_table($bytes, $total)
                   : map { int($_ * 256 / 100) } 0 .. 99;    # constant bitrate: a straight line
    my $tag = join '',
        $vbr ? 'Xing' : 'Info',
        pack('N', 0x0F),                                # frames, bytes, seek table and quality follow
        pack('N', $self->{frames}),
        pack('N', $total),
        pack('C100', @toc),
        pack('N', $vbr ? 100 - 10 * $self->{vbr} : 0);  # quality, as LAME gives it

    my $padding = $self->{frames} * $self->{frame_samples} - DELAY - $self->{samples};
    $padding = 0 if $padding < 0;

    my $lame = join '',
        sprintf('%-9.9s', $self->{name}),               # the encoder
        chr($vbr ? 0x04 : 0x01),                        # tag revision 0; VBR (new) or constant bitrate
        chr(0),                                         # lowpass: not given
        pack('N', 0),                                   # peak amplitude: not given
        pack('n n', 0, 0),                              # replay gains: not given
        chr(0),                                         # encoding flags, ATH type
        chr(_byte($self->_least_bitrate)),              # the bitrate; at a variable one the least
        substr(pack('N', (DELAY << 12) | $padding), 1), # encoder delay and padding, 12 bits each
        chr(0),                                         # misc
        chr(0),                                         # MP3 gain
        pack('n', 0),                                   # preset and surround
        pack('N', $total),                              # music length
        pack('n', 0);                                   # music CRC

    my $frame = $head . ("\0" x $side) . $tag . $lame;
    my $need  = length($frame) + 2;
    die "internal: the tag takes $need bytes, the frame has $bytes\n" if $need > $bytes;

    $frame .= pack 'n', _crc16($frame);    # of all before it: 190 bytes in stereo
    return $frame . "\0" x ($bytes - length $frame);
}

# VBR: where each hundredth of the playing time begins, in 256ths of the
# file. $before is the Info frame's size, $total the file's.
sub _seek_table ($self, $before, $total) {
    my $offsets = $self->{offsets};
    my @toc;

    for my $percent (0 .. 99) {
        my $at = @$offsets ? $before + $offsets->[ int($percent * @$offsets / 100) ] : 0;
        push @toc, _byte(int(256 * $at / $total));
    }
    return @toc;
}

# The bitrate for the LAME tag: the constant one, or the least used.
sub _least_bitrate ($self) {
    return $self->{bitrate} if !defined $self->{vbr};

    my ($least) = grep { $self->{counts}[$_] } 1 .. $#{ $self->{rates} };
    return $least ? $self->{rates}[$least] : 0;
}

sub _byte ($n) { return $n > 255 ? 255 : $n }

# CRC-16 as the LAME tag has it: polynomial 0x8005, bits reflected.
sub _crc16 ($bytes) {
    my $crc = 0;
    for my $byte (unpack 'C*', $bytes) {
        $crc ^= $byte;
        for (1 .. 8) { $crc = $crc & 1 ? ($crc >> 1) ^ 0xA001 : $crc >> 1 }
    }
    return $crc;
}

# Bits written most significant first, into bytes.
package Peta::MP3::Encode::Bits {
    sub new ($class) { return bless { bytes => '', acc => 0, count => 0, bits => 0 }, $class }

    sub put ($self, $value, $width) {
        return if !$width;

        $self->{acc} = ($self->{acc} << $width) | ($value & ((1 << $width) - 1));
        $self->{count} += $width;
        $self->{bits}  += $width;
        while ($self->{count} >= 8) {
            $self->{count} -= 8;
            $self->{bytes} .= chr(($self->{acc} >> $self->{count}) & 255);
        }
        $self->{acc} &= (1 << $self->{count}) - 1;
        return;
    }

    sub bits ($self) { return $self->{bits} }

    # Everything written, the last byte filled up with zeros.
    sub bytes ($self) {
        return $self->{bytes} if !$self->{count};
        return $self->{bytes} . chr(($self->{acc} << (8 - $self->{count})) & 255);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MP3::Encode - MP3 (MPEG-1 and MPEG-2 Layer III) encoder

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::MP3::Encode;

    my $mp3 = Peta::MP3::Encode->new(rate => 44100, channels => 2, bitrate => 192);
    print $fh $mp3->encode(\@left, \@right);    # samples -1 .. 1, as many as you like
    print $fh $mp3->finish;

=head1 DESCRIPTION

Encodes samples into MPEG-1 Layer III frames, or MPEG-2's at 16, 22.05 and
24 kHz: constant or variable bitrate, the bit reservoir, joint stereo (mid
and side, frame by frame), short blocks where there are attacks, and an
Info tag for gapless playback.

=head1 METHODS

=head2 new

    Peta::MP3::Encode->new(
        rate           => 44100,     # 32000, 44100, 48000; MPEG-2: 16000, 22050, 24000
        channels       => 2,
        bitrate        => 192,       # kbit/s
        vbr            => undef,     # 0 .. 9 for a variable bitrate
        mode           => 'joint',   # joint, stereo; mono with one channel
        filterbank     => 'auto',    # perl, pdl, auto
        ffmpeg_gapless => 0,
    );

C<bitrate> is one of 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224,
256 and 320 (MPEG-1; by default 192, mono 96), or 8, 16, 24, 32, 40, 48,
56, 64, 80, 96, 112, 128, 144 and 160 (MPEG-2; by default 96, mono 48).

C<vbr> gives a variable bitrate instead, as LAME's C<-V>: 0 is the finest,
and each level comes out near the bitrate LAME gives. C<bitrate> is then
not used.

C<filterbank> C<auto> uses PDL where it is installed: the same output,
faster. For C<ffmpeg_gapless> see L</"THE ENCODER'S NAME">.

=head2 encode

    my $bytes = $mp3->encode(\@left, \@right);

Returns the frames these samples complete. Samples are held until there
are enough for a frame (1152; MPEG-2 576), and one granule more.

=head2 finish

Returns the rest: the last samples and the frames still waiting for their
main data.

=head2 info_frame

Returns the frame to put before all the others: an Info tag (Xing, with a
table for seeking, at a variable bitrate) with the LAME extension, which
gives the encoder's delay and padding for gapless playback. It describes
the frames given out so far, so write it first to keep its place, and
again over it once C<finish> has been called.

=head2 filterbank

C<perl> or C<pdl>: which filterbank the encoder uses.

=head2 frames, samples, bitrate, shorts, vbr

The frames and samples encoded; the bitrate (at a variable bitrate the
average of the frames given out); the granules coded in short blocks; the
VBR level (undefined at a constant bitrate).

=head1 THE ENCODER'S NAME

The Info frame names the encoder C<PetaMP3>. mpg123 reads the encoder
delay and padding whatever the name, and plays the file gapless. FFmpeg
(and the browsers and players built on it) reads them only when the name
begins with C<LAME>, C<Lavf> or C<Lavc>; otherwise it plays the delay and
padding along, some 1600 samples of silence.

For gapless playback there, C<< ffmpeg_gapless => 1 >> writes C<LavfPeta>
instead, C<Lavf> being FFmpeg's own prefix (its libavformat). The file is
made by neither FFmpeg nor LAME; the rest of the name says whose it is, as
far as nine characters allow. It is a concession to how FFmpeg recognizes
the tag, and off by default.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
